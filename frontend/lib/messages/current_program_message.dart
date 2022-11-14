import 'package:json_annotation/json_annotation.dart';
import 'package:switch_bot_frontend/models/program_metadata.dart';

part 'current_program_message.g.dart';

@JsonSerializable()
class CurrentProgramMessage {
  final ProgramMetadata? metadata;
  @JsonKey(name: 'option_values')
  final Map<String, Object>? optionValues;

  CurrentProgramMessage({
    required this.metadata,
    required this.optionValues,
  });

  factory CurrentProgramMessage.fromJson(Map<String, dynamic> json) =>
      _$CurrentProgramMessageFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentProgramMessageToJson(this);
}
