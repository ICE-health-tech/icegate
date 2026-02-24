import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';

part 'EmailAddressProtocol.freezed.dart';
part 'EmailAddressProtocol.g.dart';

@freezed
abstract class EmailAddressProtocol with _$EmailAddressProtocol {
  const factory EmailAddressProtocol({
    required String emailAddressID,
    required String personID,
    required String emailAddress,
    @Default('personal') String emailType,
    @Default(true) bool isPrimary,
    @Default(EmailStatus.pending) EmailStatus status,
    DateTime? verifiedAt,
  }) = _EmailAddressProtocol;

  factory EmailAddressProtocol.create({
    String? emailAddressID,
    required String personID,
    required String emailAddress,
    String emailType = 'personal',
    bool isPrimary = false,
    EmailStatus status = EmailStatus.pending,
    DateTime? verifiedAt,
  }) {
    return EmailAddressProtocol(
      emailAddressID: emailAddressID ?? IDGen.generateUuid(),
      personID: personID,
      emailAddress: emailAddress,
      emailType: emailType,
      isPrimary: isPrimary,
      status: status,
      verifiedAt: verifiedAt,
    );
  }

  factory EmailAddressProtocol.fromJson(Map<String, dynamic> json) =>
      _$EmailAddressProtocolFromJson(json);
}
