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
          onPressed: () {}, // Dating shortcut?
        ),
        SubButton(
          icon: Icons.family_restroom,
          backgroundColor: Colors.orange,
          onPressed: () {}, // Family shortcut?
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
    _tabController = TabController(length: 5, vsync: this);
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
          title: Text(
            'Social Hub',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: -0.5,
              color: colorScheme.onSurface,
            ),
          ),
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
            // Dashboard Header
            _buildDashboard(context),

            const SizedBox(height: 8),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              isScrollable: true,
              tabs: const [
                Tab(
                  text: 'Ranking',
                  icon: Icon(Icons.leaderboard_rounded, size: 20),
                ),
                Tab(
                  text: 'Friends',
                  icon: Icon(Icons.people_alt_rounded, size: 20),
                ),
                Tab(
                  text: 'Dating',
                  icon: Icon(Icons.favorite_rounded, size: 20),
                ),
                Tab(
                  text: 'Family',
                  icon: Icon(Icons.family_restroom_rounded, size: 20),
                ),
                Tab(
                  text: 'Feats',
                  icon: Icon(Icons.emoji_events_rounded, size: 20),
                ),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRankingList(context),
                  _buildContactList(context, 'friend'),
                  _buildContactList(context, 'dating'),
                  _buildContactList(context, 'family'),
                  _buildAchievementsGrid(context),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_tabController.index == 0) {
              // No add action for achievements yet
              return;
            }
            _showAddOrImportOptions(context);
          },
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
                  Text(
                    'Social Presence',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.secondary,
                      letterSpacing: 1.2,
                    ),
                  ),
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
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'TOP ALLIES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<SocialContact>>(
            stream: personDao.watchTopRankedContacts(limit: 3),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text(
                  'Start bonding to see your top allies!',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                );
              }
              final tops = snapshot.data!;
              return Row(
                children: tops.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      index == 0
                                          ? Colors.amber
                                          : (index == 1
                                                ? Colors.blueGrey
                                                : Colors.deepOrangeAccent),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: colorScheme.surface,
                                  child: Text(
                                    contact.person.firstName[0].toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            contact.person.firstName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(BuildContext context) {
    final personDao = context.watch<PersonManagementDAO>();

    return StreamBuilder<List<SocialContact>>(
      stream: personDao.watchTopRankedContacts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final contacts = snapshot.data!;

        if (contacts.isEmpty) {
          return const Center(child: Text('No rank data available.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return _buildRankingCard(context, contact, index + 1);
          },
        );
      },
    );
  }

  Widget _buildRankingCard(
    BuildContext context,
    SocialContact socialContact,
    int rank,
  ) {
    final contact = socialContact.person;
    final affection = socialContact.affection;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: SizedBox(
          width: 60,
          child: Row(
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: rank <= 3
                      ? Colors.amber
                      : colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Text(
                  contact.firstName[0].toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          "${contact.firstName} ${contact.lastName ?? ''}",
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.favorite, size: 12, color: Colors.pink),
                const SizedBox(width: 4),
                Text(
                  '$affection Relationship Pts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (affection % 100) / 100,
                backgroundColor: colorScheme.primary.withOpacity(0.05),
                color: colorScheme.primary,
                minHeight: 4,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _importContacts() async {
    // 1. Request Permission
    if (await FlutterContacts.requestPermission()) {
      if (!mounted) return;

      // 2. Fetch Contacts (with properties for phone/name)
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: true, // Allow cancelling
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        print("DEBUG: Starting minimal contact fetch...");
        // 1. Fetch ONLY names and IDs (lightweight)
        final allContacts = await FlutterContacts.getContacts(
          withProperties: false,
        );

        // Deduplicate by displayName
        final seenNames = <String>{};
        final contacts = allContacts
            .where((c) => seenNames.add(c.displayName))
            .toList();

        print(
          "DEBUG: Fetched ${allContacts.length} contacts, deduplicated to ${contacts.length}.",
        );

        if (!mounted) return;
        Navigator.pop(context); // Hide loading

        // 3. Show Selection Dialog
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Import from Contacts',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contactSummary = contacts[index];
                          final name = contactSummary.displayName;

                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                              ),
                            ),
                            title: Text(name),
                            // No phone number in summary view
                            onTap: () async {
                              Navigator.pop(context); // Close summary sheet
                              await _fetchAndConfirmContact(contactSummary.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      } catch (e, stack) {
        print("DEBUG: Error fetching contacts: $e");
        print(stack);
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading contacts: $e')));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Please enable in settings.'),
          ),
        );
      }
    }
  }

  Future<void> _fetchAndConfirmContact(String contactId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch full contact details for this specific ID
      final contact = await FlutterContacts.getContact(contactId);

      if (!mounted) return;
      Navigator.pop(context); // Hide loading

      if (contact != null) {
        _showImportConfirmation(contact);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch contact details')),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showImportConfirmation(Contact contact) {
    if (!mounted) return;

    // Split name
    String firstName = contact.name.first;
    String lastName = contact.name.last;
    if (firstName.isEmpty && contact.displayName.isNotEmpty) {
      final parts = contact.displayName.split(' ');
      firstName = parts.first;
      if (parts.length > 1) lastName = parts.sublist(1).join(' ');
    }

    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);
    String selectedType = 'friend';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Import Contact'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      items: const [
                        DropdownMenuItem(
                          value: 'friend',
                          child: Text('Friend'),
                        ),
                        DropdownMenuItem(
                          value: 'dating',
                          child: Text('Dating'),
                        ),
                        DropdownMenuItem(
                          value: 'family',
                          child: Text('Family'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedType = value!),
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (firstNameController.text.isNotEmpty) {
                      try {
                        final dao = context.read<PersonManagementDAO>();
                        await dao.createPerson(
                          PersonProtocol.create(
                            firstName: firstNameController.text,
                            lastName: lastNameController.text,
                            isActive: true,
                            personID: IDGen.generateUuid(),
                            phoneNumber: contact.phones.isNotEmpty
                                ? contact.phones.first.number
                                : null,
                          ),
                          relationship: selectedType,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact imported!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error importing: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Import'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildContactList(BuildContext context, String type) {
    final personDao = context.watch<PersonManagementDAO>();

    return StreamBuilder<List<SocialContact>>(
      stream: personDao.getContactsByRelationship(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final contacts = snapshot.data!;

        if (contacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No contacts yet',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final socialContact = contacts[index];
            final contact = socialContact.person;
            final affection = socialContact.affection;
            final affectionLevel = (affection / 100).floor();
            final progressToNext = (affection % 100) / 100;

            return GestureDetector(
              onDoubleTap: () {
                personDao.increaseAffection(contact.personID!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Affection increased with ${contact.firstName}! ❤️',
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Top row: avatar + info + actions
                      Row(
                        children: [
                          // Avatar with heart badge
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: _getRelationshipColor(
                                  type,
                                ).withOpacity(0.15),
                                child: Text(
                                  contact.firstName.isNotEmpty
                                      ? contact.firstName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: _getRelationshipColor(type),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              if (affection > 0)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.favorite,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Name + ID + relationship tag
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${contact.firstName} ${contact.lastName ?? ''}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'ID: ${contact.personID!}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRelationshipColor(
                                          type,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        type.toUpperCase(),
                                        style: TextStyle(
                                          color: _getRelationshipColor(type),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Action buttons
                          IconButton(
                            icon: const Icon(
                              Icons.favorite_border,
                              color: Colors.pink,
                              size: 20,
                            ),
                            onPressed: () {
                              personDao.increaseAffection(
                                contact.personID!,
                                amount: 5,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sent a gift! (+5 ❤️)'),
                                ),
                              );
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (value) async {
                              if (value == 'none') {
                                final bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Remove Contact'),
                                    content: Text(
                                      'Are you sure you want to remove ${contact.firstName}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await personDao.deletePerson(
                                    contact.personID!,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${contact.firstName} removed.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } else {
                                await personDao.updateRelationship(
                                  contact.personID ?? "",
                                  value,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Moved ${contact.firstName} to ${value.toUpperCase()}',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'friend',
                                child: Text('Move to Friends'),
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
                                value: 'none',
                                child: Text('Remove Contact'),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Affection progress bar (always visible)
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LV $affectionLevel',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progressToNext,
                                backgroundColor: Colors.grey.withOpacity(0.15),
                                color: _getRelationshipColor(type),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$affection pts',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAchievementsGrid(BuildContext context) {
    final questDao = context.watch<QuestDAO>();

    return StreamBuilder<List<QuestData>>(
      stream: questDao.watchActiveQuests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final quests = snapshot.data!;

        if (quests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text('No achievements yet. Keep growing!'),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: quests.length,
          itemBuilder: (context, index) {
            final quest = quests[index];
            final progress = (quest.currentValue / quest.targetValue).clamp(
              0.0,
              1.0,
            );

            // Map categories to icons/colors
            IconData icon = Icons.star_rounded;
            Color color = Colors.orange;

            switch (quest.category.toLowerCase()) {
              case 'health':
                icon = Icons.favorite_rounded;
                color = Colors.red;
                break;
              case 'finance':
                icon = Icons.account_balance_wallet_rounded;
                color = Colors.green;
                break;
              case 'social':
                icon = Icons.people_alt_rounded;
                color = Colors.purple;
                break;
              case 'career':
              case 'project':
                icon = Icons.rocket_launch_rounded;
                color = Colors.blue;
                break;
            }

            return _AchievementCard(
              title: quest.title,
              description: quest.description ?? '',
              icon: icon,
              color: color,
              progress: progress,
            );
          },
        );
      },
    );
  }

  Color _getRelationshipColor(String type) {
    switch (type) {
      case 'dating':
        return Colors.pink;
      case 'family':
        return Colors.orange;
      case 'friend':
      default:
        return Colors.blue;
    }
  }

  void _showAddOrImportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add_rounded),
                title: const Text('Add Manually'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddContactDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.contact_phone_rounded),
                title: const Text('Import from Contacts'),
                onTap: () {
                  Navigator.pop(context);
                  _importContacts();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    String selectedType = _getTabName(_tabController.index).toLowerCase();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Contact'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name (Optional)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      items: const [
                        DropdownMenuItem(
                          value: 'friend',
                          child: Text('Friend'),
                        ),
                        DropdownMenuItem(
                          value: 'dating',
                          child: Text('Dating'),
                        ),
                        DropdownMenuItem(
                          value: 'family',
                          child: Text('Family'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedType = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final dao = context.read<PersonManagementDAO>();
                    if (firstNameController.text.isNotEmpty) {
                      await dao.createPerson(
                        PersonProtocol.create(
                          firstName: firstNameController.text,
                          lastName: lastNameController.text,
                          isActive: true,
                          personID: IDGen.generateUuid(),
                        ),
                        relationship: selectedType,
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter at least a first name.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => setState(() {}));
  }

  String _getTabName(int index) {
    switch (index) {
      case 1:
        return 'Friend';
      case 2:
        return 'Dating';
      case 3:
        return 'Family';
      default:
        return 'Friend';
    }
  }
}

class _AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double progress;

  const _AchievementCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress >= 1.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(icon, size: 100, color: color.withOpacity(0.05)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (isCompleted)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 14,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Show achievement details
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
