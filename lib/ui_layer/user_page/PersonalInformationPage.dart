import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';

import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';
// For ImageFilter
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/ui_layer/user_page/PasskeyEnrollmentWidget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  static Widget icon(BuildContext context, {double size = 56.0}) {
    return MainButton(
      type: "profile",
      icon: Icons.settings,
      destination: "/personal-info",
      size: size,
      mainFunction: () {
        context.push("/settings");
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeLeft: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
    );
  }

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _githubController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // late PersonManagementDAO personManagementDAO; // Unused
  final _formKey = GlobalKey<FormState>();
  late final AuthBlock _authBlock;

  // Store loaded data
  // PersonData? _loadedPerson; // Unused
  // EmailAddressData? _loadedEmail; // Unused
  // UserAccountData? _loadedAccount; // Unused
  // ProfileData? _loadedProfile; // Unused
  // bool _isLoading = true; // Unused

  @override
  void initState() {
    super.initState();
    _authBlock = context.read<AuthBlock>();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Initialize MinIO URLs in ObjectDatabaseBlock
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final objectBlock = context.read<ObjectDatabaseBlock>();
        objectBlock.updateUrlOfUser(context.read<PersonBlock>());
        // Log folders for debugging on device
        objectBlock.logFolderContents('profile_images');
        objectBlock.logFolderContents('meals');
        objectBlock.logFolderContents('quests');
      }
    });
  }

  // Helper to sync controllers with current state (call in build or listener)
  void _syncControllersWithState(UserInformation info) {
    // Sync if not editing to ensure latest data is shown
    _firstNameController.text = info.profiles.firstName;
    _lastNameController.text = info.profiles.lastName;
    _bioController.text = info.details.bio;
    _occupationController.text = info.details.occupation;
    _websiteController.text = info.details.websiteUrl;
    _cityController.text = info.details.location;
    _companyController.text = info.details.company;
    _countryController.text = info.details.country;
    _githubController.text = info.details.githubUrl;
    _linkedinController.text = info.details.linkedinUrl;
    _universityController.text = info.details.university;
    _educationController.text = info.details.educationLevel;
    _usernameController.text = info.profiles.username;
    _emailController.text = info.details.email;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    _occupationController.dispose();
    _companyController.dispose();
    _websiteController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _universityController.dispose();
    _educationController.dispose();
    _animationController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(bool isCreate) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final personBlock = context.read<PersonBlock>();
      final token = _authBlock.jwt.value;

      if (token == null || token.isEmpty) {
        // Handle missing token case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.msg_err_not_authenticated,
            ),
          ),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Better: Get token from AuthBlock if possible.
      // I'll assume for this refactor we call updateProfileDatabase.
      // Wait, PersonBlock.updateProfileDatabase takes 'token'.

      // Optimistic update
      personBlock.editProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        university: _universityController.text,
        location: _cityController.text,
        bio: _bioController.text,
        occupation: _occupationController.text,
        company: _companyController.text,
        websiteUrl: _websiteController.text,
        country: _countryController.text,
        githubUrl: _githubController.text,
        linkedinUrl: _linkedinController.text,
        educationLevel: _educationController.text,
        email: _emailController.text,
      );

      // Persist to database
      await personBlock.updateProfileDatabase(token);

      // Simulate save delay
      await Future.delayed(Duration(seconds: 1));

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.msg_personal_info_saved,
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.msg_err_save_failed(e.toString()),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadAvatar() async {
    final objectBlock = context.read<ObjectDatabaseBlock>();
    final token = _authBlock.jwt.value;
    final String? userId = Supabase.instance.client.auth.currentUser?.id;

    if (token == null || token.isEmpty || userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error: Not authenticated')));
      return;
    }

    setState(() => _isUploadingAvatar = true);

    try {
      final localPath = await objectBlock.pickAndUploadAvatar(
        userId: userId,
        token: token,
      );

      final success = localPath != null && localPath.isNotEmpty;

      if (success) {
        // Evict Flutter's image cache for this path so the UI reloads from disk
        final cacheKey = FileImage(File(localPath));
        imageCache.evict(cacheKey);

        final personBlock = context.read<PersonBlock>();
        personBlock.setAvatarImage(
          remoteUrl: objectBlock.userObjectResource.value.avatarImage,
          localPath: localPath,
        );

        // Auto-save to database to ensure the URL and local path are persisted
        await personBlock.updateProfileDatabase(token);
      }

      if (mounted) {
        if (!mounted) return;
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? AppLocalizations.of(context)!.msg_avatar_updated
                  : AppLocalizations.of(context)!.msg_avatar_cancelled,
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        debugPrint('❌ [PersonalInformationPage] Avatar upload failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.msg_err_upload_failed(e.toString()),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadCover() async {
    final objectBlock = context.read<ObjectDatabaseBlock>();
    final token = _authBlock.jwt.value;
    final String? userId = Supabase.instance.client.auth.currentUser?.id;

    if (token == null || token.isEmpty || userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error: Not authenticated')));
      return;
    }

    setState(() => _isUploadingCover = true);

    try {
      final localPath = await objectBlock.pickAndUploadCover(
        userId: userId,
        token: token,
      );

      final success = localPath != null && localPath.isNotEmpty;

      if (success) {
        // Evict Flutter's image cache for this path so the UI reloads from disk
        final cacheKey = FileImage(File(localPath));
        imageCache.evict(cacheKey);

        final personBlock = context.read<PersonBlock>();
        // personBlock.
        personBlock.setCoverImage(
          remoteUrl: objectBlock.userObjectResource.value.coverImage,
          localPath: localPath,
        );

        // Auto-save to database to ensure the URL and local path are persisted
        await personBlock.updateProfileDatabase(token);
      }

      if (mounted) {
        if (!mounted) return;
        setState(() => _isUploadingCover = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? AppLocalizations.of(context)!.msg_cover_updated
                  : AppLocalizations.of(context)!.msg_cover_cancelled,
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingCover = false);
        debugPrint('❌ [PersonalInformationPage] Cover upload failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.msg_err_upload_failed(e.toString()),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch PersonBlock signal
    final personBlock = context.watch<PersonBlock>();
    // Access the value of the signal (this triggers rebuilds when signal changes)
    final info = personBlock.information.watch(context);

    final objectBlock = context.watch<ObjectDatabaseBlock>();
    final objectResource = objectBlock.userObjectResource.watch(context);

    // Sync controllers with state if not editing (or initial load)
    // We only sync if we are not editing to avoid overwriting user input while typing
    if (!_isEditing) {
      _syncControllersWithState(info);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Show loading indicator is no longer needed as much if we have default state,
    // but if we want to show global loading we can check async state.
    // For now we assume signal has initial data.

    // ... rest of build method

    return Scaffold(
      key: ValueKey(info.profiles.id),
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 70,
        // title: Text(AppLocalizations.of(context)!.personal_info_title),
        leadingWidth: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios_new_rounded),
        //   onPressed: () => context.pop(),
        //   style: IconButton.styleFrom(
        //     backgroundColor: Theme.of(
        //       context,
        //     ).colorScheme.surface.withOpacity(0.1),
        //   ),
        // ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              color: Colors.black12,
              shape: BoxShape.circle,
            ),
            child: _isEditing
                ? IconButton(
                    icon: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _isSaving ? null : () => _saveChanges(false),
                    tooltip: 'Save',
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    tooltip: 'Edit',
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium High-Tech Header
                _buildModernHeader(
                  context,
                  colorScheme,
                  textTheme,
                  _usernameController,
                  objectResource,
                  info,
                ),

                // IDENTITY EVOLUTION BANNER
                Watch((context) {
                  final hasPassword = _authBlock.hasLocalPassword.value;
                  if (hasPassword) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.1),
                          colorScheme.secondary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "IDENTITY EVOLUTION",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Level 1: Google. Set a local password to upgrade your security tier.",
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/change-password'),
                          child: const Text("SET"),
                        ),
                      ],
                    ),
                  );
                }),

                // PASSKEY UPGRADE SECTION
                Watch((context) {
                  final hasPassword = _authBlock.hasLocalPassword.value;
                  final isPasskeyEnrolled = _authBlock.isPasskeyEnrolled.value;

                  if (hasPassword && !isPasskeyEnrolled) {
                    return const PasskeyEnrollmentWidget();
                  }
                  
                  if (isPasskeyEnrolled) {
                   return Center(child: const PasskeyEnrollmentWidget()); // Will show status view
                  }

                  return const SizedBox.shrink();
                }),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Bio Summary (Quick View)
                      if (!_isEditing && info.details.bio.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(
                              0.05,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            info.details.bio,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                      // Bio (Edit Mode)
                      if (_isEditing)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildModernTextField(
                            controller: _bioController,
                            label: AppLocalizations.of(context)!.bio,
                            icon: Icons.notes_rounded,
                            enabled: true,
                            maxLines: 5,
                            minLines: 3,
                          ),
                        ),

                      // Information Groups
                      _buildInfoGroup(
                        title: AppLocalizations.of(
                          context,
                        )!.personal_info_identification,
                        icon: Icons.fingerprint_rounded,
                        children: [
                          _buildModernTextField(
                            controller: _firstNameController,
                            label: AppLocalizations.of(
                              context,
                            )!.first_name_label,
                            icon: Icons.badge_outlined,
                            enabled: _isEditing,
                          ),
                          _buildModernTextField(
                            controller: _lastNameController,
                            label: AppLocalizations.of(
                              context,
                            )!.last_name_label,
                            icon: Icons.badge_outlined,
                            enabled: _isEditing,
                          ),
                          _buildModernTextField(
                            controller: _emailController,
                            label: AppLocalizations.of(context)!.email_label,
                            icon: Icons.alternate_email_rounded,
                            enabled: _isEditing,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildModernTextField(
                            controller: _phoneController,
                            label: AppLocalizations.of(
                              context,
                            )!.phone_number_label,
                            icon: Icons.sensors_rounded,
                            enabled: _isEditing,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildInfoGroup(
                        title: AppLocalizations.of(
                          context,
                        )!.personal_info_professional_matrix,
                        icon: Icons.lan_rounded,
                        children: [
                          _buildModernTextField(
                            controller: _occupationController,
                            label: AppLocalizations.of(context)!.role_label,
                            icon: Icons.terminal_rounded,
                            enabled: _isEditing,
                          ),
                          _buildModernTextField(
                            controller: _companyController,
                            label: AppLocalizations.of(
                              context,
                            )!.organization_label,
                            icon: Icons.corporate_fare_rounded,
                            enabled: _isEditing,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildInfoGroup(
                        title: AppLocalizations.of(
                          context,
                        )!.personal_info_education_node,
                        icon: Icons.hub_rounded,
                        children: [
                          _buildModernTextField(
                            controller: _universityController,
                            label: AppLocalizations.of(
                              context,
                            )!.institution_label,
                            icon: Icons.account_balance_rounded,
                            enabled: _isEditing,
                          ),
                          _buildModernTextField(
                            controller: _educationController,
                            label: AppLocalizations.of(
                              context,
                            )!.education_level_label,
                            icon: Icons.verified_user_rounded,
                            enabled: _isEditing,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildInfoGroup(
                        title: AppLocalizations.of(
                          context,
                        )!.personal_info_location,
                        icon: Icons.public_rounded,
                        children: [
                          _buildModernTextField(
                            controller: _countryController,
                            label: AppLocalizations.of(context)!.country_label,
                            icon: Icons.flag_rounded,
                            enabled: _isEditing,
                          ),
                          _buildModernTextField(
                            controller: _cityController,
                            label: AppLocalizations.of(context)!.city_label,
                            icon: Icons.map_rounded,
                            enabled: _isEditing,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildInfoGroup(
                        title: AppLocalizations.of(
                          context,
                        )!.personal_info_digital,
                        icon: Icons.alternate_email_rounded,
                        children: [
                          _buildModernTextField(
                            controller: _githubController,
                            label: AppLocalizations.of(context)!.github_label,
                            icon: Icons.code_rounded,
                            enabled: _isEditing,
                          ),
                          _buildModernTextField(
                            controller: _linkedinController,
                            label: AppLocalizations.of(context)!.linkedin_label,
                            icon: Icons.link_rounded,
                            enabled: _isEditing,
                          ),
                          _buildModernTextField(
                            controller: _websiteController,
                            label: AppLocalizations.of(
                              context,
                            )!.personal_web_label,
                            icon: Icons.language_rounded,
                            enabled: _isEditing,
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Danger Zone / Logout
                      InkWell(
                        onTap: () {
                          _authBlock.logout();
                          context.go("/login");
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colorScheme.error.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.power_settings_new_rounded,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)!.logout,
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    TextEditingController controller,
    UserObjectResource objectResource,
    UserInformation info,
  ) {
    return SizedBox(
      height: 325,
      child: Stack(
        children: [
          // Background Gradient / Cover
          GestureDetector(
            onTap: _isEditing ? _uploadCover : null,
            child: Container(
              height: 220,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: objectResource.coverImage.isEmpty
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                          colorScheme.tertiary,
                        ],
                      )
                    : null,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalFirstImage(
                    ownerId: info.profiles.id,
                    localPath: info.profiles.coverLocalPath,
                    remoteUrl: objectResource.coverImage,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  if (objectResource.coverImage.isEmpty) ...[
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Icon(
                        Icons.ac_unit_rounded,
                        size: 100,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ],
                  if (_isEditing)
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: _isUploadingCover
                          ? Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)!.change_cover,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),

          // Profile Info Overlap
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Avatar with premium border
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _isEditing ? _uploadAvatar : null,
                    child: Stack(
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primaryContainer,
                          ),
                          child: LocalFirstImage(
                            ownerId: info.profiles.id,
                            localPath: info.profiles.avatarLocalPath,
                            remoteUrl: objectResource.avatarImage,
                            fit: BoxFit.cover,
                            placeholder: Icon(
                              Icons.person_rounded,
                              size: 56,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        if (_isEditing)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                              ),
                              child: _isUploadingAvatar
                                  ? const Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_enhance_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Name & Alias
                Column(
                  children: [
                    // Username Badge (Top)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        "@${info.profiles.username.split('-').first}",
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Name Badge (Bottom)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.secondary.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        info.profiles.firstName.isNotEmpty
                            ? "${info.profiles.firstName} ${info.profiles.lastName}"
                            : "User",
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            thickness: 0.5,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(PersonBlock block, ColorScheme colorScheme) {
    return Watch((signalsContext) {
      final skillList = block.skills.watch(signalsContext);
      if (skillList.isEmpty) return const SizedBox.shrink();

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skillList.map((skill) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.terminal_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  skill.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildInfoGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        _buildSectionHeader(context, title, icon),
        const SizedBox(height: 16),
        ...children.expand((w) => [w, const SizedBox(height: 12)]),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    int? maxLines = 1,
    int? minLines,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!enabled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.text.isNotEmpty
                        ? controller.text
                        : 'Enter your...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
