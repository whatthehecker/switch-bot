import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:switch_bot_frontend/message_identifiers.dart';
import 'package:switch_bot_frontend/messages/welcome_message.dart';
import 'package:switch_bot_frontend/screens/main_screen.dart';
import 'package:switch_bot_frontend/screens/settings_screen.dart';
import 'package:switch_bot_frontend/widgets/dialog_creator.dart';

class LoginScreen extends StatefulWidget {
  final bool autoConnect;

  const LoginScreen({
    required this.autoConnect,
    Key? key,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _defaultUrl = 'ws://localhost:8765';

  static final Logger _logger = Logger('_LoginScreenState');

  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  Socket? _currentSocket;
  bool _currentlyTestingConnection = false;

  @override
  void initState() {
    super.initState();

    _initializeFromPreferences();
  }

  Future<void> _initializeFromPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    String? lastUrl = preferences.getString(SettingsScreen.keyLastUrl);

    setState(() {
      _controller.text = lastUrl ?? _defaultUrl;
    });

    if (!widget.autoConnect) {
      return;
    }
    bool shouldReconnectAutomatically = preferences.getBool(SettingsScreen.keyReconnectLastUrl) == true;
    if (shouldReconnectAutomatically && lastUrl != null) {
      setState(() {
        _currentSocket = _openSocket(lastUrl);
      });
    }
  }

  Socket _openSocket(String url) {
    Socket socket = io(
      url,
      OptionBuilder().setTransports(['websocket']).enableForceNew().disableReconnection().build(),
    );

    socket.onConnect((_) {
      _logger.info('Connected to socket.');

      // Wait for welcome message with initial data before navigating to the main screen. Otherwise we could miss
      // some initial state if messages come in before the pages to be pushed have registered their listeners.
      socket.once(MessageIdentifiers.welcome, (dynamic data) {
        _logger.fine('Received welcome message with initial data.');

        WelcomeMessage welcomeMessage = WelcomeMessage.fromJson(data);
        if(welcomeMessage.currentDialog != null) {
          _logger.info('Welcome message contains an unresolved dialog, opening it soon...');
        }

        setState(() {
          _currentlyTestingConnection = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // Wrap main screen in the dialog creator so programs can request
            // dialogs to be shown no matter which sub-page is currently
            // active on the main screen.
            builder: (context) => SocketBasedDialogCreator(
              socket: _currentSocket!,
              initialDialog: welcomeMessage.currentDialog,
              // Go to main screen and make it the main screen until disconnect
              // is explicitly chosen by the user.
              child: MainScreen(
                welcomeMessage: welcomeMessage,
                socket: _currentSocket!,
              ),
            ),
          ),
        );
      });
    });
    socket.on(
      'connect_error',
      (dynamic data) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.warning),
            title: const Text('Connection failed'),
            content: SingleChildScrollView(
              child: Text(data.toString()),
            ),
          ),
        );
        _logger.warning('Connection error: $data');

        // Reset the current socket to mark it as "not usable" for the other
        // pages.
        setState(() {
          _currentlyTestingConnection = false;
          _currentSocket = null;
        });
      },
    );
    socket.onDisconnect((_) {
      _logger.info('Disconnected from socket.');

      if(!mounted) {
        return;
      }

      setState(() {
        _currentlyTestingConnection = false;
        _currentSocket = null;
      });
    });

    setState(() {
      _currentlyTestingConnection = true;
    });

    return socket;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch Bot Login'),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    label: Text('Bot URL'),
                    hintText: 'Enter the URL of the bot backend',
                  ),
                  validator: (String? input) {
                    if (input == null || input.isEmpty) {
                      return 'URL must not be empty.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton.icon(
                  icon: _currentlyTestingConnection
                      ? const SizedBox(
                          height: 8.0,
                          width: 8.0,
                          child: CircularProgressIndicator(),
                        )
                      : const Icon(Icons.power),
                  onPressed: _currentlyTestingConnection
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            String url = _controller.text;

                            setState(() {
                              _currentSocket = _openSocket(url);
                            });

                            SharedPreferences preferences = await SharedPreferences.getInstance();
                            preferences.setString(SettingsScreen.keyLastUrl, url);
                          }
                        },
                  label: const Text('Connect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
