import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_shield/ui_layer/home_page/MainButton.dart';
import 'package:ice_shield/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/data_layer/Protocol/User/PersonProtocol.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:drift/drift.dart' show Value; // Added for Drift Value

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "social",
      destination: "/social",
      mainFunction: () => context.go("/"),
      onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
      size: size,
      icon: Icons.account_circle_outlined,
      subButtons: [
        // SubButton(
        //   icon: Icons.favorite,
        //   backgroundColor: Colors.pink,
        //   onPressed: () {},
        // ),
        // SubButton(
        //   icon: Icons.family_restroom,
        //   backgroundColor: Colors.orange,
        //   onPressed: () {},
        // ),
      ],
    );
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
        floatingActionButton: _buildFloatingActionButton(context),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Column(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     Text(
              //       "SYSTEM STATUS",
              //       style: TextStyle(
              //         color: colorScheme.primary.withOpacity(0.7),
              //         fontSize: 10,
              //         fontWeight: FontWeight.bold,
              //         letterSpacing: 2,
              //       ),
              //     ),
              //     const SizedBox(height: 4),

              //   ],
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
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
        tabs: const [
          Tab(text: 'RANKING'),
          Tab(text: 'RELATIONSHIP'),
          Tab(text: 'ACHIEVEMENTS'),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return ListenableBuilder(
      listenable: _tabController,
      builder: (context, child) {
        return FloatingActionButton(
          onPressed: () {
            if (_tabController.index == 2) {
              _showAddFeatDialog(context);
            } else {
              _showAddOrImportOptions(context);
            }
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 4,
          child: Icon(
            _tabController.index == 2
                ? Icons.add_task_rounded
                : Icons.person_add_rounded,
            color: Colors.white,
            size: 28,
          ),
        );
      },
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
            if (index == 0)
              rankColor = Colors.amber;
            else if (index == 1)
              rankColor = const Color(0xFFC0C0C0); // Silver
            else if (index == 2)
              rankColor = const Color(0xFFCD7F32); // Bronze

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
    final dao = context.watch<PersonManagementDAO>();

    return StreamBuilder<List<PersonData>>(
      stream: dao.watchAllPersons(),
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
            'No agents registered in your network.',
            Icons.people_outline_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final person = filtered[index];
            return _buildRelationshipCard(context, person);
          },
        );
      },
    );
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
              child: Row(
                children: [
                  // Avatar with Facebook-style status ring
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              relationshipColor,
                              relationshipColor.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
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
                      ),
                      // Facebook Active Status Dot
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF31A24C), // FB Active Green
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            width: 3,
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // FACEBOOK STYLE VERIFIED BADGE
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1877F2), // FB Blue
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          person.relationship.toUpperCase(),
                          style: TextStyle(
                            color: relationshipColor.withOpacity(0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // BOND / AFFECTION BAR (Glowing FB Style)
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (person.affection % 100) / 100,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: relationshipColor.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
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
                              'BOND STABILITY',
                              style: TextStyle(
                                color: Colors.white38,
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
            ),
            // Menu Button at top right
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors
                      .white, // Or colorScheme.onSurface if you want it to change
                  size: 20,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                onSelected: (value) async {
                  if (value == 'delete') {
                    await dao.deletePerson(person.id);
                  } else if (value == 'increase') {
                    await dao.increaseAffection(person.id, amount: 20);
                  } else {
                    await dao.updateRelationship(person.id, value);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'increase',
                    child: Text(
                      'BOND +20',
                      style: TextStyle(color: Colors.cyanAccent),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'friend',
                    child: Text('CHANGE TO FRIEND'),
                  ),
                  const PopupMenuItem(
                    value: 'dating',
                    child: Text('CHANGE TO DATING'),
                  ),
                  const PopupMenuItem(
                    value: 'family',
                    child: Text('CHANGE TO FAMILY'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'DELTE LINK',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
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
        return Icons.radar_rounded;
      case 'dating':
        return Icons.favorite_rounded;
      case 'family':
        return Icons.shield_rounded;
      default:
        return Icons.person_pin_rounded;
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
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white38,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context) {
    final questDao = context.watch<QuestDAO>();

    return StreamBuilder<List<QuestData>>(
      stream: questDao.watchAllQuests(), // Watch all to show completed feats
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            context,
            'No achievements recorded in the System.',
            Icons.emoji_events_outlined,
          );
        }

        final quests = snapshot.data!
            .where((q) => q.category == 'feat' || q.isCompleted)
            .toList();

        if (quests.isEmpty) {
          return _buildEmptyState(
            context,
            'No feats unlocked yet.',
            Icons.stars_rounded,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.85,
          ),
          itemCount: quests.length,
          itemBuilder: (context, index) {
            final quest = quests[index];
            return _buildAchievementCard(context, quest);
          },
        );
      },
    );
  }

  Widget _buildAchievementCard(BuildContext context, QuestData quest) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = quest.imageUrl != null && quest.imageUrl!.isNotEmpty;

    ImageProvider? imageProvider;
    if (hasImage) {
      if (quest.imageUrl!.startsWith('http')) {
        imageProvider = NetworkImage(quest.imageUrl!);
      } else {
        imageProvider = FileImage(File(quest.imageUrl!));
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          if (hasImage)
            Positioned.fill(
              child: Image(
                image: imageProvider!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      _getFeatIcon(quest.title),
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),
          if (hasImage)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!hasImage)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getFeatIcon(quest.title),
                        color: colorScheme.primary,
                        size: 32,
                      ),
                    )
                  else
                    const SizedBox(height: 32),
                  const SizedBox(height: 12),
                  Text(
                    quest.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Text(
                      "+${quest.rewardExp} EXP",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.share_rounded, size: 16, color: Colors.white),
              ),
              onPressed: () {
                Share.share(
                  "I just unlocked the '${quest.title}' feat in ICE Gate! +${quest.rewardExp} System EXP.",
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFeatIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('swing')) return Icons.fitness_center_rounded;
    if (t.contains('run')) return Icons.directions_run_rounded;
    if (t.contains('walk')) return Icons.directions_walk_rounded;
    if (t.contains('code')) return Icons.code_rounded;
    if (t.contains('study')) return Icons.menu_book_rounded;
    return Icons.stars_rounded;
  }

  void _showAddFeatDialog(BuildContext context) {
    final titleController = TextEditingController();
    final expController = TextEditingController(text: "50");
    final imageController = TextEditingController();
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
              "RECORD ACHIEVEMENT",
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
                    decoration: _buildInputDecoration(
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
                    decoration: _buildInputDecoration(
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
                                width:
                                    350, // Fixed width prevents IntrinsicWidth crash in AlertDialog
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(imageController.text),
                                height: 100,
                                width:
                                    350, // Fixed width prevents IntrinsicWidth crash in AlertDialog
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
                          decoration: _buildInputDecoration(
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
                    final dao = context.read<QuestDAO>();
                    await dao.insertQuest(
                      QuestsTableCompanion(
                        id: Value(IDGen.UUIDV7()),
                        title: Value(titleController.text),
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
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "COMPLETE",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1),
      ),
    );
  }

  void _showAddOrImportOptions(BuildContext context) {
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
                _importContacts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_rounded),
              title: const Text('Add Manually'),
              onTap: () {
                Navigator.pop(context);
                // Manual add logic
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final allContacts = await FlutterContacts.getContacts(
        withProperties: true,
      );
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (context) => ListView.builder(
          itemCount: allContacts.length,
          itemBuilder: (context, index) {
            final c = allContacts[index];
            return ListTile(
              title: Text(c.displayName),
              onTap: () async {
                final dao = context.read<PersonManagementDAO>();
                await dao.createPerson(
                  PersonProtocol.create(
                    firstName: c.name.first,
                    lastName: c.name.last,
                    id: IDGen.UUIDV7(),
                    isActive: true,
                  ),
                  relationship: 'friend',
                );
                if (mounted) Navigator.pop(context);
              },
            );
          },
        ),
      );
    }
  }

  Color _getRelationshipColor(String type) {
    switch (type.toLowerCase()) {
      case 'friend':
        return const Color(0xFF1877F2); // Vibrant FB Blue
      case 'dating':
        return const Color(0xFFFF2D55); // Neon Pink
      case 'family':
        return const Color.fromARGB(255, 30, 214, 40); // System Orange
      default:
        return const Color(0xFF8E8E93); // System Gray
    }
  }
}
