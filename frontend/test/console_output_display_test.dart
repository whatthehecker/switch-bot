import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:switch_bot_frontend/widgets/console_output_display.dart';

void main() {
  testWidgets(
    'Console lines are displayed',
    (WidgetTester tester) async {
      const int lineCount = 10;
      List<String> lines =
          List.generate(lineCount, (index) => 'A console line');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ConsoleOutputDisplay(
            lineCount: lineCount,
            consoleLines: lines,
          ),
        ),
      );

      expect(find.text('A console line'), findsNWidgets(10));
    },
  );

  testWidgets(
    'Extra lines are not shown',
    (WidgetTester tester) async {
      const int lineCount = 5;
      const int extraLinesCount = 2;
      List<String> lines = List.generate(
          lineCount + extraLinesCount, (index) => 'Message $index');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ConsoleOutputDisplay(
            lineCount: lineCount,
            consoleLines: lines,
          ),
        ),
      );

      for (int i = 0; i < lineCount; i++) {
        // Expect to find the last [lineCount] messages in the widget, since
        // the widget should only keep the last [lineCount] elements.
        expect(find.text('Message ${lineCount + extraLinesCount - 1 - i}'), findsOneWidget);
      }
      for (int i = 0; i < extraLinesCount; i++) {
        // The first elements should not be shown and as such should not be
        // found.
        expect(find.text('Message $i'), findsNothing);
      }
    },
  );

  testWidgets(
    'All lines are shown if fewer than max lines allowed exist ',
    (tester) async {
      const int maxLinesCount = 10;
      const int actualLinesCount = 4;
      List<String> lines =
          List.generate(actualLinesCount, (index) => 'Another message');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ConsoleOutputDisplay(
            lineCount: maxLinesCount,
            consoleLines: lines,
          ),
        ),
      );

      expect(find.text('Another message'), findsNWidgets(actualLinesCount));
    },
  );
}
