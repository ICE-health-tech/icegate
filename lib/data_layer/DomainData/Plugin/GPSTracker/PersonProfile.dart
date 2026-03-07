/// Domain entities for user profile and related metrics
class PersonProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? coverUrl;
  final String? avatarLocalPath;
  final String? coverLocalPath;
  final HealthMetrics health;
  final FinanceMetrics finance;
  final SocialMetrics social;
  final ProjectMetrics projects;
  final PersonalInformation? personalInfo;

  const PersonProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.coverUrl,
    this.avatarLocalPath,
    this.coverLocalPath,
    required this.health,
    required this.finance,
    required this.social,
    required this.projects,
    this.personalInfo,
  });

  PersonProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? coverUrl,
    String? avatarLocalPath,
    String? coverLocalPath,
    HealthMetrics? health,
    FinanceMetrics? finance,
    SocialMetrics? social,
    ProjectMetrics? projects,
    PersonalInformation? personalInfo,
  }) {
    return PersonProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
      coverLocalPath: coverLocalPath ?? this.coverLocalPath,
      health: health ?? this.health,
      finance: finance ?? this.finance,
      social: social ?? this.social,
      projects: projects ?? this.projects,
      personalInfo: personalInfo ?? this.personalInfo,
    );
  }
}

/// Health metrics for tracking user's health data
class HealthMetrics {
  final int todaySteps;
  final int caloriesConsumed;
  final int caloriesBurned;
  final double sleepHours;
  final int heartRate;

  const HealthMetrics({
    required this.todaySteps,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.sleepHours,
    required this.heartRate,
  });

  int get netCalories => caloriesConsumed - caloriesBurned;

  HealthMetrics copyWith({
    int? todaySteps,
    int? caloriesConsumed,
    int? caloriesBurned,
    double? sleepHours,
    int? heartRate,
  }) {
    return HealthMetrics(
      todaySteps: todaySteps ?? this.todaySteps,
      caloriesConsumed: caloriesConsumed ?? this.caloriesConsumed,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      sleepHours: sleepHours ?? this.sleepHours,
      heartRate: heartRate ?? this.heartRate,
    );
  }
}

/// Finance metrics for tracking user's financial data
class FinanceMetrics {
  final double balance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double savingsRate;

  const FinanceMetrics({
    required this.balance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.savingsRate,
  });

  double get monthlySavings => monthlyIncome - monthlyExpenses;

  FinanceMetrics copyWith({
    double? balance,
    double? monthlyIncome,
    double? monthlyExpenses,
    double? savingsRate,
  }) {
    return FinanceMetrics(
      balance: balance ?? this.balance,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      savingsRate: savingsRate ?? this.savingsRate,
    );
  }
}

/// Social metrics for tracking user's social interactions
class SocialMetrics {
  final int friendsCount;
  final int unreadMessages;
  final int upcomingEvents;

  const SocialMetrics({
    required this.friendsCount,
    required this.unreadMessages,
    required this.upcomingEvents,
  });

  SocialMetrics copyWith({
    int? friendsCount,
    int? unreadMessages,
    int? upcomingEvents,
  }) {
    return SocialMetrics(
      friendsCount: friendsCount ?? this.friendsCount,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
    );
  }
}

/// Project metrics for tracking user's project progress
class ProjectMetrics {
  final int activeProjects;
  final int completedProjects;
  final int tasksToday;

  const ProjectMetrics({
    required this.activeProjects,
    required this.completedProjects,
    required this.tasksToday,
  });

  int get totalProjects => activeProjects + completedProjects;

  ProjectMetrics copyWith({
    int? activeProjects,
    int? completedProjects,
    int? tasksToday,
  }) {
    return ProjectMetrics(
      activeProjects: activeProjects ?? this.activeProjects,
      completedProjects: completedProjects ?? this.completedProjects,
      tasksToday: tasksToday ?? this.tasksToday,
    );
  }
}

/// Detailed personal information for the user
class PersonalInformation {
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  final DateTime? birthday;
  final String? bio;
  final String? occupation;
  final String? company;
  final String? website;
  final String? coverUrl;
  final String? avatarLocalPath;
  final String? coverLocalPath;

  const PersonalInformation({
    this.phoneNumber,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    this.birthday,
    this.bio,
    this.occupation,
    this.company,
    this.website,
    this.coverUrl,
    this.avatarLocalPath,
    this.coverLocalPath,
  });

  PersonalInformation copyWith({
    String? phoneNumber,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    DateTime? birthday,
    String? bio,
    String? occupation,
    String? company,
    String? website,
    String? coverUrl,
  }) {
    return PersonalInformation(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      birthday: birthday ?? this.birthday,
      bio: bio ?? this.bio,
      occupation: occupation ?? this.occupation,
      company: company ?? this.company,
      website: website ?? this.website,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }

  int? get age {
    if (birthday == null) return null;
    final now = DateTime.now();
    int age = now.year - birthday!.year;
    if (now.month < birthday!.month ||
        (now.month == birthday!.month && now.day < birthday!.day)) {
      age--;
    }
    return age;
  }
}
