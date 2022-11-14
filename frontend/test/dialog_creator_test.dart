import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:switch_bot_frontend/message_identifiers.dart';
import 'package:switch_bot_frontend/messages/dialog_closed_message.dart';
import 'package:switch_bot_frontend/messages/show_dialog_message.dart';
import 'package:switch_bot_frontend/models/dialog.dart';
import 'package:switch_bot_frontend/widgets/dialog_creator.dart';

import 'mocks/mock_socket.mocks.dart';

void main() {
  testWidgets(
    'Dialog creator displays child',
    (WidgetTester tester) async {
      Widget child = const Text('Some interesting string');
      MockSocket socket = MockSocket();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SocketBasedDialogCreator(
            socket: socket,
            child: child,
          ),
        ),
      );

      expect(find.byWidget(child), findsOneWidget);
    },
  );

  testWidgets(
    'Dialog is shown when socket emits event',
    (WidgetTester tester) async {
      const Widget child = Text('Ignored');

      MockSocket socket = MockSocket();

      // Capture and store the event handler of the widget to invoke it later
      // manually.
      late void Function(dynamic) eventHandler;
      when(socket.on(MessageIdentifiers.showDialogRequest, any)).thenAnswer((realInvocation) {
        eventHandler = realInvocation.positionalArguments[1];
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SocketBasedDialogCreator(
            socket: socket,
            child: child,
          ),
        ),
      );
      expect(find.byType(AlertDialog), findsNothing);
      verify(socket.on(MessageIdentifiers.showDialogRequest, any)).called(1);

      // Request a dialog to be shown.
      ShowDialogMessage message = ShowDialogMessage(
        dialog: ProgramDialog(
          title: 'Some title',
          content: 'Some content',
          buttons: ['OK'],
        ),
      );
      eventHandler(message.toJson());

      // Wait for the event handler to trigger dialog creation.
      await tester.pumpAndSettle();

      Finder dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);
      expect(
        find.descendant(
          of: dialogFinder,
          matching: find.text('Some title'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialogFinder,
          matching: find.text('Some content'),
        ),
        findsOneWidget,
      );
      // Dialog ID is internal and should not be shown.
      expect(
        find.descendant(
          of: dialogFinder,
          matching: find.text('123'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: dialogFinder,
          matching: find.widgetWithText(TextButton, 'OK'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Closing dialog sends correct message',
    (WidgetTester tester) async {
      const Widget child = Text('Ignored');

      MockSocket socket = MockSocket();

      // Capture and store the event handler of the widget to invoke it later
      // manually.
      late void Function(dynamic) eventHandler;
      when(socket.on(MessageIdentifiers.showDialogRequest, any)).thenAnswer((realInvocation) {
        eventHandler = realInvocation.positionalArguments[1];
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SocketBasedDialogCreator(
            socket: socket,
            child: child,
          ),
        ),
      );

      verify(socket.on(MessageIdentifiers.showDialogRequest, any)).called(1);

      // Request a dialog to be shown.
      ShowDialogMessage message = ShowDialogMessage(
        dialog: ProgramDialog(
          title: 'Some title',
          content: 'Some content',
          buttons: ['OK'],
        ),
      );
      eventHandler(message.toJson());
      await tester.pumpAndSettle();

      // Store the emitted JSON result for later inspection.
      late Map<String, dynamic> emittedJson;
      when(socket.emit(MessageIdentifiers.dialogClosed, any)).thenAnswer((realInvocation) {
        emittedJson = realInvocation.positionalArguments[1];
      });

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'OK'),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure a message has been emitted before accessing the JSON result
      // that should have been set.
      verify(socket.emit(MessageIdentifiers.dialogClosed, any)).called(1);

      DialogClosedMessage closedMessage = DialogClosedMessage.fromJson(emittedJson);
      expect(closedMessage.button, 'OK');
    },
  );

  testWidgets(
    'Modal dialogs cannot be dismissed by tapping the background barrier.',
    (WidgetTester tester) async {
      const Widget child = Text('Ignored');

      MockSocket socket = MockSocket();

      // Capture and store the event handler of the widget to invoke it later
      // manually.
      late void Function(dynamic) eventHandler;
      when(socket.on(MessageIdentifiers.showDialogRequest, any)).thenAnswer((realInvocation) {
        eventHandler = realInvocation.positionalArguments[1];
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SocketBasedDialogCreator(
            socket: socket,
            child: child,
          ),
        ),
      );

      verify(socket.on(MessageIdentifiers.showDialogRequest, any)).called(1);

      // Request a dialog to be shown.
      ShowDialogMessage message = ShowDialogMessage(
        dialog: ProgramDialog(
          title: 'Some title',
          content: 'Some content',
          buttons: ['OK'],
          isModal: true,
        ),
      );
      eventHandler(message.toJson());
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap outside of the AlertDialog's rect.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      verifyNever(socket.emit(MessageIdentifiers.dialogClosed, any));
      expect(find.byType(AlertDialog), findsOneWidget);
    },
  );

  testWidgets(
    'Non-modal dialogs can be dismissed by tapping the background barrier.',
    (WidgetTester tester) async {
      const Widget child = Text('Ignored');

      MockSocket socket = MockSocket();

      // Capture and store the event handler of the widget to invoke it later
      // manually.
      late void Function(dynamic) eventHandler;
      when(socket.on(MessageIdentifiers.showDialogRequest, any)).thenAnswer((realInvocation) {
        eventHandler = realInvocation.positionalArguments[1];
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SocketBasedDialogCreator(
            socket: socket,
            child: child,
          ),
        ),
      );

      verify(socket.on(MessageIdentifiers.showDialogRequest, any)).called(1);

      // Request a dialog to be shown.
      ShowDialogMessage message = ShowDialogMessage(
        dialog: ProgramDialog(
          title: 'Some title',
          content: 'Some content',
          buttons: ['OK'],
          isModal: false,
        ),
      );
      eventHandler(message.toJson());
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      // We need to check whether this is the dialog's ModalBarrier, since there
      // exists another one in the widget tree.
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(AlertDialog),
        ),
        findsNothing,
      );

      // Tap outside of the AlertDialog's rect.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      verify(socket.emit(MessageIdentifiers.dialogClosed, any)).called(1);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
