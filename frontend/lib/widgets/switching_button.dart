import 'package:flutter/material.dart';

/// A button that displays a different child widget when it is pressed.
class SwitchingButton extends StatefulWidget {
  final Widget releasedChild;
  final Widget pressedChild;
  final VoidCallback? onPressed;

  const SwitchingButton({
    required this.releasedChild,
    required this.pressedChild,
    this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  State<SwitchingButton> createState() => _SwitchingButtonState();
}

class _SwitchingButtonState extends State<SwitchingButton> {
  bool _isPressed = false;

  Widget _buildChild() {
    Widget child = _isPressed ? widget.pressedChild : widget.releasedChild;

    // If widget should be disabled, tint the child grey.
    if (widget.onPressed == null) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.multiply),
        child: child,
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null
          ? null
          : (_) {
              widget.onPressed!();

              setState(() {
                _isPressed = true;
              });
            },
      onTapUp: widget.onPressed == null
          ? null
          : (_) {
              setState(() {
                _isPressed = false;
              });
            },
      child: _buildChild(),
    );
  }
}
