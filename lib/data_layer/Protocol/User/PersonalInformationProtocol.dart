import 'package:freezed_annotation/freezed_annotation.dart';
// Ensure this import path is correct for your project structure
// import 'package:ice_gate/data_layer/Protocol/User/PersonProtocols.dart';

part 'PersonalInformationProtocol.freezed.dart';
// part 'PersonalInformationProtocol.g.dart';

@freezed
abstract class PersonalInformationProtocol with _$PersonalInformationProtocol {
  // 1. PRIMARY CONSTRUCTOR
  // This defines the actual fields (schema) of your class.
  factory PersonalInformationProtocol({
    required String name,
    required String email,
    required String username,
    String? phoneNumber,
    String? address,
    String? gender,
    String? city,
    String? country,
    String? birthday,
    String? bio,
    String? occupation,
    String? profileImageUrl,
    required bool isActive,
    String? company,
    String? website,
    String? postalCode,
  }) = _PersonalInformationProtocol;
}
