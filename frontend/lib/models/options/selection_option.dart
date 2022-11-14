import 'package:json_annotation/json_annotation.dart';
import 'package:switch_bot_frontend/models/options/option.dart';

part 'selection_option.g.dart';

@JsonSerializable()
class SelectionOption extends Option<String> {
  final List<String> choices;
  @JsonKey(name: 'default_value_index')
  final int defaultValueIndex;

  SelectionOption({
    required this.choices,
    required this.defaultValueIndex,
    required super.name,
    required super.description,
    super.allowChangeAtRuntime,
  }): super('selection');

  factory SelectionOption.fromJson(Map<String, dynamic> json) =>
      _$SelectionOptionFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SelectionOptionToJson(this);

  @override
  String getDefaultValue() {
    assert(choices.length > defaultValueIndex);

    return choices[defaultValueIndex];
  }
}
