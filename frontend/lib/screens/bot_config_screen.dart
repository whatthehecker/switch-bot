import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:switch_bot_frontend/message_identifiers.dart';
import 'package:switch_bot_frontend/messages/result_message.dart';
import 'package:switch_bot_frontend/models/camera_descriptor.dart';

/// Screen to configure values of the bot after it has been connected to.
class BotConfigScreen extends StatefulWidget {
  final Socket socket;
  final List<String>? availableSerialPorts;
  final String? currentPort;
  final CameraDescriptor? currentCamera;
  final List<CameraDescriptor>? availableCameras;

  const BotConfigScreen({
    required this.socket,
    this.availableCameras,
    this.availableSerialPorts,
    this.currentCamera,
    this.currentPort,
    Key? key,
  }) : super(key: key);

  @override
  State<BotConfigScreen> createState() => _BotConfigScreenState();
}

class _BotConfigScreenState extends State<BotConfigScreen> with AutomaticKeepAliveClientMixin {
  late String? _currentPort = widget.currentPort;
  late List<String> _availableSerialPorts = widget.availableSerialPorts ?? [];

  late CameraDescriptor? _currentCamera = widget.currentCamera;
  late List<CameraDescriptor> _availableCameras = widget.availableCameras ?? [];

  @override
  void initState() {
    super.initState();

    // Register handlers for messages.
    widget.socket.on(MessageIdentifiers.currentSerialResponse, _handleCurrentSerialPortResponse);
    widget.socket.on(MessageIdentifiers.allSerialsResponse, _handleSerialPortsFound);
    widget.socket.on(MessageIdentifiers.currentVideoResponse, _handleCurrentVideoResponse);
    widget.socket.on(MessageIdentifiers.allVideoResponse, _handleVideosFound);
    widget.socket.on(MessageIdentifiers.connectSerialResponse, _handleConnectSerialResponse);
    widget.socket.on(MessageIdentifiers.connectVideoResponse, _handleConnectVideoResponse);
  }

  void _handleCurrentSerialPortResponse(dynamic data) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentPort = data as String?;
    });
  }

  void _handleSerialPortsFound(dynamic data) {
    if (!mounted) {
      return;
    }

    List<String> portNames = List.castFrom(data);

    setState(() {
      _availableSerialPorts = portNames;
    });
  }

  void _handleCurrentVideoResponse(dynamic data) {
    if (!mounted) {
      return;
    }

    Map<String, dynamic>? json = data as Map<String, dynamic>?;
    CameraDescriptor? descriptor = json == null ? null : CameraDescriptor.fromJson(json);

    setState(() {
      _currentCamera = descriptor;
    });
  }

  void _handleVideosFound(dynamic data) {
    if (!mounted) {
      return;
    }

    List<Map<String, dynamic>> camerasJson = List.castFrom(data);
    List<CameraDescriptor> descriptors =
        camerasJson.map((descriptorJson) => CameraDescriptor.fromJson(descriptorJson)).toList();
    setState(() {
      _availableCameras = descriptors;
    });
  }

  void _handleConnectSerialResponse(dynamic data) {
    ResultMessage message = ResultMessage.fromJson(data as Map<String, dynamic>);

    if (!message.success) {
      // Connection failed, mark as "not connected" in UI.
      setState(() {
        _currentPort = null;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning),
          title: const Text('Connection to controller failed'),
          content: SingleChildScrollView(
            child: Text('Could not connect to controller: ${message.errorMessage}'),
          ),
        ),
      );
    }
  }

  void _handleConnectVideoResponse(dynamic data) {
    ResultMessage message = ResultMessage.fromJson(data as Map<String, dynamic>);

    if (!message.success) {
      // Connection failed, mark as "not connected" in selector.
      setState(() {
        _currentCamera = null;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning),
          title: const Text('Connection to capture card failed'),
          content: SingleChildScrollView(
            child: Text('Could not connect to capture card: ${message.errorMessage}'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    List<Widget> children = [
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(label: Text('Serial port')),
              value: _currentPort,
              hint: const Text('No controller selected'),
              items: _availableSerialPorts
                  .map(
                    (portName) => DropdownMenuItem(
                      value: portName,
                      child: Text(portName),
                    ),
                  )
                  .toList(),
              onChanged: (String? portName) {
                if (portName == null) {
                  return;
                }

                setState(() {
                  _currentPort = portName;
                  // TODO: handle response to this instead of getting the serial again afterwards.
                  widget.socket.emit(MessageIdentifiers.connectSerialRequest, _currentPort);
                  widget.socket.emit(MessageIdentifiers.currentSerialRequest);
                });
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentPort = null;
                    widget.socket.emit(MessageIdentifiers.disconnectSerial);
                  });
                },
                icon: const Icon(Icons.close),
                label: const Text('Disconnect'),
              ),
              TextButton.icon(
                onPressed: () {
                  widget.socket.emit(MessageIdentifiers.currentSerialRequest);
                  widget.socket.emit(MessageIdentifiers.allSerialsRequest);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField(
              value: _currentCamera,
              hint: const Text('No video connected'),
              decoration: const InputDecoration(label: Text('Video Camera')),
              // TODO: refresh throws when current selection is null.
              items: _availableCameras
                  .map(
                    (descriptor) => DropdownMenuItem(
                      value: descriptor,
                      child: Text(descriptor.name),
                    ),
                  )
                  .toList(),
              onChanged: (CameraDescriptor? newDescriptor) {
                if (newDescriptor == null) {
                  return;
                }

                setState(() {
                  _currentCamera = newDescriptor;
                  widget.socket.emit(MessageIdentifiers.connectVideoRequest, newDescriptor.toJson());
                  widget.socket.emit(MessageIdentifiers.currentVideoRequest);
                });
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () {
                  widget.socket.emit(MessageIdentifiers.disconnectVideo);
                },
                icon: const Icon(Icons.close),
                label: const Text('Disconnect'),
              ),
              TextButton.icon(
                onPressed: () {
                  widget.socket.emit(MessageIdentifiers.currentVideoRequest);
                  widget.socket.emit(MessageIdentifiers.allVideoRequest);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    ];

    return Center(
      child: ListView.separated(
        itemBuilder: (BuildContext _, int index) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: children[index],
        ),
        padding: const EdgeInsets.all(8.0),
        separatorBuilder: (BuildContext context, int index) => const Divider(),
        itemCount: children.length,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
