import 'package:flutter/material.dart';
import 'package:switch_bot_frontend/widgets/joycon_button.dart';
import 'package:switch_bot_frontend/widgets/joystick_widget.dart';
import 'package:switch_bot_frontend/widgets/switching_button.dart';

Widget _buildButtonWidget(
  JoyconButton button, {
  required ValueChanged<JoyconButton> parentCallback,
  required String assetName,
}) {
  return SwitchingButton(
    releasedChild: Image.asset(
      'assets/joycon_icons/outline/$assetName.png',
      width: 25,
      height: 25,
    ),
    pressedChild: Image.asset(
      'assets/joycon_icons/solid/$assetName.png',
      width: 25,
      height: 25,
    ),
    onPressed: () => parentCallback(button),
  );
}

class LeftJoyconWidget extends StatelessWidget {
  final JoystickCallback onLeftJoystickChanged;
  final ValueChanged<JoyconButton> onButtonPressed;

  const LeftJoyconWidget({
    required this.onLeftJoystickChanged,
    required this.onButtonPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 125,
      color: Colors.lightBlue,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildButtonWidget(
                    JoyconButton.zl,
                    parentCallback: onButtonPressed,
                    assetName: 'ZL',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildButtonWidget(
                    JoyconButton.l,
                    parentCallback: onButtonPressed,
                    assetName: 'L',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(child: SizedBox()),
                _buildButtonWidget(
                  JoyconButton.minus,
                  parentCallback: onButtonPressed,
                  assetName: 'Minus',
                ),
              ],
            ),
            const SizedBox(height: 4),
            JoystickWidget(
              widthAndHeight: 100,
              childWidthAndHeight: 25,
              onJoystickMove: onLeftJoystickChanged,
              child: Image.asset(
                'assets/joycon_icons/outline/Joystick.png',
                height: 25,
                width: 25,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButtonWidget(
                  JoyconButton.directionUp,
                  parentCallback: onButtonPressed,
                  assetName: 'D-Pad-Up',
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButtonWidget(
                  JoyconButton.directionLeft,
                  parentCallback: onButtonPressed,
                  assetName: 'D-Pad-Left',
                ),
                const SizedBox(width: 25),
                _buildButtonWidget(
                  JoyconButton.directionRight,
                  parentCallback: onButtonPressed,
                  assetName: 'D-Pad-Right',
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButtonWidget(
                  JoyconButton.directionDown,
                  parentCallback: onButtonPressed,
                  assetName: 'D-Pad-Down',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(child: SizedBox()),
                _buildButtonWidget(
                  JoyconButton.capture,
                  parentCallback: onButtonPressed,
                  assetName: 'Capture',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RightJoyconWidget extends StatelessWidget {
  final JoystickCallback onRightJoystickChanged;
  final ValueChanged<JoyconButton> onButtonPressed;

  const RightJoyconWidget({
    required this.onRightJoystickChanged,
    required this.onButtonPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      width: 125,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildButtonWidget(
                    JoyconButton.zr,
                    parentCallback: onButtonPressed,
                    assetName: 'ZR',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildButtonWidget(
                    JoyconButton.r,
                    parentCallback: onButtonPressed,
                    assetName: 'R',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildButtonWidget(
                  JoyconButton.plus,
                  parentCallback: onButtonPressed,
                  assetName: 'Plus',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButtonWidget(
                  JoyconButton.x,
                  parentCallback: onButtonPressed,
                  assetName: 'X',
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButtonWidget(
                  JoyconButton.y,
                  parentCallback: onButtonPressed,
                  assetName: 'Y',
                ),
                const SizedBox(width: 25),
                _buildButtonWidget(
                  JoyconButton.a,
                  parentCallback: onButtonPressed,
                  assetName: 'A',
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButtonWidget(
                  JoyconButton.b,
                  parentCallback: onButtonPressed,
                  assetName: 'B',
                ),
              ],
            ),
            const SizedBox(height: 4),
            JoystickWidget(
              widthAndHeight: 100,
              childWidthAndHeight: 25,
              onJoystickMove: onRightJoystickChanged,
              child: Image.asset(
                'assets/joycon_icons/outline/Joystick.png',
                height: 25,
                width: 25,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildButtonWidget(
                  JoyconButton.home,
                  parentCallback: onButtonPressed,
                  assetName: 'Home',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
