import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:switch_bot_frontend/message_identifiers.dart';
import 'package:switch_bot_frontend/messages/dialog_closed_message.dart';
import 'package:switch_bot_frontend/messages/show_dialog_message.dart';
import 'package:switch_bot_frontend/models/dialog.dart';

/// Creates dialog windows in the navigator whenever a message is
/// received from the given [Socket].
class SocketBasedDialogCreator extends StatefulWidget {
  final Socket socket;
  final Widget child;
  final ProgramDialog? initialDialog;

  const SocketBasedDialogCreator({
    required this.socket,
    required this.child,
    this.initialDialog,
    Key? key,
  }) : super(key: key);

  @override
  State<SocketBasedDialogCreator> createState() => _SocketBasedDialogCreatorState();
}

class _SocketBasedDialogCreatorState extends State<SocketBasedDialogCreator> {
  @override
  void initState() {
    super.initState();

    widget.socket.on(MessageIdentifiers.showDialogRequest, _onShowDialogMessageReceived);

    // If there is an initial dialog to show, show it after the widget is ready.
    if (widget.initialDialog != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDialogAndEmitResponse(widget.initialDialog!));
    }
  }

  Widget _createDialog(ProgramDialog dialog) {
    return AlertDialog(
      title: Text(dialog.title),
      // Wrap the text in a scroll view in case it is too long to fit on
      // the screen normally.
      content: SingleChildScrollView(child: Text(dialog.content)),
      actions: dialog.buttons.map((String buttonName) {
        return TextButton(
          onPressed: () {
            Navigator.pop(context, buttonName);
          },
          child: Text(buttonName),
        );
      }).toList(),
    );
  }

  void _onShowDialogMessageReceived(dynamic data) async {
    Map<String, dynamic> json = data as Map<String, dynamic>;
    ShowDialogMessage showMessage = ShowDialogMessage.fromJson(json);

    _showDialogAndEmitResponse(showMessage.dialog);
  }
  
  Future<void> _showDialogAndEmitResponse(ProgramDialog programDialog) async {
    // Create and show the dialog.
    Widget dialogWidget = _createDialog(programDialog);
    
    String? chosenButton = await showDialog(
      context: context,
      builder: (context) => dialogWidget,
      barrierDismissible: !programDialog.isModal,
    );

    // Once it has been closed, create the response message and emit it back to the backend.
    DialogClosedMessage closedMessage = DialogClosedMessage(button: chosenButton);
    widget.socket.emit(MessageIdentifiers.dialogClosed, closedMessage.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
