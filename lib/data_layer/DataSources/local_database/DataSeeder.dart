import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/CVAddressProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/EmailAddressProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/PersonProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/UserAccountProtocol.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

class DataSeeder {
  static const String guestPersonId = '00000000-0000-4000-8000-000000000001';
  static const String guestTenantId = '00000000-0000-0000-0000-000000000001';

  static Future<void> seed(AppDatabase db) async {
    // Check if any person exists
    final person = await db.personManagementDAO.getPersonById(guestPersonId);
    if (person != null) return; // Already seeded

    // 1. Create Person using PersonProtocol (generic guest — no real PII)
    final personProtocol = PersonProtocol(
      id: guestPersonId,
      firstName: 'Guest',
      lastName: null,
      dateOfBirth: null,
      gender: null,
      phoneNumber: null,
      profileImageUrl: null,
    );
    final personId = await db.personManagementDAO.createPerson(
      personProtocol,
      id: guestPersonId,
      tenantId: guestTenantId,
    );


    // 2. Create Email using EmailAddressProtocol
    final emailProtocol = EmailAddressProtocol.create(
      personID: personId,
      emailAddress: 'guest@example.invalid',
      isPrimary: true,
      status: EmailStatus.pending,
    );
    await db.personManagementDAO.addEmail(emailProtocol);

    // 3. Create Account using UserAccountProtocol
    final accountProtocol = UserAccountProtocol.create(
      personID: personId,
      username: 'Guest',
      role: 'user',
    );
    await db.personManagementDAO.createAccount(
      accountProtocol,
      passwordHash: r'$MOCK$SEED$PASSWORD$HASH$NOT$USABLE',
    );

    // 4. Create CV Address using CVAddressProtocol
    final cvAddressProtocol = CVAddressProtocol.create(
      personID: personId,
      bio: '',
      occupation: '',
      educationLevel: '',
      location: '',
      websiteUrl: null,
    );
    await db.personManagementDAO.createCVAddress(cvAddressProtocol);

    // 5. Create Financial Accounts
    await db.financeDAO.createAccount(
      FinancialAccountsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        accountName: const Value('Primary'),
        accountType: const Value('checking'),
        balance: const Value(0.00),
        currency: const Value(CurrencyType.USD),
        isPrimary: const Value(true),
      ),
    );
    await db.financeDAO.createAccount(
      FinancialAccountsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        accountName: const Value('Savings'),
        accountType: const Value('savings'),
        balance: const Value(0.00),
        currency: const Value(CurrencyType.USD),
      ),
    );

    // 6. Create Assets
    await db.financeDAO.createAsset(
      AssetsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        assetName: const Value('Unknown'),
        assetCategory: const Value('electronics'),
        currentEstimatedValue: const Value(0.00),
        currency: const Value(CurrencyType.USD),
      ),
    );

    // 7. Create Goals
    final goalId = await db.growthDAO.createGoal(
      GoalsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        title: const Value('Sample goal'),
        category: const Value('general'),
        status: const Value('active'),
        progressPercentage: const Value(0),
      ),
    );

    // 8. Create Habits
    await db.growthDAO.createHabit(
      HabitsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        goalID: Value(goalId),
        habitName: const Value('Sample habit'),
        frequency: const Value('daily'),
        targetCount: const Value(1),
      ),
    );

    // 9. Create Skills
    await db.growthDAO.createSkill(
      SkillsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        skillName: const Value('Sample skill'),
        proficiencyLevel: const Value(SkillLevel.beginner),
        yearsOfExperience: const Value(0),
        isFeatured: const Value(true),
      ),
    );

    // 10. Create AI Analysis
    await db.aiAnalysisDAO.createAnalysis(
      AiAnalysisTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        title: const Value('Sample analysis'),
        detailedAnalysis: const Value('Placeholder content for local seed data.'),
        status: const Value('published'),
        category: const Value('Overall'),
        aiModel: const Value('system'),
        publishedAt: Value(DateTime.now()),
      ),
    );

    // 11. Create Mock Health Metrics for points
    // final now = DateTime.now();
    // for (int i = 0; i < 7; i++) {
    //   final date = now.subtract(Duration(days: i));
    //   final normalizedDate = DateTime(date.year, date.month, date.day);
    //   await db.healthMetricsDAO.insertOrUpdateMetrics(
    //     HealthMetricsTableCompanion(
    //       id: Value(IDGen.UUIDV7()),
    //       personID: Value(personId),
    //       steps: Value(5000 + (i * 100)), // 5000 to 5600 steps per day
    //       date: Value(normalizedDate),
    //       updatedAt: Value(DateTime.now()),
    //     ),
    //   );
    // }

    // // 12. Seed Quests
    // await db.questDAO.insertQuest(
    //   QuestsTableCompanion(
    //     id: Value(IDGen.UUIDV7()),
    //     title: const Value('Sample quest A'),
    //     personID: Value(personId),
    //     description: const Value('Mock quest description.'),
    //     targetValue: const Value(1.0),
    //     currentValue: const Value(0.0),
    //     category: const Value('health'),
    //     type: const Value('system'),
    //   ),
    // );
    // await db.questDAO.insertQuest(
    //   QuestsTableCompanion(
    //     id: Value(IDGen.UUIDV7()),
    //     title: const Value('Sample quest B'),
    //     personID: Value(personId),
    //     description: const Value('Mock quest description.'),
    //     targetValue: const Value(1.0),
    //     currentValue: const Value(0.0),
    //     category: const Value('productivity'),
    //     type: const Value('system'),
    //   ),
    // );

    // 13. Seed External Widgets
    await db.externalWidgetsDAO.insertNewWidget(
      externalWidgetProtocol: const ExternalWidgetProtocol(
        name: 'Sample widget A',
        protocol: 'https',
        host: 'example.com',
        url: '/placeholder/a',
        imageUrl: 'https://example.com/placeholder.png',
      ),
      personID: personId,
    );
    await db.externalWidgetsDAO.insertNewWidget(
      externalWidgetProtocol: const ExternalWidgetProtocol(
        name: 'Sample widget B',
        protocol: 'https',
        host: 'example.com',
        url: '/placeholder/b',
        imageUrl: 'https://example.com/placeholder.png',
      ),
      personID: personId,
    );

    // // 14. Seed Reminders
    // await db.customNotificationDAO.insertNotification(
    //   CustomNotificationsTableCompanion.insert(
    //     id: IDGen.UUIDV7(),
    //     title: 'Sample reminder',
    //     content: 'Placeholder notification body.',
    //     scheduledTime: DateTime.now().add(const Duration(hours: 2)),
    //     category: const Value('Health'),
    //   ),
    // );

    // 15. Seed Project Notes
    await db.projectNoteDAO.insertNote(
      title: 'Sample note',
      content: jsonEncode([
        {'insert': 'Placeholder note content.\n'},
      ]),
      personID: personId,
      category: 'general',
    );
  }
}
