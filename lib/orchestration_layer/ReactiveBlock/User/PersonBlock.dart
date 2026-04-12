import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ice_gate/initial_layer/CoreLogics/CustomAuthService.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:signals/signals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Interfaces for State ---
class UserDetails {
  final String? informationId;
  final String? identityId;
  final String githubUrl;
  final String websiteUrl;
  final String company;
  final String university;
  final String location;
  final String country;
  final String bio;
  final String occupation;
  final String educationLevel;
  final String email;
  final String linkedinUrl;

  const UserDetails({
    this.informationId,
    this.identityId,
    this.githubUrl = '',
    this.websiteUrl = '',
    this.company = '',
    this.university = '',
    this.location = '',
    this.country = '',
    this.bio = '',
    this.occupation = '',
    this.educationLevel = '',
    this.email = '',
    this.linkedinUrl = '',
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      informationId:
          json['information_id'] as String?, // Assuming exact key match
      identityId: json['identity_id'] as String?, // Check backend structure
      githubUrl: json['github_url'] ?? '',
      websiteUrl: json['website_url'] ?? '',
      company: json['company'] ?? '',
      university: json['university'] ?? '',
      location: json['location'] ?? '',
      country: json['country'] ?? '',
      bio: json['bio'] ?? '',
      occupation: json['occupation'] ?? '',
      educationLevel: json['education_level'] ?? '',
      email: json['email'] ?? '',
      linkedinUrl: json['linkedin_url'] ?? '',
    );
  }

  // Helper for updates
  UserDetails copyWith({
    String? githubUrl,
    String? websiteUrl,
    String? company,
    String? university,
    String? location,
    String? country,
    String? bio,
    String? occupation,
    String? educationLevel,
    String? email,
    String? linkedinUrl,
  }) {
    return UserDetails(
      informationId: informationId,
      identityId: identityId,
      githubUrl: githubUrl ?? this.githubUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      company: company ?? this.company,
      university: university ?? this.university,
      location: location ?? this.location,
      country: country ?? this.country,
      bio: bio ?? this.bio,
      occupation: occupation ?? this.occupation,
      educationLevel: educationLevel ?? this.educationLevel,
      email: email ?? this.email,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
    );
  }
}

class UserProfile {
  final String? id;
  final String firstName;
  final String lastName;
  final int friends;
  final int mutual;
  final String profileImageUrl;
  final String coverImageUrl;
  final String avatarLocalPath;
  final String coverLocalPath;
  final String username;
  final String? tenantId;

  const UserProfile({
    this.id,
    this.firstName = '',
    this.lastName = '',
    this.friends = 0,
    this.mutual = 0,
    this.profileImageUrl = '',
    this.coverImageUrl = '',
    this.avatarLocalPath = '',
    this.coverLocalPath = '',
    this.username = '',
    this.tenantId,
  });

  // UserProfile copyWith({
  //   String? id,
  //   String? firstName,
  //   String? profileImageUrl,
  // }) {
  //   return UserProfile(
  //     id: id ?? this.id,
  //     firstName: firstName ?? this.firstName,
  //     profileImageUrl: profileImageUrl ?? this.profileImageUrl,
  //   );
  // }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      friends: json['friends'] ?? 0,
      mutual: json['mutual'] ?? 0,
      profileImageUrl:
          json['profileImageUrl'] ?? json['profile_image_url'] ?? '',
      coverImageUrl: json['coverImageUrl'] ?? json['cover_image_url'] ?? '',
      avatarLocalPath:
          json['avatarLocalPath'] ?? json['avatar_local_path'] ?? '',
      coverLocalPath: json['coverLocalPath'] ?? json['cover_local_path'] ?? '',
      username: json['username'] ?? '',
      tenantId: json['tenantId'] ?? json['tenant_id'] ?? '',
    );
  }

  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    int? friends,
    int? mutual,
    String? profileImageUrl,
    String? coverImageUrl,
    String? avatarLocalPath,
    String? coverLocalPath,
    String? username,
    String? tenantId,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      friends: friends ?? this.friends,
      mutual: mutual ?? this.mutual,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      avatarLocalPath: avatarLocalPath ?? this.avatarLocalPath,
      coverLocalPath: coverLocalPath ?? this.coverLocalPath,
      username: username ?? this.username,
      tenantId: tenantId ?? this.tenantId,
    );
  }
}

