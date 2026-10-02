import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';

import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';
// For ImageFilter
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/identity_page/widgets/PasskeySetupCard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/RadialPremiumBackground.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  static Widget icon(BuildContext context, {double size = 56.0}) {
    return MainButton(
      type: "profile",
      icon: Icons.settings,
      destination: "/personal-info",
      size: size,
      backgroundColor: EntryColors.arcticSilver,
      iconColor: EntryColors.obsidianBase,
      mainFunction: () {
        context.push("/settings");
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context, "/settings");
      },
      onSwipeLeft: () {
        WidgetNavigatorAction.smartPop(context, "/settings");
      },
      onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context, "/settings");
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
        final personBlock = context.read<PersonBlock>();
        objectBlock.updateUrlOfUser(personBlock);
        // Same paths as saveAnyLocalImage: {personId}/{subFolder}
        final pid = personBlock.currentPersonID.value;
        if (pid != null && pid.isNotEmpty) {
          objectBlock.logFolderContents('profile_images', personId: pid);
          objectBlock.logFolderContents('meals', personId: pid);
          objectBlock.logFolderContents('quests', personId: pid);
        }
      }
    });

    _animationController.forward();
  }

  void _showPasskeySetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: EntryColors.obsidianBase.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: EntryColors.glassBorder),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 8),
                    PasskeySetupCard(),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.msg_err_not_authenticated)));
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
        imageCache.evict(FileImage(File(localPath)));

        final personBlock = context.read<PersonBlock>();
        final remoteUrl = objectBlock.userObjectResource.value.avatarImage;
        personBlock.setAvatarImage(
          remoteUrl: remoteUrl,
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
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.msg_err_not_authenticated)));
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: EntryColors.obsidianBase,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: RadialPremiumBackground(
        child: Scaffold(
          key: ValueKey(info.profiles.id),
          // backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            toolbarHeight: 70,
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
                        tooltip: AppLocalizations.of(context)!.tooltip_save,
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
                        tooltip: AppLocalizations.of(context)!.tooltip_edit,
                      ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  color: colorScheme.primary.withValues(alpha: 0.1),
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
                                label: AppLocalizations.of(
                                  context,
                                )!.email_label,
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
                                label: AppLocalizations.of(
                                  context,
                                )!.country_label,
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
                                label: AppLocalizations.of(
                                  context,
                                )!.github_label,
                                icon: Icons.code_rounded,
                                enabled: _isEditing,
                              ),
                              _buildModernTextField(
                                controller: _linkedinController,
                                label: AppLocalizations.of(
                                  context,
                                )!.linkedin_label,
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
                          Watch((context) {
                            final hasPassword =
                                _authBlock.hasLocalPassword.value;
                            if (hasPassword) return const SizedBox.shrink();

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colorScheme.primary.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.identity_evolution,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppLocalizations.of(context)!.identity_evolution_desc,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.push('/change-password'),
                                    child: Text(AppLocalizations.of(context)!.btn_set),
                                  ),
                                ],
                              ),
                            );
                          }),

                          // SECURITY & PRIVACY SECTION
                          Watch((context) {
                            final colorScheme = Theme.of(context).colorScheme;

                            return _buildInfoGroup(
                              title: AppLocalizations.of(context)!.security_accuracy,
                              icon: Icons.shield,
                              children: [
                                _buildSecurityItem(
                                  context: context,
                                  title: AppLocalizations.of(context)!.passkey_settings,
                                  subtitle: _authBlock.isPasskeyEnrolled.value
                                      ? AppLocalizations.of(context)!.fast_track_active
                                      : AppLocalizations.of(context)!.upgrade_biometric,
                                  icon: Icons.key_rounded,
                                  trailing: _authBlock.isPasskeyEnrolled.value
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            color: Colors.green
                                                .withValues(alpha: 0.12),
                                            border: Border.all(
                                              color: Colors.green
                                                  .withValues(alpha: 0.35),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                size: 16,
                                                color: Colors.green
                                                    .withValues(alpha: 0.95),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'ACTIVE',
                                                style: TextStyle(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.95),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Icon(
                                          Icons.chevron_right_rounded,
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.5),
                                        ),
                                  onTap: () => _showPasskeySetupDialog(),
                                ),
                                // _buildSecurityItem(
                                //   context: context,
                                //   title: "Encryption Key",
                                //   subtitle: "Managed by Ice Gate Protocol",
                                //   icon: Icons.vpn_key_rounded,
                                //   trailing: const Icon(
                                //     Icons.lock_rounded,
                                //     size: 16,
                                //     color: Colors.grey,
                                //   ),
                                //   onTap: () {
                                //     ScaffoldMessenger.of(context).showSnackBar(
                                //       const SnackBar(
                                //         content: Text(
                                //           "Key rotations are handled automatically by the neural engine.",
                                //         ),
                                //       ),
                                //     );
                                //   },
                                // ),
                              ],
                            );
                          }),
                          const SizedBox(height: 48),

                          // Sign out — flat pill (no gradient / shadow)
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 1.5,
                            height: 48,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _authBlock.logout();
                                  context.go("/login");
                                },
                                splashColor: const Color(0xFFE07A7A)
                                    .withValues(alpha: 0.12),
                                highlightColor: const Color(0xFFE07A7A)
                                    .withValues(alpha: 0.06),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2226),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFF6B454A)
                                          .withValues(alpha: 0.85),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.logout_rounded,
                                        size: 20,
                                        color: const Color(0xFFE8A8AE)
                                            .withValues(alpha: 0.95),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .logout
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: EntryLandscapePalette
                                              .icyWhiteBlue
                                              .withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11.5,
                                          letterSpacing: 4.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
              ),
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
      height: 350,
      child: Stack(
        children: [
          // Background Gradient / Cover
          GestureDetector(
            onTap: _isEditing ? _uploadCover : null,
            child: Container(
              height: 240,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: objectResource.coverImage.isEmpty
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.8),
                          colorScheme.secondary.withValues(alpha: 0.8),
                        ],
                      )
                    : null,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(80),
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
                    ),
                  ),
                  // Darken overlay for better contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isUploadingCover)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context)!.change_cover,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
            top: 140,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Avatar with premium border
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: _isEditing ? _uploadAvatar : null,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: LocalFirstImage(
                            ownerId: info.profiles.id,
                            localPath: info.profiles.avatarLocalPath,
                            remoteUrl: objectResource.avatarImage,
                            fit: BoxFit.cover,
                            placeholder: Icon(
                              Icons.person_rounded,
                              size: 60,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        if (_isEditing)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: _isUploadingAvatar
                                  ? const Center(
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 30),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name & Alias with Glassmorphism
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            info.profiles.firstName.isNotEmpty
                                ? "${info.profiles.firstName} ${info.profiles.lastName}"
                                : AppLocalizations.of(context)!.user_default,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              // Use theme-aware foreground to avoid invisible text
                              // on light surfaces (desktop/web themes).
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "@${info.profiles.username.split('-').first}".toUpperCase(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    shadows: [
                      Shadow(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.01),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.05),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
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
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.text.isNotEmpty
                            ? controller.text
                            : AppLocalizations.of(context)!.hint_enter_your,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      cursorColor: colorScheme.primary,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary.withValues(alpha: 0.95),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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

  Widget _buildSecurityItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.01),
              ],
            ),
          ),
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: colorScheme.primary, size: 22),
            ),
            title: Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing: trailing,
          ),
        ),
      ),
    );
  }
}
