import 'package:json_annotation/json_annotation.dart';

part 'dialog.g.dart';

// Named differently from the Python class to avoid naming conflicts with the built-in Dialog class.
@JsonSerializable()
class ProgramDialog {
  final String title;
  final String content;
  final List<String> buttons;
  @JsonKey(name: 'is_modal', defaultValue: false)
  final bool isModal;

  ProgramDialog({
    required this.title,
    required this.content,
    required this.buttons,
    this.isModal = false,
  });

  factory ProgramDialog.fromJson(Map<String, dynamic> json) => _$ProgramDialogFromJson(json);

  Map<String, dynamic> toJson() => _$ProgramDialogToJson(this);
}
