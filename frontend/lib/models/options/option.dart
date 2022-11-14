import 'package:json_annotation/json_annotation.dart';
import 'package:switch_bot_frontend/models/options/bool_option.dart';
import 'package:switch_bot_frontend/models/options/int_option.dart';
import 'package:switch_bot_frontend/models/options/selection_option.dart';
import 'package:switch_bot_frontend/models/options/string_option.dart';

abstract class Option<T> {
  final String type;
  final String name;
  final String description;
  @JsonKey(name: 'allow_change_at_runtime')
  final bool allowChangeAtRuntime;

  Option(this.type, {
    required this.name,
    required this.description,
    this.allowChangeAtRuntime = false,
  });

  Map<String, dynamic> toJson();

  static Option<Object> fromJson(Map<String, dynamic> json) {
    String type = json['type'];
    switch(type) {
      case 'int':
        return IntOption.fromJson(json);
      case 'bool':
        return BoolOption.fromJson(json);
      case 'string':
        return StringOption.fromJson(json);
      case 'selection':
        return SelectionOption.fromJson(json);
      default:
        throw StateError('Unknown option type in JSON: $type');
    }
  }

  T getDefaultValue();
}
