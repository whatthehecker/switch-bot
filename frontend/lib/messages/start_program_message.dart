import 'package:json_annotation/json_annotation.dart';

part 'start_program_message.g.dart';

@JsonSerializable()
class StartProgramMessage {
  @JsonKey(name: 'program_name')
  final String programName;

  @JsonKey(name: 'option_values')
  final Map<String, Object?> optionValues;

  StartProgramMessage({required this.programName, required this.optionValues});

  factory StartProgramMessage.fromJson(Map<String, dynamic> json) => _$StartProgramMessageFromJson(json);

  Map<String, dynamic> toJson() => _$StartProgramMessageToJson(this);
}