class UserInformation {
  final UserDetails details;
  final UserProfile profiles;

  const UserInformation({required this.details, required this.profiles});
  UserInformation copyWith({UserDetails? details, UserProfile? profiles}) {
    return UserInformation(
      details: details ?? this.details,
      profiles: profiles ?? this.profiles,
    );
  }
}

class UserAccount {
  final String role; // 'ADMIN', 'USER', etc.
  const UserAccount({this.role = 'USER'});
}

class SkillType {
  final String id;
  final String category;
  final String name;
  final String description;

  const SkillType({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
  });

  factory SkillType.fromJson(Map<String, dynamic> json) {
    return SkillType(
      id: json['id'] as String? ?? '',
      category: json['category'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

// --- Person Block ---
class PersonBlock {
  // State Signals
  var information = signal<UserInformation>(
    UserInformation(
      details: const UserDetails(),
      profiles: const UserProfile(
        firstName: 'Initial',
        profileImageUrl:
            'https://ui-avatars.com/api/?name=Initial&background=6366F1&color=fff',
      ),
    ),
  );

  final account = signal<UserAccount>(const UserAccount());
  final skills = signal<List<SkillType>>([]);

  // Signal for the profile currently being viewed (if different from logged in user)
  final viewedInformation = signal<UserInformation?>(null);

  // Sync Status signal for Dynamic Island
  final isSyncing = signal<bool>(false);

  // Computed currentPersonID avoids stale state during login transitions
  late final currentPersonID = computed(() => information.value.profiles.id);

  final PersonManagementDAO personDao;

  PersonBlock({
    required CustomAuthService authService,
    required this.personDao,
  });

  // --- ACTIONS ---

  /// Sync with the Java Backend for latest profile data
  Future<void> appSync(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || token == "mock_guest_jwt_token") return;

    isSyncing.value = true;
    try {
      const baseUrl = 'https://backend.duylong.art';
      final url = Uri.parse('$baseUrl/api/v1/users/me');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {  
        final data = json.decode(response.body);
        debugPrint('✅ [PersonBlock] app_sync success: $data');

        // Update local database with latest remote paths from backend
        if (data['profileImageUrl'] != null) {
          unawaited(
            personDao.updateAvatarImageUrl(user.id, data['profileImageUrl']),
          );
        }
        if (data['coverImageUrl'] != null) {
          unawaited(
            personDao.updateCoverImageUrl(user.id, data['coverImageUrl']),
          );
        }
      } else {
        debugPrint('⚠️ [PersonBlock] app_sync status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ [PersonBlock] app_sync failed: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  /// Fetch user profile and details together (Local-first with Supabase/Backend sync)
  Future<void> fetchFromDatabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || token == "mock_guest_jwt_token") {
      _applyGuestFallback();
      return;
    }

    try {
      debugPrint(
        "🔍 [PersonBlock] Syncing profile for ${user.id} (LOCAL FIRST)...",
      );

      // 1. Fetch from LOCAL DAO first (INSTANT)
      final localPerson = await personDao.getPersonById(user.id);
      final localProfile = await personDao.getProfileForPerson(user.id);
      final localDetails = await personDao.getCVAddressForPerson(user.id);

      if (localPerson != null || localProfile != null || localDetails != null) {
        debugPrint("   - Local data found. Updating UI immediately.");
        _updateSignalFromData(
          user: user,
          localPerson: localPerson,
          localProfile: localProfile,
          localDetails: localDetails,
        );
      } else {
        debugPrint(
          "   - No local data. Initializing signal with Auth ID to unblock dependent blocks.",
        );
        _updateSignalFromData(user: user);
      }

      // 2. Trigger REMOTE Supabase fetch & Backend Sync in BACKGROUND
      unawaited(_syncRemote(user, token));
    } catch (e) {
      debugPrint("❌ [PersonBlock] Failed to fetch user profile: $e");
      if (information.value.profiles.firstName == 'Initial') {
        _applyGuestFallback();
      }
    }
  }

  /// Combined Supabase + Backend sync
  Future<void> _syncRemote(User user, String token) async {
    await appSync(token);
    await _fetchRemoteAndUpdate(user);
  }

  /// background remote fetch to keep UI non-blocking
  Future<void> _fetchRemoteAndUpdate(User user) async {
    try {
      print("🌐 [PersonBlock] Fetching remote data in background...");
      final remotePerson = await Supabase.instance.client
          .from('persons')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      final remoteProfile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      final remoteDetails = await Supabase.instance.client
          .from('detail_information')
          .select()
          .eq('person_id', user.id)
          .maybeSingle();

      // Refresh local copy too
      final localPerson = await personDao.getPersonById(user.id);
      final localProfile = await personDao.getProfileForPerson(user.id);
      final localDetails = await personDao.getCVAddressForPerson(user.id);

      _updateSignalFromData(
        user: user,
        localPerson: localPerson,
        localProfile: localProfile,
        localDetails: localDetails,
        remotePerson: remotePerson,
        remoteProfile: remoteProfile,
        remoteDetails: remoteDetails,
      );

      // 4. Persist Remote URLs to LOCAL DB for future offline/instant access
      if (remotePerson?['profile_image_url'] != null) {
        unawaited(
          personDao.updateAvatarImageUrl(
            user.id,
            remotePerson!['profile_image_url'],
          ),
        );
      }
      if (remoteDetails?['cover_image_url'] != null) {
        unawaited(
          personDao.updateCoverImageUrl(
            user.id,
            remoteDetails!['cover_image_url'],
          ),
        );
      }

      print("✅ [PersonBlock] Remote sync completed.");
    } catch (e) {
      print("⚠️ [PersonBlock] Remote background sync failed: $e");
    }
  }

  void _updateSignalFromData({
    required User user,
    PersonData? localPerson,
    ProfileData? localProfile,
    CVAddressData? localDetails,
    Map<String, dynamic>? remotePerson,
    Map<String, dynamic>? remoteProfile,
    Map<String, dynamic>? remoteDetails,
  }) {
    // 1. Construct Details (Prioritize Local > Remote > Auth)
    final details = UserDetails(
      bio:
          localDetails?.bio ??
          localProfile?.bio ??
          remoteProfile?['bio'] ??
          remoteDetails?['bio'] ??
          '',
      occupation:
          localDetails?.occupation ??
          localProfile?.occupation ??
          remoteProfile?['occupation'] ??
          remoteDetails?['occupation'] ??
          '',
      location:
          localDetails?.location ??
          localProfile?.location ??
          remoteProfile?['location'] ??
          remoteDetails?['location'] ??
          '',
      company: localDetails?.company ?? remoteDetails?['company'] ?? '',
      university:
          localDetails?.university ?? remoteDetails?['university'] ?? '',
      country: localDetails?.country ?? remoteDetails?['country'] ?? '',
      githubUrl:
          localDetails?.githubUrl ??
          localProfile?.githubUrl ??
          remoteProfile?['github_url'] ??
          remoteDetails?['github_url'] ??
          '',
      linkedinUrl:
          localDetails?.linkedinUrl ??
          localProfile?.linkedinUrl ??
          remoteProfile?['linkedin_url'] ??
          remoteDetails?['linkedin_url'] ??
          '',
      educationLevel:
          localDetails?.educationLevel ??
          localProfile?.educationLevel ??
          remoteProfile?['education_level'] ??
          remoteDetails?['education_level'] ??
          '',
      websiteUrl:
          localDetails?.websiteUrl ??
          localProfile?.websiteUrl ??
          remoteProfile?['website_url'] ??
          remoteDetails?['website_url'] ??
          '',
      email: user.email ?? '',
    );

    // 2. Construct Profile (Prioritize Local > Remote > Metadata)
    final profile = UserProfile(
      id: localPerson?.id ?? remotePerson?['id'] ?? user.id,
      firstName:
          localPerson?.firstName ??
          remotePerson?['first_name'] ??
          user.userMetadata?['first_name'] ??
          'User',
      lastName:
          localPerson?.lastName ??
          remotePerson?['last_name'] ??
          user.userMetadata?['last_name'] ??
          '',
      username:
          remotePerson?['username'] ??
          user.userMetadata?['user_name'] ??
          'user',
      profileImageUrl:
          localPerson?.profileImageUrl ??
          remotePerson?['profile_image_url'] ??
          user.userMetadata?['avatar_url'] ??
          '',
      coverImageUrl:
          localDetails?.coverImageUrl ??
          localPerson?.coverImageUrl ??
          localProfile?.coverImageUrl ??
          remoteDetails?['cover_image_url'] ??
          remotePerson?['cover_image_url'] ??
          remoteProfile?['cover_image_url'] ??
          '',
      avatarLocalPath:
          localPerson?.avatarLocalPath ?? localProfile?.avatarLocalPath ?? '',
      coverLocalPath:
          localPerson?.coverLocalPath ?? localProfile?.coverLocalPath ?? '',
      tenantId:
          localPerson?.tenantID ??
          remotePerson?['tenant_id'] ??
          remoteProfile?['tenant_id'],
    );

    batch(() {
      information.value = UserInformation(profiles: profile, details: details);
    });
  }

  void _applyGuestFallback() {
    print("👤 [PersonBlock] Applying default fallback data...");
    batch(() {
      information.value = UserInformation(
        profiles: const UserProfile(
          id: DataSeeder.guestPersonId,
          firstName: 'Guest',
          lastName: 'DuyLongArt',
          username: 'Guest',
          profileImageUrl:
              'https://ui-avatars.com/api/?name=Duy+Long&background=6366F1&color=fff',
        ),
        details: const UserDetails(
          bio: 'Securing the digital life.',
          occupation: 'Core Security Agent',
          location: 'Unknown Sector',
          email: 'agent@ice-shield.net',
        ),
      );
    });
  }

  // Consolidated image updates
  void setAvatarImage({required String remoteUrl, required String localPath}) {
    // 1. Update In-Memory Signal
    batch(() {
      information.value = UserInformation(
        details: information.value.details,
        profiles: information.value.profiles.copyWith(
          profileImageUrl: remoteUrl,
          avatarLocalPath: localPath,
        ),
      );
    });

    // 2. Persist to Local Database
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      unawaited(personDao.updateAvatarLocalPath(userId, localPath));
      unawaited(personDao.updateAvatarImageUrl(userId, remoteUrl));
    }
  }

  void setCoverImage({required String remoteUrl, required String localPath}) {
    // 1. Update In-Memory Signal
    batch(() {
      information.value = UserInformation(
        details: information.value.details,
        profiles: information.value.profiles.copyWith(
          coverImageUrl: remoteUrl,
          coverLocalPath: localPath,
        ),
      );
    });

    // 2. Persist to Local Database
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      unawaited(personDao.updateCoverLocalPath(userId, localPath));
      unawaited(personDao.updateCoverImageUrl(userId, remoteUrl));
    }
  }

  // Optimistic update for edit
  void editProfile({
    String? firstName,
    String? lastName,
    String? university,
    String? location,
    String? bio,
    String? occupation,
    String? websiteUrl,
    String? company,
    String? country,
    String? githubUrl,
    String? linkedinUrl,
    String? educationLevel,
    String? email,
  }) {
    information.value = UserInformation(
      profiles: information.value.profiles.copyWith(
        firstName: firstName,
        lastName: lastName,
      ),
      details: information.value.details.copyWith(
        university: university,
        location: location,
        bio: bio,
        occupation: occupation,
        websiteUrl: websiteUrl,
        company: company,
        country: country,
        githubUrl: githubUrl,
        linkedinUrl: linkedinUrl,
        educationLevel: educationLevel,
        email: email,
      ),
    );
  }

  // Persist edits to Supabase
  Future<void> updateProfileDatabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print("❌ [PersonBlock] No user logged in to update profile.");
      throw Exception("No user logged in");
    }

    try {
      final details = information.value.details;
      final profile = information.value.profiles;

      print(
        "💾 [PersonBlock] Updating profile across tables for ${user.id}...",
      );

      // We'll update via Drift first, and PowerSync will handle the remote sync.
      print(
        "   - Updating local database via Drift (PowerSync will sync to Supabase)...",
      );
      await personDao.upsertPersonProfileData(
        personId: user.id,
        firstName: profile.firstName,
        lastName: profile.lastName,
        profileImageUrl: profile.profileImageUrl,
        coverImageUrl: profile.coverImageUrl,
        avatarLocalPath: profile.avatarLocalPath,
        coverLocalPath: profile.coverLocalPath,
        bio: details.bio,
        occupation: details.occupation,
        educationLevel: details.educationLevel,
        location: details.location,
        websiteUrl: details.websiteUrl,
        linkedinUrl: details.linkedinUrl,
        githubUrl: details.githubUrl,
        company: details.company,
        university: details.university,
        country: details.country,
      );

      print(
        "✅ [PersonBlock] Multi-table Profile Update COMPLETED locally for ${user.id}. PowerSync will sync shortly.",
      );
    } catch (e) {
      print("❌ [PersonBlock] Failed to update profile in database: $e");
      rethrow;
    }
  }

  // Fetch User Role
  Future<void> getUserRole(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || token == "mock_guest_jwt_token") {
      account.value = const UserAccount(role: 'GUEST');
      return;
    }

    try {
      // For now, assume a field exists or just default to USER
      // Role management might be in a separate table or app_metadata
      final role = user.appMetadata['role'] ?? 'USER';
      account.value = UserAccount(role: role);
      print("✅ [PersonBlock] User Role: $role");
    } catch (e) {
      print("❌ [PersonBlock] Failed to get user role: $e");
      account.value = const UserAccount(role: 'USER');
    }
  }

