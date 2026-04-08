import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:ice_gate/ui_layer/social_page/SocialNotesDashboard.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';
import 'package:share_plus/share_plus.dart';

import 'package:drift/drift.dart' show Value;
import 'package:signals_flutter/signals_flutter.dart';
import 'package:live_activities/live_activities.dart';
import 'package:flutter/foundation.dart';

import 'package:ice_gate/ui_layer/social_page/SocialAnalysisPage.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  static Widget icon(BuildContext context, {double? size}) {
    return Watch((context) {
      final socialBlock = context.read<SocialBlock>();
      final index = socialBlock.activeTab.value;
      IconData iconData;
      VoidCallback action;
      print("social index: $index");
      switch (index) {
        case 0: // Journal
          iconData = Icons.edit_note_rounded;
          action = () => context.push('/projects/editor', extra: {
                'category': 'social',
              });
          break;
        case 1: // Relationships
          iconData = Icons.self_improvement_rounded;
          action = () => showAddOrImportOptions(context);
          break;
        case 2: // Achievements
          iconData = Icons.spa_rounded;
          action = () => showAddFeatDialog(context);
          break;
        case 3: // Analysis
          iconData = Icons.bar_chart_rounded;
          action = () {
            // Placeholder for analysis action or navigation
          };
          break;
        default:
          iconData = Icons.psychology_outlined;
          action = () => context.go("/");
      }

      return MainButton(
        type: "social",
        destination: "/social",
        mainFunction: action,
        onSwipeUp: () {
          WidgetNavigatorAction.smartPop(context);
        },
        onSwipeRight: () {
          WidgetNavigatorAction.smartPop(context);
        },
        onLongPress: () {
          context.go("/social/dashboard");
        },
        onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
        size: size,
        icon: iconData,
        subButtons: [],
      );
    });
  }

  static void showAddFeatDialog(BuildContext context, {QuestData? quest}) {
    final titleController = TextEditingController(text: quest?.title);
    final expController = TextEditingController(
      text: quest?.rewardExp?.toString() ?? "50",
    );
    final imageController = TextEditingController(text: quest?.imageUrl);
    final ImagePicker picker = ImagePicker();
    XFile? pickedXFile; // Temporary storage for freshly picked file

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            title: Text(
              quest == null
                  ? AppLocalizations.of(context)!.record_achievement
                  : AppLocalizations.of(context)!.update_achievement,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: buildInputDecoration(
                      context,
                      AppLocalizations.of(context)!.achievement_title_label,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: expController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: buildInputDecoration(
                      context,
                      AppLocalizations.of(context)!.system_exp_reward,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (imageController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageController.text.startsWith('http')
                            ? Image.network(
                                imageController.text,
                                height: 100,
                                width: 350,
                                fit: BoxFit.cover,
                              )
                            : LocalFirstImage(
                                ownerId: context
                                    .read<PersonBlock>()
                                    .currentPersonID
                                    .value,
                                localPath: imageController.text,
                                remoteUrl: '', // Locally picked, no remote yet
                                subFolder: 'quests',
                                height: 100,
                                width: 350,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: imageController,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: buildInputDecoration(
                            context,
                            AppLocalizations.of(context)!.image_url,
                          ),
                          onChanged: (v) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setModalState(() {
                              pickedXFile = image;
                              imageController.text = image.name;
                            });
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    try {
                      final dao = context.read<QuestDAO>();
                      final personBlock = context.read<PersonBlock>();
                      final objectBlock = context.read<ObjectDatabaseBlock>();
                      final personId = personBlock.currentPersonID.value;

                      String finalImageUrl = imageController.text;

                      // If we have a freshly picked file, save it to app directory first
                      if (pickedXFile != null) {
                        finalImageUrl = await objectBlock.saveAnyLocalImage(
                          pickedXFile!,
                          subFolder: 'quests',
                          personId: personId,
                        );
                      }

                      if (quest == null) {
                        await dao.insertQuest(
                          QuestsTableCompanion(
                            id: Value(IDGen.UUIDV7()),
                            title: Value(titleController.text),
                            personID: Value(personId),
                            rewardExp: Value(
                              int.tryParse(expController.text) ?? 50,
                            ),
                            isCompleted: const Value(true),
                            category: const Value('feat'),
                            currentValue: const Value(1.0),
                            targetValue: const Value(1.0),
                            createdAt: Value(DateTime.now()),
                            imageUrl: Value(
                              finalImageUrl.isNotEmpty ? finalImageUrl : null,
                            ),
                          ),
                        );
                      } else {
                        await dao.updateQuest(
                          quest.copyWith(
                            title: Value(titleController.text),
                            rewardExp: Value(
                              int.tryParse(expController.text) ?? 50,
                            ),
                            imageUrl: Value(
                              finalImageUrl.isNotEmpty ? finalImageUrl : null,
                            ),
                          ),
                        );
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              quest == null
                                  ? AppLocalizations.of(
                                      context,
                                    )!.achievement_recorded
                                  : AppLocalizations.of(
                                      context,
                                    )!.achievement_updated,
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint("Error saving feat: $e");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              )!.system_error(e.toString()),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  quest == null
                      ? AppLocalizations.of(context)!.record_feat
                      : AppLocalizations.of(context)!.update_feat,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static InputDecoration buildInputDecoration(
    BuildContext context,
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static void showAddOrImportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.contact_phone_rounded),
              title: Text(AppLocalizations.of(context)!.import_from_contacts),
              onTap: () {
                Navigator.pop(context);
                importContacts(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_rounded),
              title: Text(AppLocalizations.of(context)!.add_manually),
              onTap: () {
                Navigator.pop(context);
                showManualAddPersonDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showManualAddPersonDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    String selectedRelationship = 'friend';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            title: Text(
              AppLocalizations.of(context)!.register_agent,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: buildInputDecoration(
                      context,
                      AppLocalizations.of(context)!.first_name,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lastNameController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: buildInputDecoration(
                      context,
                      AppLocalizations.of(context)!.last_name,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context)!.relationship_type,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRelationship,
                    dropdownColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHigh,
                    decoration: buildInputDecoration(context, ""),
                    items: ['friend', 'dating', 'family'].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() {
                          selectedRelationship = v;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (firstNameController.text.isNotEmpty) {
                    final dao = context.read<PersonManagementDAO>();
                    await dao.createContact(
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                      relationship: selectedRelationship,
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.create_link,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> importContacts(BuildContext context) async {
    if (await FlutterContacts.requestPermission()) {
      final allContacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      final dao = context.read<PersonManagementDAO>();
      final existingPeopleStream = await dao.watchAllPersons().first;
      final existingFullNames = existingPeopleStream.map((p) {
        final first = p.firstName;
        final last = p.lastName;
        return '$first $last'.trim().toLowerCase();
      }).toSet();

      final newContacts = <Contact>[];
      final seenNewNames = <String>{};

      for (var c in allContacts) {
        String contactName = c.displayName.trim();
        if (contactName.isEmpty ||
            contactName.toLowerCase() == 'null null' ||
            contactName.toLowerCase() == 'null') {
          final first = c.name.first.trim();
          final last = c.name.last.trim();
          contactName = '$first $last'.trim();
        }

        contactName = contactName.toLowerCase();
        if (contactName.isEmpty) continue;

        if (!existingFullNames.contains(contactName) &&
            !seenNewNames.contains(contactName)) {
          newContacts.add(c);
          seenNewNames.add(contactName);
        }
      }

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          builder: (context) => ListView.builder(
            itemCount: newContacts.length,
            itemBuilder: (context, index) {
              final c = newContacts[index];
              String displayName = c.displayName.trim();
              if (displayName.isEmpty ||
                  displayName.toLowerCase() == 'null null' ||
                  displayName.toLowerCase() == 'null') {
                final first = c.name.first.trim();
                final last = c.name.last.trim();
                displayName = '$first $last'.trim();
              }

              return ListTile(
                title: Text(
                  displayName.isNotEmpty ? displayName : 'Unknown Contact',
                ),
                onTap: () async {
                  String first = c.name.first.trim();
                  String last = c.name.last.trim();

                  if (first.isEmpty && last.isEmpty) {
                    first = displayName;
                  }

                  await dao.createContact(
                    firstName: first,
                    lastName: last,
                    relationship: 'friend',
                  );
                  if (context.mounted) Navigator.pop(context);
                },
              );
            },
          ),
        );
      }
    }
  }

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _liveActivities = LiveActivities();
  String? _activityId;
  void Function()? _disposeEffect;
  late SocialBlock _socialBlock;

  @override
  void initState() {
    super.initState();
    _socialBlock = context.read<SocialBlock>();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _socialBlock.activeTab.peek(),
    );

    // Sync signal -> tab
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      final newIndex = _tabController.index;
      if (_socialBlock.activeTab.peek() != newIndex) {
        print("🔄 [TAB -> SIGNAL] Syncing index: $newIndex");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            untracked(() {
              _socialBlock.activeTab.value = newIndex;
            });
          }
        });
      }
    });

    // Sync tab -> signal (for external updates like Dynamic Island)
    _disposeEffect = effect(() {
      final index = _socialBlock.activeTab.value;
      print("🔄 [SIGNAL -> TAB] Checking sync for index: $index");

      // Update Live Activity / Dynamic Island
      if (mounted) {
        _updateLiveActivity(context, index);
      }

      if (_tabController.index != index) {
        print("🔄 [SIGNAL -> TAB] Animating TabController to: $index");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _tabController.index != index) {
            _tabController.animateTo(index);
          }
        });
      }
    });

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      _setupLiveActivity();
    }
  }

  Future<void> _setupLiveActivity() async {
    try {
      await _liveActivities.init(appGroupId: 'group.duylong.art.iceshield');
      await _createLiveActivity();
    } catch (e) {
      debugPrint("Social Live Activity Setup Error: $e");
    }
  }

  Future<void> _createLiveActivity() async {
    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _activityId = await _liveActivities.createActivity(
        'group.duylong.art.iceshield',
        {
          'title': l10n.social_dashboard,
          'songName': _getTabName(context, _tabController.index),
          'artist': "ICE GATE",
          'cover': "social_cover",
          'progress': 0.0,
        },
      );
    } catch (e) {
      debugPrint("Social Live Activity Creation Error: $e");
    }
  }

  void _updateLiveActivity(BuildContext context, int index) {
    if (_activityId != null) {
      try {
        final l10n = AppLocalizations.of(context)!;
        _liveActivities.updateActivity(_activityId!, {
          'title': l10n.social_dashboard,
          'songName': _getTabName(context, index),
          'artist': "ICE GATE",
          'cover': "social_cover",
          'progress': 0.0,
        });
        print("✅ [SOCIAL] Dynamic Island Updated to: ${_getTabName(context, index)}");
      } catch (e) {
        debugPrint("Social Live Activity Update Error: $e");
      }
    }
  }

  String _getTabName(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return l10n.journal;
      case 1:
        return l10n.relationships;
      case 2:
        return l10n.achievements;
      case 3:
        return "ANALYSIS"; // Placeholder for L10n
      default:
        return l10n.social;
    }
  }

  String _getRankSuffix(BuildContext context, int rank) {
    final l10n = AppLocalizations.of(context)!;
    switch (rank) {
      case 1:
        return l10n.social_rank_first;
      case 2:
        return l10n.social_rank_second;
      case 3:
        return l10n.social_rank_third;
      default:
        return rank.toString();
    }
  }

  @override
  void dispose() {
    if (_activityId != null) {
      _liveActivities.endActivity(_activityId!);
    }
    _disposeEffect?.call();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SwipeablePage(
      onSwipe: () => Navigator.maybePop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 80, // We use a custom header (CanvasDynamicIsland)
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            // const SizedBox(height: 16),
            // TabBar is now removed, navigation is handled by Dynamic Island
            Expanded(
              child: Watch((context) {
                // Accessing activeTab.value ensures this widget rebuilds when the signal changes
                final _ = _socialBlock.activeTab.value;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    const SocialNotesDashboard(),
                    _buildMergedContactList(context),
                    _buildAchievementsGrid(context),
                    const SocialAnalysisPage(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMergedContactList(BuildContext context) {
    return Watch((context) {
      final dao = context.read<PersonManagementDAO>();

      return StreamBuilder<List<PersonContactData>>(
        stream: dao.watchAllContacts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allContacts = snapshot.data!;
          final filtered = allContacts
              .where(
                (p) =>
                    p.relationship == 'friend' ||
                    p.relationship == 'dating' ||
                    p.relationship == 'family',
              )
              .toList();

          if (filtered.isEmpty) {
            return _buildEmptyState(
              context,
              AppLocalizations.of(context)!.social_empty_network,
              Icons.people_outline_rounded,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final contact = filtered[index];
              // Convert to PersonData for UI compatibility
              final person = PersonData(
                id: contact.id,
                firstName: contact.firstName,
                lastName: contact.lastName,
                relationship: contact.relationship,
                affection: contact.affection,
                isActive: true,
                createdAt: contact.createdAt,
                updatedAt: contact.updatedAt,
                phoneNumber: contact.phoneNumber,
                profileImageUrl: contact.profileImageUrl,
              );
              return _buildRelationshipCard(context, person);
            },
          );
        },
      );
    });
  }

  Widget _buildRelationshipCard(BuildContext context, PersonData person) {
    final dao = context.read<PersonManagementDAO>();
    final relationshipColor = _getRelationshipColor(person.relationship);
    final relationshipIcon = _getRelationshipIcon(person.relationship);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push('/profile/${person.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: relationshipColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: relationshipColor.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: -10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Subtle relationship accent background
              Positioned(
                right: -24,
                top: -24,
                child: Icon(
                  relationshipIcon,
                  size: 110,
                  color: relationshipColor.withOpacity(0.04),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Tactical Avatar
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: relationshipColor.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: relationshipColor.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              backgroundImage: person.profileImageUrl != null
                                  ? NetworkImage(person.profileImageUrl!)
                                  : null,
                              child: person.profileImageUrl == null
                                  ? Text(
                                      person.firstName[0].toUpperCase(),
                                      style: TextStyle(
                                        color: relationshipColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    )
                                  : null,
                            ),
                            // Status Indicator
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00FFA3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00FFA3,
                                      ).withOpacity(0.5),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${person.firstName} ${person.lastName ?? ''}',
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                person.relationship.toUpperCase(),
                                style: TextStyle(
                                  color: relationshipColor.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // BOND / AFFECTION BAR
                              Stack(
                                children: [
                                  Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: (person.affection % 100) / 100,
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: relationshipColor
                                                .withOpacity(0.4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                        gradient: LinearGradient(
                                          colors: [
                                            relationshipColor,
                                            relationshipColor.withOpacity(0.6),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.social_trust_level,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.6),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!.level((person.affection / 100).floor() + 1),
                                    style: TextStyle(
                                      color: relationshipColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ACTION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final scoreBlock = context.read<ScoreBlock>();

                              // 1. Increase affection in local DB
                              await dao.increaseContactAffection(
                                person.id,
                                amount: DEFAULT_AFFECTION_INCREASE,
                              );

                              // 2. Add points to Social Score manually
                              await scoreBlock.manualSocialIncrement(5.0);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          color: relationshipColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)!.social_bond_strengthened,
                                          style: TextStyle(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: relationshipColor.withOpacity(
                                0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: relationshipColor.withOpacity(0.3),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  size: 16,
                                  color: relationshipColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'STRENGTHEN BOND',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () =>
                                _showRelationshipOptions(context, person, dao),
                            icon: const Icon(Icons.settings_outlined, size: 20),
                            tooltip: AppLocalizations.of(context)!.social_options,
                          ),
                        ),
                      ],
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

  void _showRelationshipOptions(
    BuildContext context,
    PersonData person,
    PersonManagementDAO dao,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.social_manage_title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionItem(
              context,
              icon: Icons.person_add_disabled_rounded,
              title: AppLocalizations.of(context)!.social_change_friend,
              onTap: () {
                dao.updateContactRelationship(person.id, 'friend');
                Navigator.pop(context);
              },
            ),
            _buildOptionItem(
              context,
              icon: Icons.favorite_rounded,
              title: AppLocalizations.of(context)!.social_change_dating,
              onTap: () {
                dao.updateContactRelationship(person.id, 'dating');
                Navigator.pop(context);
              },
            ),
            _buildOptionItem(
              context,
              icon: Icons.family_restroom_rounded,
              title: AppLocalizations.of(context)!.social_change_family,
              onTap: () {
                dao.updateContactRelationship(person.id, 'family');
                Navigator.pop(context);
              },
            ),
            const Divider(height: 32),
            _buildOptionItem(
              context,
              icon: Icons.delete_outline_rounded,
              title: AppLocalizations.of(context)!.social_delete_bond,
              isDestructive: true,
              onTap: () {
                dao.deleteContact(person.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.redAccent
        : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRelationshipIcon(String type) {
    switch (type.toLowerCase()) {
      case 'friend':
        return Icons.people_rounded;
      case 'dating':
        return Icons.favorite_rounded;
      case 'family':
        return Icons.family_restroom_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Color _getRelationshipColor(String type) {
    switch (type.toLowerCase()) {
      case 'friend':
        return const Color(0xFF1877F2); // Vibrant FB Blue
      case 'dating':
        return const Color(0xFFFF2D55); // Neon Pink
      case 'family':
        return const Color.fromARGB(255, 30, 214, 40); // System Green
      default:
        return const Color(0xFF8E8E93); // System Gray
    }
  }

  Widget _buildEmptyState(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
            ),
            child: Icon(
              icon,
              size: 48,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context) {
    return Watch((context) {
      final questDao = context.read<QuestDAO>();
      final personBlock = context.read<PersonBlock>();
      final currentPersonId = personBlock.currentPersonID.value ?? "";

      return StreamBuilder<List<QuestData>>(
        stream: questDao.watchQuestsByPerson(currentPersonId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final quests = snapshot.data!
              .where((q) => q.category?.toLowerCase() == 'feat')
              .toList();

          if (quests.isEmpty) {
            return _buildEmptyState(
              context,
              AppLocalizations.of(context)!.social_no_achievements,
              Icons.emoji_events_outlined,
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Taller for progress bar
            ),
            itemCount: quests.length,
            itemBuilder: (context, index) {
              final quest = quests[index];
              return _buildFeatCard(context, quest);
            },
          );
        },
      );
    });
  }

  Widget _buildFeatCard(BuildContext context, QuestData quest) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = quest.isCompleted ?? false;
    // Percentage placeholder - in a real app this would come from the database
    final double progress = isCompleted
        ? 1.0
        : ((quest.rewardExp ?? 0) % 100) / 100.0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Hero(
                  tag: 'feat_${quest.id}',
                  child: Icon(
                    _getFeatIcon(quest.title ?? ""),
                    size: 48,
                    color: Colors.blue.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title?.toUpperCase() ?? AppLocalizations.of(context)!.social_feat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '+${quest.rewardExp} EXP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          color: Colors.blue,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 16,
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFeatIcon(String title) {
    return Icons.military_tech_rounded;
  }
}
