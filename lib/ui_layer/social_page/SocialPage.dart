import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_shield/ui_layer/home_page/MainButton.dart';
import 'package:ice_shield/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:share_plus/share_plus.dart';

import 'package:drift/drift.dart' show Value;
import 'package:signals_flutter/signals_flutter.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  static final activeTab = signal(0);

  static Widget icon(BuildContext context, {double? size}) {
    return Watch((context) {
      final index = activeTab.value;
      IconData iconData;
      VoidCallback action;

      switch (index) {
        case 0:
          iconData = Icons.share_rounded;
          action = () {
            Share.share(
              'Check out my rank on ICE Shield! I am making progress!',
            );
          };
          break;
        case 1:
          iconData = Icons.person_add_rounded;
          action = () => showAddOrImportOptions(context);
          break;
        case 2:
          iconData = Icons.add_task_rounded;
          action = () => showAddFeatDialog(context);
          break;
        default:
          iconData = Icons.account_circle_outlined;
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
              quest == null ? "RECORD ACHIEVEMENT" : "UPDATE ACHIEVEMENT",
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
                      "Achievement Title (e.g. Swinging in 2h)",
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
                      "System EXP Reward",
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
                            : Image.file(
                                File(imageController.text),
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
                            "Image URL",
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
                              imageController.text = image.path;
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
                  "CANCEL",
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
                      final personId = personBlock.currentPersonID.value;

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
                              imageController.text.isNotEmpty
                                  ? imageController.text
                                  : null,
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
                              imageController.text.isNotEmpty
                                  ? imageController.text
                                  : null,
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
                                  ? "ACHIEVEMENT RECORDED IN SYSTEM"
                                  : "ACHIEVEMENT UPDATED",
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
                            content: Text("SYSTEM ERROR: $e"),
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
                  quest == null ? "RECORD FEAT" : "UPDATE FEAT",
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
              title: const Text('Import from Contacts'),
              onTap: () {
                Navigator.pop(context);
                importContacts(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_rounded),
              title: const Text('Add Manually'),
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
              "REGISTER AGENT",
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
                    decoration: buildInputDecoration(context, "First Name"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: lastNameController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: buildInputDecoration(context, "Last Name"),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "RELATIONSHIP TYPE",
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
                    value: selectedRelationship,
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
                  "CANCEL",
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
                child: const Text(
                  "CREATE LINK",
                  style: TextStyle(fontWeight: FontWeight.w900),
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      SocialPage.activeTab.value = _tabController.index;
    });
  }

  @override
  void dispose() {
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
          toolbarHeight: 0, // We use a custom header
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildTacticalHeader(context),
            // const SizedBox(height: 16),
            _buildCustomTabBar(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGlobalRankingList(context),
                  _buildMergedContactList(context),
                  _buildAchievementsGrid(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTacticalHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: []),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      // padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.primary.withOpacity(0.15),
          border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
        ),
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        padding: EdgeInsets.symmetric(horizontal: 10),
        tabs: const [
          Tab(text: 'RANKING'),
          Tab(text: 'RELATIONSHIP'),
          Tab(text: 'ACHIEVEMENTS'),
        ],
      ),
    );
  }

  Widget _buildGlobalRankingList(BuildContext context) {
    final scoreDao = context.watch<ScoreDAO>();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<GlobalRankingEntry>>(
      stream: scoreDao.watchGlobalRanking(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rankings = snapshot.data!;

        if (rankings.isEmpty) {
          return _buildEmptyState(
            context,
            'No data in the Global Supremacy Board.',
            Icons.leaderboard_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: rankings.length,
          itemBuilder: (context, index) {
            final entry = rankings[index];
            final person = entry.person;
            final isTopThree = index < 3;

            Color rankColor = Colors.white38;
            if (index == 0) {
              rankColor = Colors.amber;
            } else if (index == 1) {
              rankColor = const Color(0xFFC0C0C0); // Silver
            } else if (index == 2) {
              rankColor = const Color(0xFFCD7F32); // Bronze
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isTopThree
                      ? rankColor.withOpacity(0.5)
                      : colorScheme.outlineVariant,
                  width: isTopThree ? 1.5 : 1,
                ),
                boxShadow: isTopThree
                    ? [
                        BoxShadow(
                          color: rankColor.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isTopThree
                              ? rankColor
                              : colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: colorScheme.surface,
                        backgroundImage: person.profileImageUrl != null
                            ? NetworkImage(person.profileImageUrl!)
                            : null,
                        child: person.profileImageUrl == null
                            ? Text(
                                person.firstName[0].toUpperCase(),
                                style: TextStyle(
                                  color: rankColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (isTopThree)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: rankColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surfaceContainer,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          index == 0
                              ? Icons.workspace_premium_rounded
                              : Icons.star_rounded,
                          size: 14,
                          color: Colors.black87,
                        ),
                      ),
                  ],
                ),
                title: Text(
                  '${person.firstName} ${person.lastName ?? ''}',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'GLOBAL SCORE: ${entry.totalScore.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'RANK',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: rankColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
              'No person registered in your network.',
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

    return Container(
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
                                    color: colorScheme.primary.withOpacity(0.1),
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
                                          color: relationshipColor.withOpacity(
                                            0.4,
                                          ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TRUST LEVEL',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.6),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  'LVL ${(person.affection / 100).floor() + 1}',
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
                                        'Bond Strengthened! Social Score +5.0',
                                        style: TextStyle(
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: colorScheme.primaryContainer,
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
                            backgroundColor: relationshipColor.withOpacity(0.1),
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
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: IconButton(
                          onPressed: () =>
                              _showRelationshipOptions(context, person, dao),
                          icon: const Icon(Icons.settings_outlined, size: 20),
                          tooltip: 'Options',
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
              'MANAGE RELATIONSHIP',
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
              title: 'Change to Friend',
              onTap: () {
                dao.updateContactRelationship(person.id, 'friend');
                Navigator.pop(context);
              },
            ),
            _buildOptionItem(
              context,
              icon: Icons.favorite_rounded,
              title: 'Change to Dating',
              onTap: () {
                dao.updateContactRelationship(person.id, 'dating');
                Navigator.pop(context);
              },
            ),
            _buildOptionItem(
              context,
              icon: Icons.family_restroom_rounded,
              title: 'Change to Family',
              onTap: () {
                dao.updateContactRelationship(person.id, 'family');
                Navigator.pop(context);
              },
            ),
            const Divider(height: 32),
            _buildOptionItem(
              context,
              icon: Icons.delete_outline_rounded,
              title: 'Delete Bond',
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
              'No achievements recorded in the System.',
              Icons.emoji_events_outlined,
            );
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth < 600 ? 2 : 3;

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
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
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("DELETE FEAT"),
            content: const Text(
              "Are you sure you want to remove this achievement from your system history?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCEL"),
              ),
              TextButton(
                onPressed: () async {
                  final dao = context.read<QuestDAO>();
                  await dao.deleteQuest(quest.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  "DELETE",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onPrimaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.05),
              blurRadius: 15,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    if (quest.imageUrl != null && quest.imageUrl!.isNotEmpty)
                      quest.imageUrl!.startsWith('http')
                          ? Image.network(
                              quest.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(quest.imageUrl!),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                    else
                      Container(
                        color: colorScheme.primary.withOpacity(0.05),
                        child: Center(
                          child: Icon(
                            _getFeatIcon(quest.title ?? ""),
                            size: 40,
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '+${quest.rewardExp} EXP',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            quest.title?.toUpperCase() ?? "LEGENDARY FEAT",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () => SocialPage.showAddFeatDialog(
                                context,
                                quest: quest,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.ios_share_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                final String textToShare =
                                    "I just unlocked the '${quest.title ?? "Unnamed"}' feat in ICE Gate! +${quest.rewardExp ?? 0} System EXP.";
                                Share.share(textToShare);
                              },
                            ),
                          ],
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

  IconData _getFeatIcon(String title) {
    return Icons.military_tech_rounded;
  }
}
