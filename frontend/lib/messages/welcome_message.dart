import 'package:json_annotation/json_annotation.dart';
import 'package:switch_bot_frontend/models/camera_descriptor.dart';
import 'package:switch_bot_frontend/models/dialog.dart';
import 'package:switch_bot_frontend/models/program_metadata.dart';

part 'welcome_message.g.dart';

@JsonSerializable()
class WelcomeMessage {
  @JsonKey(name: 'available_programs')
  final List<ProgramMetadata> availablePrograms;
  @JsonKey(name: 'current_program_name')
  final String? currentProgramName;
  @JsonKey(name: 'current_program_options')
  final Map<String, Object?>? currentProgramOptions;
  @JsonKey(name: 'current_video')
  final CameraDescriptor? currentVideo;
  @JsonKey(name: 'available_video')
  final List<CameraDescriptor> availableVideo;
  @JsonKey(name: 'current_serial')
  final String? currentSerial;
  @JsonKey(name: 'current_dialog')
  final ProgramDialog? currentDialog;
  @JsonKey(name: 'available_serial')
  final List<String> availableSerial;
  @JsonKey(name: 'recent_program_logs')
  final List<String> recentProgramLogs;

  WelcomeMessage({
    required this.availablePrograms,
    required this.currentProgramName,
    required this.currentProgramOptions,
    required this.currentVideo,
    required this.availableVideo,
    required this.currentSerial,
    required this.currentDialog,
    required this.availableSerial,
    required this.recentProgramLogs,
  });

  factory WelcomeMessage.fromJson(Map<String, dynamic> json) => _$WelcomeMessageFromJson(json);

  Map<String, dynamic> toJson() => _$WelcomeMessageToJson(this);
}
