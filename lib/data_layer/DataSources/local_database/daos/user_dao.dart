part of '../Database.dart';

@DriftAccessor(tables: [UserAccountsTable])
class UserAccountDAO extends DatabaseAccessor<AppDatabase>
    with _$UserAccountDAOMixin {
  UserAccountDAO(super.db);

  Future<int> insertAccount(UserAccountsTableCompanion entry) =>
      into(userAccountsTable).insert(entry);

  Future<bool> updateAccount(UserAccountData entry) =>
      update(userAccountsTable).replace(entry);

  Future<UserAccountData?> getAccountByPersonId(String personId) =>
      (select(userAccountsTable)..where((t) => t.personID.equals(personId)))
          .getSingleOrNull();

  Future<UserAccountData?> getAccountByUsername(String username) =>
      (select(userAccountsTable)..where((t) => t.username.equals(username)))
          .getSingleOrNull();
}

@DriftAccessor(tables: [ProfilesTable])
class ProfileDAO extends DatabaseAccessor<AppDatabase> with _$ProfileDAOMixin {
  ProfileDAO(super.db);

  Future<int> insertProfile(ProfilesTableCompanion entry) =>
      into(profilesTable).insert(entry);

  Future<bool> updateProfile(ProfileData entry) =>
      update(profilesTable).replace(entry);

  Future<ProfileData?> getProfileByPersonId(String personId) =>
      (select(profilesTable)..where((t) => t.personID.equals(personId)))
          .getSingleOrNull();

  Stream<ProfileData?> watchProfileByPersonId(String personId) =>
      (select(profilesTable)..where((t) => t.personID.equals(personId)))
          .watchSingleOrNull();
}

@DriftAccessor(tables: [CVAddressesTable])
class CVAddressDAO extends DatabaseAccessor<AppDatabase>
    with _$CVAddressDAOMixin {
  CVAddressDAO(super.db);

  Future<int> insertAddress(CVAddressesTableCompanion entry) =>
      into(cVAddressesTable).insert(entry);

  Future<bool> updateAddress(CVAddressData entry) =>
      update(cVAddressesTable).replace(entry);

  Future<CVAddressData?> getAddressByPersonId(String personId) =>
      (select(cVAddressesTable)..where((t) => t.personID.equals(personId)))
          .getSingleOrNull();

  Stream<CVAddressData?> watchAddressByPersonId(String personId) =>
      (select(cVAddressesTable)..where((t) => t.personID.equals(personId)))
          .watchSingleOrNull();
}
