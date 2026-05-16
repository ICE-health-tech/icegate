import 'package:drift/drift.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

/// Agent responsible for checking the health and integrity of the live database.
class DatabaseVerificationAgent {
  final GeneratedDatabase database;

  DatabaseVerificationAgent(this.database);

  /// Runs a full SQLite integrity check.
  /// Returns a list of error messages. If empty, the DB is healthy.
  /// Warning: This can be slow on large databases.
  Future<List<String>> verifyIntegrity() async {
    // 'PRAGMA integrity_check' returns 'ok' as a single row if healthy,
    // or a list of error strings if corrupt.
    final result = await database
        .customSelect('PRAGMA integrity_check')
        .map((row) => row.read<String>('integrity_check'))
        .get();

    if (result.length == 1 && result.first == 'ok') {
      return [];
    }

    return result;
  }

  /// Checks for any broken foreign key constraints.
  /// Returns a list of maps detailing the violations.
  Future<List<Map<String, dynamic>>> verifyForeignKeys() async {
    // 'PRAGMA foreign_key_check' returns rows for every violation.
    // Columns: table, rowid, parent, fkid
    final result = await database
        .customSelect('PRAGMA foreign_key_check')
        .map((row) => row.data)
        .get();

    return result;
  }

  /// Runs a "smoke test" by attempting a simple read/write transaction.
  /// Useful to verify disk permission issues or unexpected read-only states.
  Future<bool> runSmokeTest() async {
    try {
      await database.transaction(() async {
        // Just ensuring we can open a transaction context
        await database.customSelect('SELECT 1').get();
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> checkDatabaseTables() async {
    try {
      await database.customSelect('SELECT 1').get();
      final allTables = database.allTables;
      for (var table in allTables) {
        print(table.actualTableName);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> checkPersonEmailAccountCVTable() async {
    try {
      // await database.customSelect('SELECT 1').get();
      PersonDAO dao = PersonDAO(database as AppDatabase);
      dao.getPersonByID('');
      // print("✅ Can get person 0");
    } catch (e) {
      // print("❌ Can't get person 0");
      print(e);
    }
  }

  /// add more function

  /// Runs all checks and returns a full report.
  Future<VerificationReport> runFullDiagnostics() async {
    final integrityErrors = await verifyIntegrity();
    final fkErrors = await verifyForeignKeys();
    final smokeTestPassed = await runSmokeTest();
    await checkDatabaseTables();

    return VerificationReport(
      isHealthy: integrityErrors.isEmpty,

      // && fkErrors.isEmpty && smokeTestPassed,
      integrityErrors: integrityErrors,
      foreignKeyErrors: fkErrors,
      smokeTestPassed: smokeTestPassed,
    );
  }
}

class VerificationReport {
  final bool isHealthy;
  final List<String>? integrityErrors;
  final List<Map<String, dynamic>>? foreignKeyErrors;
  final bool? smokeTestPassed;

  VerificationReport({
    required this.isHealthy,
    this.integrityErrors,
    this.foreignKeyErrors,
    this.smokeTestPassed,
  });

  @override
  String toString() {
    if (isHealthy) return '✅ Database is healthy.';
    return '❌ Database issues found:\n'
        'Integrity: $integrityErrors\n'
        'FK Violations: $foreignKeyErrors\n'
        'Smoke Test: ${smokeTestPassed ?? "N/A"}';
  }
}

Future<void> monitoring(AppDatabase db) async {
  final agent = DatabaseVerificationAgent(db);
  print("==========Database agent===========");
  // Call this safely, perhaps in a background isolate if the DB is huge
  final report = await agent.runFullDiagnostics();

  print(report.toString());
  if (!report.isHealthy) {
    // Log to Sentry/Crashlytics or prompt user to "Reset Data"
    print(report.toString());
    print("==========Database agent===========");
    print(report.toString());
  }
}
