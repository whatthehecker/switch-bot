import asyncio
import base64
import logging
import sys
from asyncio import sleep
from pathlib import Path
from typing import Optional, Type, Dict, cast, List

import cv2
import socketio
from serial import SerialException

from .messages.start_program_message import StartProgramMessage
from .messages.welcome_message import WelcomeMessage
from ..bot.switch_bot import SwitchBot
from ..bot.video_connector import CameraDescriptor
from ..program.program import Program, ProgramMetadata
from ..program.program_loader import import_program_from_directory
from .message_identifiers import MessageIdentifiers
from .messages.current_program_message import CurrentProgramMessage
from .messages.dialog_closed_message import DialogClosedMessage
from .messages.result_message import ResultMessage
from .messages.video_frame_message import VideoFrameMessage
from ..util.cyclic_buffer_handler import CyclicBufferHandler
from ..util.emitting_socket_handler import EmittingSocketHandler

logger = logging.getLogger('Server')
handler = logging.StreamHandler(sys.stdout)
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)

# Maps from the names buttons use inside a "Press button" message to button name internally used by the serial protocol.
MESSAGE_BUTTON_TO_BUTTON_NAME = {
    'A': 'A',
    'B': 'B',
    'X': 'X',
    'Y': 'Y',
    'Home': 'H',
    'Minus': 'M',
    'Plus': 'P',
    'Capture': 'C',
    'L': 'L',
    'R': 'R',
    'ZL': 'ZL',
    'ZR': 'ZR',
    'Left': 'DL',
    'Right': 'DR',
    'Up': 'DU',
    'Down': 'DD',
}


