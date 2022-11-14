import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:switch_bot_frontend/message_identifiers.dart';
import 'package:switch_bot_frontend/messages/video_frame_message.dart';
import 'package:switch_bot_frontend/messages/welcome_message.dart';
import 'package:switch_bot_frontend/screens/bot_config_screen.dart';
import 'package:switch_bot_frontend/screens/controller_screen.dart';
import 'package:switch_bot_frontend/screens/login_screen.dart';
import 'package:switch_bot_frontend/screens/program_screen.dart';
import 'package:switch_bot_frontend/screens/settings_screen.dart';
import 'package:switch_bot_frontend/widgets/image_display_widget.dart';
import 'package:switch_bot_frontend/widgets/split_view.dart';

class MainScreen extends StatefulWidget {
  final Socket socket;
  final WelcomeMessage? welcomeMessage;

  const MainScreen({
    required this.socket,
    this.welcomeMessage,
    Key? key,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  static final Logger _logger = Logger('_MainScreenState');

  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  Uint8List? _currentImageBytes;

  @override
  void initState() {
    super.initState();

    widget.socket.on(MessageIdentifiers.videoFrameGrabbed, _onCameraFrameReceived);
    widget.socket.onDisconnect((dynamic reason) {
      _logger.info('Connection was closed.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(
            autoConnect: false,
          ),
        ),
      );

      // Only show "connection lost" dialog if connection was not closed by pressing the disconnect button.
      if(reason != 'io client disconnect') {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text('Connection lost'),
            content: SingleChildScrollView(
              child: Text('Connection to the Switch Bot was lost.'),
            ),
          ),
        );
      }
    });
  }

  void _onCameraFrameReceived(dynamic data) {
    if (!mounted) {
      return;
    }

    Map<String, dynamic> json = data as Map<String, dynamic>;
    VideoFrameMessage message = VideoFrameMessage.fromJson(json);

    Uint8List decodedBytes = base64Decode(message.base64Image);

    setState(() {
      _currentImageBytes = decodedBytes;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch Bot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () {
              // Only disconnect and don't push a page to the navigator - the socket callback does this.
              widget.socket.disconnect();
            },
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.orange.shade200,
        currentIndex: _currentPageIndex,
        onTap: (int newPageIndex) {
          setState(() {
            // TODO: children are rebuilt every time they scroll into view, they shouldn't do that.
            _currentPageIndex = newPageIndex;
            _pageController.animateToPage(
              newPageIndex,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Bot Configuration',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.control_camera),
            label: 'Controller',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Program',
          ),
        ],
      ),
      body: SplitView(
        splitterHeight: 16.0,
        initialRatio: 0.3,
        minRatio: 0.25,
        maxRatio: 0.5,
        splitter: const Icon(
          Icons.drag_handle,
          size: 16.0,
        ),
        children: [
          ImageDisplayWidget(
            _currentImageBytes,
            aspectRatio: 16.0 / 9.0,
          ),
          PageView(
            controller: _pageController,
            onPageChanged: (int newPageIndex) {
              setState(() {
                _currentPageIndex = newPageIndex;
              });
            },
            children: [
              BotConfigScreen(
                socket: widget.socket,
                availableCameras: widget.welcomeMessage?.availableVideo,
                availableSerialPorts: widget.welcomeMessage?.availableSerial,
                currentCamera: widget.welcomeMessage?.currentVideo,
                currentPort: widget.welcomeMessage?.currentSerial,
              ),
              ControllerScreen(socket: widget.socket),
              ProgramScreen(
                socket: widget.socket,
                availablePrograms: widget.welcomeMessage?.availablePrograms,
                currentProgramName: widget.welcomeMessage?.currentProgramName,
                currentProgramOptions: widget.welcomeMessage?.currentProgramOptions,
                recentLogs: widget.welcomeMessage?.recentProgramLogs,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
