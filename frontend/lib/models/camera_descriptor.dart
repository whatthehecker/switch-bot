import 'package:json_annotation/json_annotation.dart';

part 'camera_descriptor.g.dart';

@JsonSerializable()
class CameraDescriptor {
  String name;
  Object identifier;

  CameraDescriptor({
    required this.name,
    required this.identifier,
  });

  factory CameraDescriptor.fromJson(Map<String, dynamic> json) =>
      _$CameraDescriptorFromJson(json);

  Map<String, dynamic> toJson() => _$CameraDescriptorToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameraDescriptor &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;
}
