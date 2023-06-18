import 'package:json_annotation/json_annotation.dart';

part 'sample_dto.g.dart';

@JsonSerializable()
class SampleDto {
  final String name;
  final int age;

  SampleDto({
    required this.name,
    required this.age,
  });

  factory SampleDto.fromJson(Map<String, dynamic> json) =>
      _$SampleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SampleDtoToJson(this);
}
