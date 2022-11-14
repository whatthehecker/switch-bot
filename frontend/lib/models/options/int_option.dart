import 'package:json_annotation/json_annotation.dart';
import 'package:switch_bot_frontend/models/options/option.dart';

part 'int_option.g.dart';

@JsonSerializable()
class IntOption extends Option<int> {
  @JsonKey(name: 'min_value')
  final int? minValue;
  @JsonKey(name: 'max_value')
  final int? maxValue;
  @JsonKey(name: 'default_value')
  final int defaultValue;

  IntOption({
    required super.name,
    required super.description,
    this.minValue,
    this.maxValue,
    required this.defaultValue,
    super.allowChangeAtRuntime,
  }) : super('int');

  factory IntOption.fromJson(Map<String, dynamic> json) => _$IntOptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$IntOptionToJson(this);

  @override
  int getDefaultValue() => defaultValue;
}
