import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';

part 'ProfileProtocol.freezed.dart';
part 'ProfileProtocol.g.dart';

@freezed
abstract class ProfileProtocol with _$ProfileProtocol {
  // ProfileProtocol._();

  factory ProfileProtocol({
    required String profileID,
    required String personID,
    String? bio,
    String? occupation,
    String? educationLevel,
    String? location,
    String? websiteUrl,
    String? linkedinUrl,
    String? githubUrl,
  }) = _ProfileProtocol;

  factory ProfileProtocol.create({
    String? profileID,
    required String personID,
    String? bio,
    String? occupation,
    String? educationLevel,
    String? location,
    String? websiteUrl,
    String? linkedinUrl,
    String? githubUrl,
  }) {
    return ProfileProtocol(
      profileID: profileID ?? IDGen.generateUuid(),
      personID: personID,
      bio: bio,
      occupation: occupation,
      educationLevel: educationLevel,
      location: location,
      websiteUrl: websiteUrl,
      linkedinUrl: linkedinUrl,
      githubUrl: githubUrl,
    );
  }

  factory ProfileProtocol.fromJson(Map<String, dynamic> json) =>
      _$ProfileProtocolFromJson(json);
}
