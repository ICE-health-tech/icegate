import 'package:drift/drift.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/CVAddressProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/EmailAddressProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/PersonProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/UserAccountProtocol.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

class DataSeeder {
  static const String guestPersonId = '00000000-0000-0000-0000-000000000001';

  static Future<void> seed(AppDatabase db) async {
    // Check if any person exists
    final person = await db.personManagementDAO.getPersonById(guestPersonId);
    if (person != null) return; // Already seeded

    print("Seeding database...");

    // 1. Create Person using PersonProtocol
    final personProtocol = PersonProtocol(
      id: guestPersonId,
      firstName: 'Long',
      lastName: 'Duy',
      dateOfBirth: DateTime(1, 1, 1),
      gender: 'Unknown',
      phoneNumber: '0123456789',
      profileImageUrl: 'https://example.com/profile.jpg',
    );
    final personId = await db.personManagementDAO.createPerson(
      personProtocol,
      id: guestPersonId,
    );
    print("DUYLONG>>>>>>$personId");

    // 2. Create Email using EmailAddressProtocol
    final emailProtocol = EmailAddressProtocol.create(
      personID: personId,
      emailAddress: 'longduy@example.com',
      isPrimary: true,
      status: EmailStatus.verified,
    );
    print("DUYLONG>>>>>>$emailProtocol");
    await db.personManagementDAO.addEmail(emailProtocol);

    // 3. Create Account using UserAccountProtocol
    final accountProtocol = UserAccountProtocol.create(
      personID: personId,
      username: 'Guest',
      role: 'admin',
    );
    await db.personManagementDAO.createAccount(
      accountProtocol,
      passwordHash: 'hashed_password', // Mock hash
    );

    // 4. Create CV Address using CVAddressProtocol
    final cvAddressProtocol = CVAddressProtocol.create(
      personID: personId,
      bio: 'Flutter Developer & Tech Enthusiast',
      occupation: 'Software Engineer',
      educationLevel: 'Bachelor',
      location: 'Ha Noi, Vietnam',
      websiteUrl: 'https://example.com',
    );
    await db.personManagementDAO.createCVAddress(cvAddressProtocol);

    // 5. Create Financial Accounts
    await db.financeDAO.createAccount(
      FinancialAccountsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        accountName: const Value('Main Checking'),
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
        title: const Value('Learn Rust'),
        category: const Value('education'),
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
        habitName: const Value('Code Rust daily'),
        frequency: const Value('daily'),
        targetCount: const Value(1),
      ),
    );

    // 9. Create Skills
    await db.growthDAO.createSkill(
      SkillsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        skillName: const Value('Flutter'),
        proficiencyLevel: const Value(SkillLevel.expert),
        yearsOfExperience: const Value(0),
        isFeatured: const Value(true),
      ),
    );

    // 10. Create AI Analysis
    await db.aiAnalysisDAO.createAnalysis(
      AiAnalysisTableCompanion(
        id: Value(IDGen.UUIDV7()),
        personID: Value(personId),
        title: const Value('Welcome Analysis'),
        detailedAnalysis: const Value(
          'Initial system analysis of your profile and goals.',
        ),
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

    // 12. Seed Quests
    await db.questDAO.insertQuest(
      QuestsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        title: const Value('Stamina Boost'),
        personID: Value(personId),
        description: const Value('Walk 10,000 steps today.'),
        targetValue: const Value(10000.0),
        currentValue: const Value(4320.0),
        category: const Value('health'),
      ),
    );
    await db.questDAO.insertQuest(
      QuestsTableCompanion(
        id: Value(IDGen.UUIDV7()),
        title: const Value('Iron Will'),
        personID: Value(personId),
        description: const Value('Complete 3 heavy focus sessions.'),
        targetValue: const Value(3.0),
        currentValue: const Value(1.0),
        category: const Value('productivity'),
      ),
    );

    // 13. Seed External Widgets
    await db.externalWidgetsDAO.insertNewWidget(
      externalWidgetProtocol: const ExternalWidgetProtocol(
        name: 'System Monitor',
        protocol: 'https',
        host: 'example.com',
        url: '/widgets/monitor',
        imageUrl: 'https://img.icons8.com/isometric/512/processor.png',
      ),
      personID: personId,
    );
    await db.externalWidgetsDAO.insertNewWidget(
      externalWidgetProtocol: const ExternalWidgetProtocol(
        name: 'Weather Core',
        protocol: 'https',
        host: 'example.com',
        url: '/widgets/weather',
        imageUrl: 'https://img.icons8.com/isometric/512/cloud.png',
      ),
      personID: personId,
    );

    // 14. Seed Reminders
    await db.customNotificationDAO.insertNotification(
      CustomNotificationsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        title: 'Hydration Protocol',
        content: 'Drink 500ml of water to maintain peak performance.',
        scheduledTime: DateTime.now().add(const Duration(hours: 2)),
        category: const Value('Health'),
      ),
    );

    print("Database seeded successfully.");
  }
}
