import 'package:json_annotation/json_annotation.dart';
import 'package:switch_bot_frontend/models/dialog.dart';

part 'show_dialog_message.g.dart';

@JsonSerializable()
class ShowDialogMessage {
  final ProgramDialog dialog;

  ShowDialogMessage({required this.dialog});

  factory ShowDialogMessage.fromJson(Map<String, dynamic> json) => _$ShowDialogMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ShowDialogMessageToJson(this);
}
