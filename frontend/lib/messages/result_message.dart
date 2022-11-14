import 'package:json_annotation/json_annotation.dart';

part 'result_message.g.dart';

/// A generic message for any actions that can result in success or failure.
/// Results that represent a failure usually have an additional error message
/// set.
@JsonSerializable()
class ResultMessage {
  final bool success;
  @JsonKey(name: 'error_message')
  final String? errorMessage;

  ResultMessage({
    required this.success,
    this.errorMessage,
  });

  factory ResultMessage.fromJson(Map<String, dynamic> json) =>
      _$ResultMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ResultMessageToJson(this);
}
