import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';

part 'CVAddressProtocol.freezed.dart';
part 'CVAddressProtocol.g.dart';

@freezed
abstract class CVAddressProtocol with _$CVAddressProtocol {
  const factory CVAddressProtocol({
    required String cvAddressID,
    required String personID,
    String? githubUrl,
    String? websiteUrl,
    String? company,
    String? university,
    String? location,
    String? country,
    String? bio,
    String? occupation,
    String? educationLevel,
    String? linkedinUrl,
  }) = _CVAddressProtocol;

  factory CVAddressProtocol.create({
    String? cvAddressID,
    required String personID,
    String? githubUrl,
    String? websiteUrl,
    String? company,
    String? university,
    String? location,
    String? bio,
    String? occupation,
    String? country,
    String? educationLevel,
    String? linkedinUrl,
  }) {
    return CVAddressProtocol(
      cvAddressID: cvAddressID ?? IDGen.UUIDV7(),
      personID: personID,
      githubUrl: githubUrl,
      websiteUrl: websiteUrl,
      company: company,
      university: university,
      location: location,
      bio: bio,
      occupation: occupation,
      educationLevel: educationLevel,
      linkedinUrl: linkedinUrl,
    );
  }

  factory CVAddressProtocol.fromJson(Map<String, dynamic> json) =>
      _$CVAddressProtocolFromJson(json);
}
