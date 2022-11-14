import 'package:json_annotation/json_annotation.dart';

part 'dialog_closed_message.g.dart';

@JsonSerializable()
class DialogClosedMessage {
  final String? button;

  DialogClosedMessage({this.button});

  factory DialogClosedMessage.fromJson(Map<String, dynamic> json) =>
      _$DialogClosedMessageFromJson(json);

  Map<String, dynamic> toJson() => _$DialogClosedMessageToJson(this);
}
