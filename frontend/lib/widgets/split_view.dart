import 'dart:math';

import 'package:flutter/material.dart';

/// A widget that splits itself into a top and a bottom part which can be
/// resized by dragging a splitter.
class SplitView extends StatefulWidget {
  final Widget splitter;
  final double splitterHeight;
  final List<Widget> children;
  final double initialRatio;
  final double maxRatio;
  final double minRatio;

  const SplitView({
    required this.splitter,
    this.splitterHeight = 8.0,
    required this.children,
    this.maxRatio = 0.75,
    this.minRatio = 0.25,
    this.initialRatio = 0.5,
    Key? key,
  })  : assert(children.length == 2),
        assert(maxRatio <= 1.0 && maxRatio >= 0.0),
        assert(minRatio <= 1.0 && minRatio >= 0.0),
        assert(minRatio <= maxRatio),
        assert(initialRatio >= minRatio && initialRatio <= maxRatio),
        super(key: key);

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late double _ratio = widget.initialRatio;
  late double _maxHeight;

  @override
  Widget build(BuildContext context) {
    // Code adapted from https://medium.com/@leonar.d/how-to-create-a-flutter-split-view-7e2ac700ea12
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _maxHeight = constraints.maxHeight - widget.splitterHeight;

        double topHeight =
            _ratio * constraints.maxHeight - widget.splitterHeight / 2;
        double bottomHeight =
            (1 - _ratio) * constraints.maxHeight - widget.splitterHeight / 2;

        return SizedBox(
          width: constraints.maxWidth,
          child: Column(
            children: [
              SizedBox(
                height: topHeight,
                child: widget.children[0],
              ),
              SizedBox(
                height: widget.splitterHeight,
                width: constraints.maxWidth,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (DragUpdateDetails details) {
                    setState(() {
                      _ratio += details.delta.dy / _maxHeight;
                      // Clamp to [0, 1].
                      _ratio = max(min(_ratio, 1.0), 0.0);
                      // Clamp to [minRatio, maxRatio].
                      _ratio = min(_ratio, widget.maxRatio);
                      _ratio = max(_ratio, widget.minRatio);
                    });
                  },
                  child: widget.splitter,
                ),
              ),
              SizedBox(
                height: bottomHeight,
                child: widget.children[1],
              ),
            ],
          ),
        );
      },
    );
  }
}
