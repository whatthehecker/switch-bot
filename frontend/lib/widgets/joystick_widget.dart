import 'dart:math';

import 'package:flutter/material.dart';

typedef JoystickCallback = void Function(double radius, double degrees);

class JoystickWidget extends StatefulWidget {
  final Widget child;
  final double childWidthAndHeight;
  final double widthAndHeight;
  final JoystickCallback onJoystickMove;

  const JoystickWidget({
    required this.child,
    required this.childWidthAndHeight,
    required this.widthAndHeight,
    required this.onJoystickMove,
    Key? key,
  }) : super(key: key);

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget> {
  double _x = 0;
  double _y = 0;

  late final double maxRadius = (widget.widthAndHeight - widget.childWidthAndHeight) / 2;

  Point<double> _cartesianToPolar(double x, double y) {
    double maxRadius = widget.widthAndHeight / 2 - widget.childWidthAndHeight / 2;
    double r = sqrt(x * x + y * y) / maxRadius;
    // Take negative y coordinate since this is a graphical coordinate system
    // which starts from the top but we want the angle as if it was a regular
    // coordinate system starting from the bottom.
    double angle = atan2(-y, x);
    return Point<double>(r, angle);
  }

  Point<double> _clampToUnitCircle(double x, double y) {
    double length = sqrt(x * x + y * y);
    // Normalize vector to length of 1.
    if(length > maxRadius) {
      return Point(x, y) * (1.0 / length);
    }
    // Normalize vector to a length between 0 and 1.
    return Point(x, y) * (1.0 / maxRadius);
  }

  void _onDragStart(DragStartDetails details) {
    _updateWithLocalPosition(details.localPosition);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updateWithLocalPosition(details.localPosition);
  }

  void _updateWithLocalPosition(Offset localPosition) {
    double tempX = localPosition.dx - widget.widthAndHeight / 2;
    double tempY = localPosition.dy - widget.widthAndHeight / 2;
    Point<double> newPos = _clampToUnitCircle(tempX, tempY) * maxRadius;

    setState(() {
      _x = newPos.x;
      _y = newPos.y;
    });

    Point<double> polarCoordinates = _cartesianToPolar(_x, _y);
    widget.onJoystickMove(polarCoordinates.x, polarCoordinates.y);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _x = 0;
      _y = 0;
    });

    widget.onJoystickMove(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onDragStart,
      onVerticalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onVerticalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onVerticalDragEnd: _onDragEnd,
      child: Container(
        width: widget.widthAndHeight,
        height: widget.widthAndHeight,
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(widget.widthAndHeight / 2),
        ),
        child: Stack(
          children: [
            Positioned(
              left: widget.widthAndHeight/ 2 + _x - widget.childWidthAndHeight / 2,
              top: widget.widthAndHeight / 2 + _y - widget.childWidthAndHeight / 2,
              child: IgnorePointer(
                child: SizedBox(
                  width: widget.childWidthAndHeight,
                  height: widget.childWidthAndHeight,
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
