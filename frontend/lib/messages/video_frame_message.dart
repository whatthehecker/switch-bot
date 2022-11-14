import 'package:json_annotation/json_annotation.dart';

part 'video_frame_message.g.dart';

@JsonSerializable()
class VideoFrameMessage {
  @JsonKey(name: 'image')
  final String base64Image;

  VideoFrameMessage({required this.base64Image});

  factory VideoFrameMessage.fromJson(Map<String, dynamic> json) =>
      _$VideoFrameMessageFromJson(json);

  Map<String, dynamic> toJson() => _$VideoFrameMessageToJson(this);
}
