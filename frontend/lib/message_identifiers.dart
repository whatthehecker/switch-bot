/// Constant identifiers to identify message payloads emitted to and from
/// the backend.
class MessageIdentifiers {
  static const String videoFrameGrabbed = 'video_frame';
  static const String currentVideoRequest = 'get_current_video';
  static const String currentVideoResponse = 'current_video_result';
  static const String connectVideoRequest = 'connect_video';
  static const String connectVideoResponse = 'connect_video_result';
  static const String disconnectVideo = 'disconnect_video';
  static const String allVideoRequest = 'get_available_video';
  static const String allVideoResponse = 'all_videos';
  static const String currentSerialRequest = 'get_current_serial';
  static const String currentSerialResponse = 'current_serial_result';
  static const String connectSerialRequest = 'connect_serial';
  static const String connectSerialResponse = 'connect_serial_response';
  static const String disconnectSerial = 'disconnect_serial';
  static const String allSerialsRequest = 'get_all_serial';
  static const String allSerialsResponse = 'all_serials';
  static const String getProgramsRequest = 'get_available_programs';
  static const String getProgramsResponse = 'found_programs';
  static const String startProgramRequest = 'start_program';
  static const String startProgramResponse = 'program_start_result';
  static const String stopProgram = 'stop_current_program';
  static const String getRunningProgramRequest = 'get_running_program';
  static const String getRunningProgramResponse = 'current_running_program';
  static const String reloadPrograms = 'reload_programs';
  static const String updateRunningProgramOptionValues = 'update_running_option_values';
  static const String pressButton = 'press_button';
  static const String moveJoystick = 'move_joystick';
  static const String dialogClosed = 'close_dialog';
  static const String showDialogRequest = 'show_dialog';
  static const String logLineEmitted = 'log_line';
  static const String welcome = 'welcome';
}