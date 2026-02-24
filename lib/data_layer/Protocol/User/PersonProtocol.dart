import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';

part 'PersonProtocol.freezed.dart';
part 'PersonProtocol.g.dart';

@freezed
abstract class PersonProtocol with _$PersonProtocol {
  // PersonProtocol.();

  const factory PersonProtocol({
    required String personID,
    required String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? profileImageUrl,
    @Default(true) bool isActive,
  }) = _PersonProtocol;

  factory PersonProtocol.create({
    String? personID,
    required String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? profileImageUrl,
    bool isActive = true,
  }) {
    return PersonProtocol(
      personID: personID ?? IDGen.generateUuid(),
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
      isActive: isActive,
    );
  }

  factory PersonProtocol.fromJson(Map<String, dynamic> json) =>
      _$PersonProtocolFromJson(json);

  // String get fullName => '$firstName ${lastName ?? ''}'.trim();
}
