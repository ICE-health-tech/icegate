import 'package:drift/drift.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/data_layer/Protocol/User/CVAddressProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/User/EmailAddressProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/User/PersonProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/User/UserAccountProtocol.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';

class DataSeeder {
  static Future<void> seed(AppDatabase db) async {
    // Check if any person exists (autoincrement usually starts at 1, but we use 0 in seeder)
    final person = await db.personManagementDAO.getPersonById(1);
    if (person != null) return; // Already seeded

    print("Seeding database...");

    // 1. Create Person using PersonProtocol (ID auto-generated)
    final personProtocol = PersonProtocol(
      personID: 1,
      firstName: 'Long',
      lastName: 'Duy',
      dateOfBirth: DateTime(1, 1, 1),
      gender: 'Unknown',
      phoneNumber: '0123456789',
      profileImageUrl: 'https://example.com/profile.jpg',
    );
    final personId = await db.personManagementDAO.createPerson(personProtocol);
    print("DUYLONG>>>>>>$personId");
    // 2. Create Email using EmailAddressProtocol (ID auto-generated)
    final emailProtocol = EmailAddressProtocol(
      emailAddressID: 1,
      personID: personId,
      emailAddress: 'longduy@example.com',
      isPrimary: true,
      status: EmailStatus.verified,
    );
    print("DUYLONG>>>>>>$emailProtocol");
    await db.personManagementDAO.addEmail(emailProtocol);

    // 3. Create Account using UserAccountProtocol (ID auto-generated)
    final accountProtocol = UserAccountProtocol(
      personID: personId,
      username: 'Guest',
      role: 'admin',
      accountID: personId,
    );
    await db.personManagementDAO.createAccount(
      accountProtocol,
      passwordHash: 'hashed_password', // Mock hash
    );

    // 4. Create Profile using ProfileProtocol (ID auto-generated)
    final profileProtocol = CVAddressProtocol(
      cvAddressID: 1,
      personID: personId,
      bio: 'Flutter Developer & Tech Enthusiast',
      occupation: 'Software Engineer',
      educationLevel: 'Bachelor',
      location: 'Ha Noi, Vietnam',
      websiteUrl: 'https://example.com',
    );
    await db.personManagementDAO.createCVAddress(profileProtocol);

    // 5. Create Financial Accounts
    await db.financeDAO.createAccount(
      FinancialAccountsTableCompanion(
        id: Value(IDGen.generateUuid()),
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
        id: Value(IDGen.generateUuid()),
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
        id: Value(IDGen.generateUuid()),
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
        id: Value(IDGen.generateUuid()),
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
        id: Value(IDGen.generateUuid()),
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
        id: Value(IDGen.generateUuid()),
        personID: Value(personId),
        skillName: const Value('Flutter'),
        proficiencyLevel: const Value(SkillLevel.expert),
        yearsOfExperience: const Value(0),
        isFeatured: const Value(true),
      ),
    );

    // 10. Create Blog Posts
    await db.contentDAO.createPost(
      BlogPostsTableCompanion(
        id: Value(IDGen.generateUuid()),
        authorID: Value(personId),
        title: const Value('Hello World'),
        slug: const Value('hello-world'),
        content: const Value('This is my first post on the new platform.'),
        status: const Value(PostStatus.published),
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
    //       id: Value(IDGen.generateUuid()),
    //       personID: Value(personId),
    //       steps: Value(5000 + (i * 100)), // 5000 to 5600 steps per day
    //       date: Value(normalizedDate),
    //       updatedAt: Value(DateTime.now()),
    //     ),
    //   );
    // }

    print("Database seeded successfully.");
  }
}
