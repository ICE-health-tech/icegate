import 'package:freezed_annotation/freezed_annotation.dart';
// EmailStatus enum now lives in database.dart (enums.dart was an orphaned duplicate).
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart' show EmailStatus;
import 'package:ice_gate/orchestration_layer/IDGen.dart';

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
      emailAddressID: emailAddressID ?? IDGen.UUIDV7(),
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
