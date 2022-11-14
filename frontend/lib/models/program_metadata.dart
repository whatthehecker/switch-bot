import 'package:json_annotation/json_annotation.dart';
import 'package:switch_bot_frontend/models/options/option.dart';

part 'program_metadata.g.dart';

@JsonSerializable()
class ProgramMetadata {
  @JsonKey(fromJson: optionsFromJson, toJson: optionsToJson)
  final List<Option<Object>> options;
  final String name;
  final String description;

  ProgramMetadata(this.name, this.description, this.options);

  factory ProgramMetadata.fromJson(Map<String, dynamic> json) =>
      _$ProgramMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramMetadataToJson(this);

  static List<Option<Object>> optionsFromJson(
      List<dynamic> dynamicList) {
    List<Map<String, dynamic>> jsonList = List.castFrom(dynamicList);
    return jsonList.map((json) => Option.fromJson(json)).toList();
  }

  static List<Map<String, dynamic>> optionsToJson(List<Option> options) {
    return options.map((option) => option.toJson()).toList();
  }
}
