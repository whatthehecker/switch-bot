import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:switch_bot_frontend/message_identifiers.dart';
import 'package:switch_bot_frontend/messages/current_program_message.dart';
import 'package:switch_bot_frontend/messages/start_program_message.dart';
import 'package:switch_bot_frontend/models/options/option.dart';
import 'package:switch_bot_frontend/models/program_metadata.dart';
import 'package:switch_bot_frontend/widgets/console_output_display.dart';
import 'package:switch_bot_frontend/widgets/option_configurator.dart';

class ProgramScreen extends StatefulWidget {
  final Socket socket;
  final List<ProgramMetadata>? availablePrograms;
  final String? currentProgramName;
  final Map<String, Object?>? currentProgramOptions;
  final List<String>? recentLogs;

  const ProgramScreen({
    required this.socket,
    this.currentProgramName,
    this.currentProgramOptions,
    this.availablePrograms,
    this.recentLogs,
    Key? key,
  }) : super(key: key);

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  static const int _maxLogLinesKept = 10;
  static const List<Tab> _tabs = [
    Tab(icon: Icon(Icons.play_arrow), text: 'Run program'),
    Tab(icon: Icon(Icons.text_snippet), text: 'Console log')
  ];

  static final Logger _logger = Logger('_ProgramScreenState');

  late List<ProgramMetadata> _allProgramsMetadata = widget.availablePrograms ?? [];
  late ProgramMetadata? _selectedProgramMetadata = _currentlyRunningProgram;
  late ProgramMetadata? _currentlyRunningProgram =
      _allProgramsMetadata.firstWhereOrNull((program) => program.name == widget.currentProgramName);

  /// Stores the option values for each available program.
  ///
  /// This does store the option values for programs that are not the currently
  /// selected program, simply so that a user can switch between programs
  /// without always having their options reset to the defaults again.
  late final Map<String, Map<String, Object?>> _programOptionsMap = {
    for (ProgramMetadata metadata in _allProgramsMetadata)
      metadata.name: (metadata.name == widget.currentProgramName ? widget.currentProgramOptions : null) ??
          _generateDefaultOptionValues(metadata)
  };

  late final List<String> _consoleOutput = widget.recentLogs ?? [];

  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();

    widget.socket.on(MessageIdentifiers.getProgramsResponse, _onProgramsFound);
    widget.socket.on(MessageIdentifiers.logLineEmitted, _onLogLineReceived);
    widget.socket.on(MessageIdentifiers.getRunningProgramResponse, _onCurrentRunningProgramReceived);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  void _onProgramsFound(dynamic data) {
    if (!mounted) {
      return;
    }

    List<dynamic> jsonList = data as List<dynamic>;
    List<ProgramMetadata> programs = jsonList.map((json) => ProgramMetadata.fromJson(json)).toList();

    setState(() {
      _allProgramsMetadata = programs;
      // Generate initial default values for programs which haven't been
      // initialized yet.
      for (ProgramMetadata metadata in programs) {
        _programOptionsMap[metadata.name] ??= _generateDefaultOptionValues(metadata);
      }
    });
  }

  static Map<String, Object> _generateDefaultOptionValues(ProgramMetadata metadata) {
    Map<String, Object> optionValues = {};
    for (Option<Object> option in metadata.options) {
      optionValues[option.name] = option.getDefaultValue();
    }
    return optionValues;
  }

  void _onLogLineReceived(dynamic data) {
    if (!mounted) {
      return;
    }

    String line = data as String;
    _logger.info('Log line received: $line');

    setState(() {
      // Trim the list down to number of log lines - 1 elements.
      // Remove from the start to only keep the latest log lines.
      int numberOfElementsToRemove = _consoleOutput.length - _maxLogLinesKept;
      if (numberOfElementsToRemove > 0) {
        _consoleOutput.removeRange(0, numberOfElementsToRemove);
      }
      // Add the received line so we have at most number of log lines elements.
      _consoleOutput.add(line);
    });
  }