class Server:
    def __init__(self, sio: socketio.Server):
        self.sio: socketio.Server = sio
        self.bot: SwitchBot = SwitchBot(sio)
        self.emitter_task: Optional[asyncio.Task] = None
        self.programs: List[Program] = []
        self.program_task: Optional[asyncio.Task] = None
        self.program_instance: Optional[Program] = None
        self.log_buffer_handler = CyclicBufferHandler(level=logging.DEBUG)

        sio.on('connect', self.connect)
        sio.on('disconnect', self.disconnect)
        sio.on(MessageIdentifiers.CONNECT_SERIAL_REQUEST, self.connect_serial)
        sio.on(MessageIdentifiers.DISCONNECT_SERIAL, self.disconnect_serial)
        sio.on(MessageIdentifiers.CURRENT_SERIAL_REQUEST, self.emit_current_serial)
        sio.on(MessageIdentifiers.ALL_SERIALS_REQUEST, self.emit_available_serial)
        sio.on(MessageIdentifiers.CONNECT_VIDEO_REQUEST, self.connect_video)
        sio.on(MessageIdentifiers.DISCONNECT_VIDEO, self.disconnect_video)
        sio.on(MessageIdentifiers.CURRENT_VIDEO_REQUEST, self.emit_current_video)
        sio.on(MessageIdentifiers.ALL_VIDEO_REQUEST, self.emit_available_video)
        sio.on(MessageIdentifiers.GET_PROGRAMS_REQUEST, self.emit_available_programs)
        sio.on(MessageIdentifiers.START_PROGRAM_REQUEST, self.start_program)
        sio.on(MessageIdentifiers.STOP_PROGRAM, self.stop_current_program)
        sio.on(MessageIdentifiers.RELOAD_PROGRAMS, self.reload_programs)
        sio.on(MessageIdentifiers.DIALOG_CLOSED, self.close_dialog)
        sio.on(MessageIdentifiers.PRESS_BUTTON, self.press_button)
        sio.on(MessageIdentifiers.MOVE_JOYSTICK, self.move_joystick)
        sio.on(MessageIdentifiers.GET_RUNNING_PROGRAM_REQUEST, self.emit_current_program)

        # Load programs from directory when the server is started.
        self._do_reload_programs()

    async def connect(self, sid, environ, auth):
        logger.info(f'Client with ID {sid} connected.')

        logger.debug(f'Building current state for client {sid}...')
        welcome_message = WelcomeMessage(
            available_programs=[ProgramMetadata.to_dict(program.metadata) for program in self.programs],
            current_video=CameraDescriptor.to_dict(self.bot.video.active_camera_descriptor)
            if self.bot.video.active_camera_descriptor is not None
            else None,
            available_video=[CameraDescriptor.to_dict(descriptor) for descriptor in self.bot.video.list_cameras()],
            current_serial=self.bot.serial.port_identifier,
            available_serial=self.bot.serial.list_serial_ports(),
            current_dialog=self.program_instance.current_dialog.to_dict()
            if self.program_instance is not None
               and self.program_instance.current_dialog is not None else None,
            current_program_name=self.program_instance.metadata.name if self.program_instance is not None else None,
            current_program_options=self.program_instance.option_values if self.program_instance is not None else None,
            recent_program_logs=list(self.log_buffer_handler.get_buffered_records()),
        )
        await self.sio.emit(MessageIdentifiers.WELCOME, WelcomeMessage.to_dict(welcome_message))
        logger.info(f'Sent welcome message to client {sid}')

    def disconnect(self, sid):
        logger.info(f'Client with ID {sid} disconnected.')

    async def connect_serial(self, _sid, port: str):
        logger.info(f'Requested to connect to port {port}')
        try:
            self.bot.serial.connect(port)
            message = ResultMessage(success=True)
        except SerialException as exception:
            message = ResultMessage(success=False, error_message=str(exception))
        await self.sio.emit(MessageIdentifiers.CONNECT_SERIAL_RESPONSE, ResultMessage.to_dict(message))

    def disconnect_serial(self, _sid):
        self.bot.serial.disconnect()

    async def emit_current_serial(self, sid):
        await self.sio.emit(MessageIdentifiers.CURRENT_SERIAL_RESPONSE, self.bot.serial.port_identifier, to=sid)

    async def emit_available_serial(self, sid):
        await self.sio.emit(MessageIdentifiers.ALL_SERIALS_RESPONSE, self.bot.serial.list_serial_ports(), to=sid)

    async def connect_video(self, sid, descriptor_json: Dict[str, object]):
        descriptor = CameraDescriptor.from_dict(descriptor_json)

        self.bot.video.connect(descriptor)

        if self.emitter_task is not None:
            self.emitter_task.cancel()
        self.emitter_task = self.sio.start_background_task(target=self.emit_frames)

        message = ResultMessage(success=True)
        await self.sio.emit(MessageIdentifiers.CONNECT_VIDEO_RESPONSE, ResultMessage.to_dict(message), to=sid)

    async def emit_frames(self):
        logger.debug('Starting to emit frames...')

        if self.bot.video.capture is None:
            logger.warning('Could not start emitting frames as capture is None!')
            return
        elif not self.bot.video.capture.isOpened():
            logger.warning('Could not start emitting frames as capture is not open!')
            return

        while self.bot.video.capture is not None and self.bot.video.capture.isOpened():
            success, frame = self.bot.video.capture.read()
            if not success:
                continue
            # Scale down image to save on bandwidth
            frame = cv2.resize(src=frame, dsize=(0, 0), fx=0.25, fy=0.25)
            success, jpg = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 75])
            if not success:
                continue

            b64_image: str = base64.b64encode(jpg).decode()
            message: VideoFrameMessage = VideoFrameMessage(image=b64_image)
            await self.sio.emit(MessageIdentifiers.VIDEO_FRAME_GRABBED, VideoFrameMessage.to_dict(message))
            # Also sleep for a single video frame so that other tasks can run!
            await sleep(1.0 / 60.0)
        logger.debug('Stopped emitting frame because capture was closed.')

    async def disconnect_video(self, _sid):
        logger.info('Disconnecting video...')
        self.bot.video.disconnect()
        await self.emit_current_video()

    async def emit_current_video(self, sid=None):
        await self.sio.emit(MessageIdentifiers.CURRENT_VIDEO_RESPONSE, CameraDescriptor.to_dict(
            self.bot.video.active_camera_descriptor) if self.bot.video.active_camera_descriptor is not None else None,
                            to=sid)

    async def emit_available_video(self, sid=None):
        data: List[CameraDescriptor] = [CameraDescriptor.to_dict(descriptor) for descriptor in
                                        self.bot.video.list_cameras()]
        await self.sio.emit(MessageIdentifiers.ALL_VIDEO_RESPONSE, data, to=sid)

    async def emit_available_programs(self, sid=None):
        identifier_metadata = [ProgramMetadata.to_dict(program.metadata) for program in
                               self.programs]
        # todo: does this correctly only emit to the chosen sid?
        await self.sio.emit(MessageIdentifiers.GET_PROGRAMS_RESPONSE, identifier_metadata, to=sid)

    async def start_program(self, sid, data: Dict[str, object]):
        start_message: StartProgramMessage = StartProgramMessage.from_dict(data)

        program_instance: Program = next(
            (program for program in self.programs if program.metadata.name == start_message.program_name), None)
        if program_instance is not None:
            # Cancel any running program. No need to reset the values of self.program_task and self.program_instance
            # as they will be set in the following lines anyways.
            if self.program_task is not None:
                self.program_task.cancel()
            # Initialize program with the chosen option values.
            program_instance.update_option_values(start_message.option_values)

            # Start the program task to execute the program.
            self.program_instance = program_instance

            async def do_run():
                await program_instance.run(self.bot)
                await self._on_program_finished()

            self.program_task: Optional[asyncio.Task] = self.sio.start_background_task(do_run)

            # Report a success.
            message = ResultMessage(success=True)
        else:
            # Indicate that program start failed.
            message = ResultMessage(success=False,
                                    error_message=f'No program with name {start_message.program_name} found')
        await self.sio.emit(MessageIdentifiers.START_PROGRAM_RESPONSE, ResultMessage.to_dict(message), to=sid)
        await self.emit_current_program(sid)

    def _create_program_logger(self, name: str):
        # Create a logging handler to emit each log line to the clients.
        program_logger: logging.Logger = logging.getLogger(name)
        emitting_handler = EmittingSocketHandler(self.sio, level=logging.DEBUG)
        program_logger.addHandler(emitting_handler)
        # Also add the buffering handler that keeps the last log lines to emit on login.
        program_logger.addHandler(self.log_buffer_handler)
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.DEBUG)
        formatter = logging.Formatter('%(asctime)s PROGRAM - %(name)s - %(levelname)s - %(message)s')
        console_handler.setFormatter(formatter)
        program_logger.addHandler(console_handler)

        return program_logger

    async def _on_program_finished(self):
        logger.info('Program finished.')
        # Clear task to show that no program is running anymore.
        self.program_task = None
        self.program_instance = None
        await self.emit_current_program()

    def press_button(self, _sid, message_button_name: str):
        serial_button_name: Optional[str] = MESSAGE_BUTTON_TO_BUTTON_NAME.get(message_button_name, None)
        if serial_button_name is None:
            # todo: respond with error
            pass
        # todo: handle exceptions and relay them in a message to the caller
        self.bot.serial.write_command(f'T{serial_button_name}')

    def move_joystick(self, _sid, data: Dict[str, object]):
        joystick: str = cast(str, data['joystick'])
        # Clamp radius to 1.0 to prevent pretty-much-zero-but-not-quite values from causing errors.
        radius: float = min(1.0, cast(float, data['radius']))
        angle: float = cast(float, data['angle'])

        if joystick == 'left':
            self.bot.serial.set_left_joystick(angle, radius)
        elif joystick == 'right':
            self.bot.serial.set_right_joystick(angle, radius)

    async def stop_current_program(self, _sid):
        if self.program_task is not None:
            self.program_task.cancel()
            self.program_task = None
            self.program_instance = None
            # Only emit this update if we actually stopped anything.
            await self.emit_current_program()

    async def reload_programs(self, sid):
        self._do_reload_programs()
        await self.emit_available_programs(sid)

    async def close_dialog(self, _sid, data):
        logger.debug('Dialog closed handler called')
        message: DialogClosedMessage = DialogClosedMessage.from_dict(data)
        self.program_instance.on_user_interaction(message.button)

    async def emit_current_program(self, sid=None):
        if self.program_task is not None:
            metadata: ProgramMetadata = self.program_instance.metadata
            option_values: Dict[str, object] = self.program_instance.option_values

            message = CurrentProgramMessage(
                metadata=metadata,
                option_values=option_values,
            )
        else:
            message = CurrentProgramMessage(metadata=None, option_values=None)

        await self.sio.emit(MessageIdentifiers.GET_RUNNING_PROGRAM_RESPONSE, CurrentProgramMessage.to_dict(message),
                            to=sid)

    def _do_reload_programs(self):
        self.programs.clear()

        programs_path: Path = Path('./programs')
        # Load programs from all subdirectories
        for program_directory in programs_path.glob('*/'):
            program_type: Optional[Type[Program]] = import_program_from_directory(program_directory)
            if program_type is not None:
                program_logger = self._create_program_logger(program_type.__name__)
                program_instance: Program = program_type(program_logger)
                self.programs.append(program_instance)
            else:
                logger.info(f'Directory at {program_directory} contained no valid program definition.')