  // Fetch Skills from Supabase
  Future<void> getUserSkill(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || token == "mock_guest_jwt_token") {
      skills.value = [];
      return;
    }

    try {
      final personId = information.value.profiles.id;
      if (personId == null) {
        print(
          "⚠️ [PersonBlock] Skipping skills fetch: No personID resolved yet.",
        );
        skills.value = [];
        return;
      }

      final response = await Supabase.instance.client
          .from('skills')
          .select()
          .eq('person_id', personId);

      final skillList = (response as List)
          .map((s) => SkillType.fromJson(s))
          .toList();

      skills.value = skillList;
      print("✅ [PersonBlock] ${skillList.length} skills fetched.");
    } catch (e) {
      print("❌ [PersonBlock] Failed to get user skills: $e");
      skills.value = [];
    }
  }

  // Unified Fetch Method
  Future<void> fetchInitialData(String token) async {
    if (token.isEmpty) return;

    print("🚀 [PersonBlock] Starting Initial Data Fetch (Sequential Flow)...");

    // 1. First resolve person identity
    await fetchFromDatabase(token);

    // 2. Then fetch dependent data
    await Future.wait([getUserRole(token), getUserSkill(token)]);
    print("✅ [PersonBlock] Initial Data Fetch Completed");
  }

  /// Fetch a specific person's profile for viewing
  Future<void> fetchPersonById(String personId) async {
    try {
      debugPrint("🔍 [PersonBlock] Fetching profile for viewing: $personId");

      final localPerson = await personDao.getPersonById(personId);
      final localProfile = await personDao.getProfileForPerson(personId);
      final localDetails = await personDao.getCVAddressForPerson(personId);

      if (localPerson == null && localProfile == null) {
        debugPrint("⚠️ [PersonBlock] Person $personId not found locally.");
        viewedInformation.value = null;
        return;
      }

      final details = UserDetails(
        bio: localDetails?.bio ?? localProfile?.bio ?? '',
        occupation: localDetails?.occupation ?? localProfile?.occupation ?? '',
        location: localDetails?.location ?? localProfile?.location ?? '',
        company: localDetails?.company ?? '',
        university: localDetails?.university ?? '',
        country: localDetails?.country ?? '',
        githubUrl: localDetails?.githubUrl ?? localProfile?.githubUrl ?? '',
        linkedinUrl:
            localDetails?.linkedinUrl ?? localProfile?.linkedinUrl ?? '',
        educationLevel:
            localDetails?.educationLevel ?? localProfile?.educationLevel ?? '',
        websiteUrl: localDetails?.websiteUrl ?? localProfile?.websiteUrl ?? '',
      );

      final profile = UserProfile(
        id: personId,
        firstName: localPerson?.firstName ?? '',
        lastName: localPerson?.lastName ?? '',
        username:
            '', // PersonData doesn't have username, it's in UserAccountsTable
        profileImageUrl: localPerson?.profileImageUrl ?? '',
        coverImageUrl:
            localDetails?.coverImageUrl ??
            localPerson?.coverImageUrl ??
            localProfile?.coverImageUrl ??
            '',
        avatarLocalPath:
            localPerson?.avatarLocalPath ?? localProfile?.avatarLocalPath ?? '',
        coverLocalPath:
            localPerson?.coverLocalPath ?? localProfile?.coverLocalPath ?? '',
      );

      viewedInformation.value = UserInformation(
        profiles: profile,
        details: details,
      );
    } catch (e) {
      debugPrint("❌ [PersonBlock] Failed to fetch person $personId: $e");
      viewedInformation.value = null;
    }
  }
}
