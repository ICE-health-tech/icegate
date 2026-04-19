part of '../Database.dart';

@DriftAccessor(tables: [OrganizationsTable])
class OrganizationDAO extends DatabaseAccessor<AppDatabase>
    with _$OrganizationDAOMixin {
  OrganizationDAO(super.db);

  Future<int> insertOrganization(OrganizationsTableCompanion entry) =>
      into(organizationsTable).insert(entry);

  Future<bool> updateOrganization(OrganizationData entry) =>
      update(organizationsTable).replace(entry);

  Stream<List<OrganizationData>> watchAllOrganizations() =>
      select(organizationsTable).watch();
}

@DriftAccessor(tables: [PersonsTable])
class PersonDAO extends DatabaseAccessor<AppDatabase> with _$PersonDAOMixin {
  PersonDAO(super.db);

  Future<int> insertPerson(PersonsTableCompanion entry) =>
      into(personsTable).insert(entry);

  Future<bool> updatePerson(PersonData entry) =>
      update(personsTable).replace(entry);

  Future<int> deletePerson(String id) =>
      (delete(personsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<PersonData>> watchAllPersons() => select(personsTable).watch();

  Future<PersonData?> getPersonById(String id) =>
      (select(personsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(personsTable).insert(
      PersonsTableCompanion(
        id: Value(record['id'] as String),
        tenantID: Value(record['tenant_id'] as String?),
        firstName: Value(record['first_name'] as String),
        lastName: Value(record['last_name'] as String?),
        dateOfBirth: Value(record['date_of_birth'] != null
            ? DateTime.parse(record['date_of_birth'].toString())
            : null),
        gender: Value(record['gender'] as String?),
        phoneNumber: Value(record['phone_number'] as String?),
        profileImageUrl: Value(record['profile_image_url'] as String?),
        coverImageUrl: Value(record['cover_image_url'] as String?),
        avatarLocalPath: Value(record['avatar_local_path'] as String?),
        coverLocalPath: Value(record['cover_local_path'] as String?),
        relationship: Value(record['relationship'] as String? ?? 'none'),
        affection: Value(record['affection'] as int? ?? 0),
        isActive: Value(record['is_active'] as bool? ?? true),
        createdAt: Value(record['created_at'] != null
            ? DateTime.parse(record['created_at'].toString())
            : DateTime.now()),
        updatedAt: Value(record['updated_at'] != null
            ? DateTime.parse(record['updated_at'].toString())
            : DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}

@DriftAccessor(tables: [PersonContactsTable])
class PersonContactDAO extends DatabaseAccessor<AppDatabase>
    with _$PersonContactDAOMixin {
  PersonContactDAO(super.db);

  Future<int> insertContact(PersonContactsTableCompanion entry) =>
      into(personContactsTable).insert(entry);

  Future<bool> updateContact(PersonContactData entry) =>
      update(personContactsTable).replace(entry);

  Future<int> deleteContact(String id) =>
      (delete(personContactsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<PersonContactData>> watchAllContacts() =>
      select(personContactsTable).watch();

  Future<List<PersonContactData>> getAllContacts() =>
      select(personContactsTable).get();
}
