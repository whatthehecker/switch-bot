import 'package:json_annotation/json_annotation.dart';
import 'package:switch_bot_frontend/models/options/option.dart';

part 'string_option.g.dart';

@JsonSerializable()
class StringOption extends Option<String> {
  @JsonKey(name: 'default_value')
  final String defaultValue;

  StringOption({
    required this.defaultValue,
    required super.name,
    required super.description,
    super.allowChangeAtRuntime,
  }) : super('string');

  factory StringOption.fromJson(Map<String, dynamic> json) => _$StringOptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$StringOptionToJson(this);

  @override
  String getDefaultValue() => defaultValue;
}
