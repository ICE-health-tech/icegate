import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_shield/ui_layer/home_page/MainButton.dart';
import 'package:ice_shield/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/data_layer/Protocol/User/PersonProtocol.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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
        SubButton(
          icon: Icons.favorite,
          backgroundColor: Colors.pink,
          onPressed: () {},
        ),
        SubButton(
          icon: Icons.family_restroom,
          backgroundColor: Colors.orange,
          onPressed: () {},
        ),
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwipeablePage(
      onSwipe: () => Navigator.maybePop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 60,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          
          leadingWidth: 0,
          leading: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded, size: 28),
              onPressed: () {
                WidgetNavigatorAction.smartPop(context);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // _buildDashboard(context),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  text: 'Ranking',
                  icon: Icon(Icons.leaderboard_rounded, size: 20),
                ),
                Tab(
                  text: 'Contacts',
                  icon: Icon(Icons.people_alt_rounded, size: 20),
                ),
                Tab(
                  text: 'Feats',
                  icon: Icon(Icons.emoji_events_rounded, size: 20),
                ),
              ],
            ),

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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddOrImportOptions(context),
          child: const Icon(Icons.person_add_rounded),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final personDao = context.watch<PersonManagementDAO>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            colorScheme.secondaryContainer.withOpacity(0.1),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  StreamBuilder<int>(
                    stream: personDao.watchTotalAffection(),
                    builder: (context, snapshot) {
                      final total = snapshot.data ?? 0;
                      return Text(
                        '$total ✨',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Global Influence Score',
            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
          ),
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
            'No rankings yet',
            Icons.leaderboard_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rankings.length,
          itemBuilder: (context, index) {
            final entry = rankings[index];
            final person = entry.person;
            final isTopThree = index < 3;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: isTopThree
                    ? Border.all(
                        color: index == 0
                            ? Colors.amber
                            : index == 1
                            ? Colors.grey
                            : Colors.brown,
                        width: 2,
                      )
                    : null,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: person.profileImageUrl != null
                      ? NetworkImage(person.profileImageUrl!)
                      : null,
                  child: person.profileImageUrl == null
                      ? Text(person.firstName[0].toUpperCase())
                      : null,
                ),
                title: Text(
                  '${person.firstName} ${person.lastName ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Power Score: ${entry.totalScore.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                trailing: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isTopThree
                        ? (index == 0
                              ? Colors.amber
                              : index == 1
                              ? Colors.grey
                              : Colors.brown)
                        : colorScheme.onSurfaceVariant,
                  ),
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
            'No contacts found',
            Icons.people_outline_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final person = filtered[index];
            return _buildContactTile(context, person);
          },
        );
      },
    );
  }

  Widget _buildContactTile(BuildContext context, PersonData person) {
    final colorScheme = Theme.of(context).colorScheme;
    final dao = context.read<PersonManagementDAO>();
    final relationshipColor = _getRelationshipColor(person.relationship);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: () {
          // Profile details navigation
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: person.profileImageUrl != null
              ? NetworkImage(person.profileImageUrl!)
              : null,
          child: person.profileImageUrl == null
              ? Text(person.firstName[0].toUpperCase())
              : null,
        ),
        title: Text(
          '${person.firstName} ${person.lastName ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: relationshipColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: relationshipColor.withOpacity(0.3)),
              ),
              child: Text(
                person.relationship.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: relationshipColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.favorite, size: 14, color: Colors.red),
            Text(
              ' ${person.affection.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => dao.increaseAffection(person.id, amount: 10),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) async {
                if (value == 'delete') {
                  await dao.deletePerson(person.id);
                } else {
                  await dao.updateRelationship(person.id, value);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'friend',
                  child: Text('Move to Friend'),
                ),
                const PopupMenuItem(
                  value: 'dating',
                  child: Text('Move to Dating'),
                ),
                const PopupMenuItem(
                  value: 'family',
                  child: Text('Move to Family'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Contact'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.outline.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context) {
    final questDao = context.watch<QuestDAO>();

    return StreamBuilder<List<QuestData>>(
      stream: questDao.watchActiveQuests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            context,
            'No achievements yet',
            Icons.emoji_events_outlined,
          );
        }

        final quests = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: quests.length,
          itemBuilder: (context, index) {
            final quest = quests[index];
            return Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      quest.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: quest.targetValue > 0
                          ? quest.currentValue / quest.targetValue
                          : 0,
                      borderRadius: BorderRadius.circular(4),
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
                    id: IDGen.generateUuid(),
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
        return Colors.blue;
      case 'dating':
        return Colors.pink;
      case 'family':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
