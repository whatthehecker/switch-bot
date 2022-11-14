import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:switch_bot_frontend/message_identifiers.dart';
import 'package:switch_bot_frontend/widgets/joycon_button.dart';
import 'package:switch_bot_frontend/widgets/joycon_widget.dart';

class ControllerScreen extends StatelessWidget {
  final Socket socket;

  const ControllerScreen({
    required this.socket,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LeftJoyconWidget(
              onLeftJoystickChanged: (double radius, double angle) {
                socket.emit(
                  MessageIdentifiers.moveJoystick,
                  {
                    'joystick': 'left',
                    'radius': radius,
                    'angle': angle,
                  },
                );
              },
              onButtonPressed: (JoyconButton button) {
                socket.emit(MessageIdentifiers.pressButton, button.name);
              },
            ),
            RightJoyconWidget(
              onRightJoystickChanged: (double radius, double angle) {
                socket.emit(
                  MessageIdentifiers.moveJoystick,
                  {
                    'joystick': 'right',
                    'radius': radius,
                    'angle': angle,
                  },
                );
              },
              onButtonPressed: (JoyconButton button) {
                socket.emit(MessageIdentifiers.pressButton, button.name);
              },
            ),
          ],
        ),
      ),
    );
  }
}
