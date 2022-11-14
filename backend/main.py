import logging

import socketio
from aiohttp import web
import argparse

from switchbot.server.server import Server


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--host', help='The to serve on.', default=None)
    parser.add_argument('-p', '--port', help='The port to serve on.', default=8765, type=int)

    args = parser.parse_args()

    sio = socketio.AsyncServer(async_mode='aiohttp', cors_allowed_origins='*')
    app = web.Application()
    sio.attach(app)

    bot_server = Server(sio)

    logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    web.run_app(app, host=args.host, port=args.port)
