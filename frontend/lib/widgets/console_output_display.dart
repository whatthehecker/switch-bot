import 'dart:math';

import 'package:flutter/material.dart';

class ConsoleOutputDisplay extends StatefulWidget {
  final int lineCount;
  final List<String> _relevantConsoleLines;

  ConsoleOutputDisplay({
    required this.lineCount,
    required List<String> consoleLines,
    Key? key,
  })  : _relevantConsoleLines = consoleLines.sublist(max(0, consoleLines.length - lineCount)),
        super(key: key);

  @override
  State<ConsoleOutputDisplay> createState() => _ConsoleOutputDisplayState();
}

class _ConsoleOutputDisplayState extends State<ConsoleOutputDisplay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Make the list scroll down all the way when it is shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      controller: _scrollController,
      itemBuilder: (BuildContext context, int index) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(widget._relevantConsoleLines[index], textAlign: TextAlign.start),
      ),
      separatorBuilder: (BuildContext _, int __) => const Divider(),
      itemCount: widget._relevantConsoleLines.length,
    );
  }
}