  void _onCurrentRunningProgramReceived(dynamic data) {
    if (!mounted) {
      return;
    }

    Map<String, dynamic> json = data as Map<String, dynamic>;
    CurrentProgramMessage message = CurrentProgramMessage.fromJson(json);

    // A program was running but now it isn't, so it must have stopped.
    if (_currentlyRunningProgram != null && message.metadata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program has finished running.'),
        ),
      );
    }

    setState(() {
      _currentlyRunningProgram = message.metadata;

      if (_currentlyRunningProgram != null) {
        _programOptionsMap[_currentlyRunningProgram!.name] = message.optionValues!;
      }

      // If there was no program selected to launch, select the currently running program as a default.
      if (_selectedProgramMetadata == null && _currentlyRunningProgram != null) {
        _selectedProgramMetadata = _currentlyRunningProgram;
      }
    });
  }

  Widget _buildProgramWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: _selectedProgramMetadata?.name,
              hint: const Text('Select a program'),
              selectedItemBuilder: (context) => _allProgramsMetadata.map((metadata) {
                Widget child;

                if (metadata.name == _currentlyRunningProgram?.name) {
                  child = Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: metadata.name),
                        const WidgetSpan(
                          child: Icon(Icons.play_arrow, color: Colors.red),
                        ),
                        const TextSpan(
                          text: ' (running)',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                } else {
                  child = Text(metadata.name);
                }

                return Container(
                  alignment: Alignment.center,
                  child: child,
                );
              }).toList(),
              items: _allProgramsMetadata.map(
                (ProgramMetadata metadata) {
                  return DropdownMenuItem<String>(
                    value: metadata.name,
                    child: metadata.name == _currentlyRunningProgram?.name
                        ? Text('${metadata.name} (running)')
                        : Text(metadata.name),
                  );
                },
              ).toList(),
              onChanged: (String? selectedProgramName) {
                if (selectedProgramName == null) {
                  return;
                }

                setState(() {
                  _selectedProgramMetadata =
                      _allProgramsMetadata.firstWhere((metadata) => metadata.name == selectedProgramName);
                });
              },
            ),
            TextButton.icon(
              onPressed: () {
                widget.socket.emit(MessageIdentifiers.getRunningProgramRequest);
                widget.socket.emit(MessageIdentifiers.reloadPrograms);
              },
              label: const Text('Reload'),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        Text(
          _selectedProgramMetadata?.description ?? 'No program selected.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_selectedProgramMetadata != null)
          OptionConfigurator(
            key: _selectedProgramMetadata == null ? null : ValueKey(_selectedProgramMetadata!.name),
            lockOptionsCurrentlyInUse:
                _selectedProgramMetadata != null && _selectedProgramMetadata?.name == _currentlyRunningProgram?.name,
            options: _selectedProgramMetadata!.options,
            currentOptionValues: _programOptionsMap[_selectedProgramMetadata!.name]!,
            onOptionChanged: (String optionName, Object? value) {
              setState(() {
                _programOptionsMap[_selectedProgramMetadata!.name]![optionName] = value;
              });
            },
          )
        else
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('This program has no options to set.'),
          )
      ],
    );
  }

  Widget _buildProgramConfigWidget() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(child: SingleChildScrollView(child: _buildProgramWidget())),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                // If the selected program is currently running, show a button
                // to update any options that are allowed to be changed
                // at runtime.
                // Otherwise show a button to start the selected program with
                // the chosen option values.
                child:
                    _currentlyRunningProgram != null && _selectedProgramMetadata?.name == _currentlyRunningProgram?.name
                        ? ElevatedButton(
                            onPressed: () {
                              widget.socket.emit(
                                MessageIdentifiers.updateRunningProgramOptionValues,
                                _programOptionsMap[_selectedProgramMetadata]!,
                              );
                            },
                            child: const Text('Update options'),
                          )
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                            onPressed: () {
                              setState(() {
                                _currentlyRunningProgram = _selectedProgramMetadata;
                              });

                              widget.socket.emit(MessageIdentifiers.stopProgram);

                              StartProgramMessage startMessage = StartProgramMessage(
                                programName: _selectedProgramMetadata!.name,
                                optionValues: _programOptionsMap[_selectedProgramMetadata!.name]!,
                              );
                              widget.socket.emit(MessageIdentifiers.startProgramRequest, startMessage.toJson());
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                // TODO: this button and the start button should show splashes to be more responsive!
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  onPressed: () {
                    widget.socket.emit(MessageIdentifiers.stopProgram);
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildConsoleWidget() {
    return _consoleOutput.isEmpty
        ? const Center(
            child: Text('Nothing has been written to the console yet.'),
          )
        : ConsoleOutputDisplay(
            lineCount: 10,
            consoleLines: _consoleOutput.toList(),
          );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          indicatorColor: Colors.orange,
          labelColor: Colors.orangeAccent,
          controller: _tabController,
          tabs: _tabs,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProgramConfigWidget(),
              _buildConsoleWidget(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
