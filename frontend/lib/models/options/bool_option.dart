import 'package:json_annotation/json_annotation.dart';
import 'package:switch_bot_frontend/models/options/option.dart';

part 'bool_option.g.dart';

@JsonSerializable()
class BoolOption extends Option<bool> {
  @JsonKey(name: 'default_value', defaultValue: true)
  final bool defaultValue;

  BoolOption({
    required super.name,
    required super.description,
    required this.defaultValue,
    super.allowChangeAtRuntime,
  }) : super('bool');

  factory BoolOption.fromJson(Map<String, dynamic> json) => _$BoolOptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BoolOptionToJson(this);

  @override
  bool getDefaultValue() => defaultValue;
}
