import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_shield/ui_layer/home_page/MainButton.dart';
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
      mainFunction: () => context.go("/social"),
      onSwipeUp: () => context.go("/canvas"),
      onSwipeRight: () {
        if (Navigator.canPop(context)) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      size: size,
      icon: Icons.people_alt_rounded,
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
    _tabController = TabController(length: 4, vsync: this);
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
          toolbarHeight: 70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leadingWidth: 0,
          leading: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_rounded, size: 30),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.grid_view, size: 30),
              onPressed: () => context.go('/canvas'),
            ),
            IconButton(
              icon: const Icon(Icons.settings, size: 30),
              onPressed: () => context.go('/settings'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Level Header
            // _buildLevelHeader(context),

            // const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              tabs: const [
                Tab(text: 'Friends', icon: Icon(Icons.people_outline)),
                Tab(text: 'Dating', icon: Icon(Icons.favorite_border)),
                Tab(text: 'Family', icon: Icon(Icons.family_restroom)),
                Tab(
                  text: 'Directory',
                  icon: Icon(Icons.import_contacts_rounded),
                ),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContactList(context, 'friend'),
                  _buildContactList(context, 'dating'),
                  _buildContactList(context, 'family'),
                  _buildDirectoryList(context),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_tabController.index == 3) {
              _importContacts();
            } else {
              _showAddContactDialog(context);
            }
          },
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return Icon(
                _tabController.index == 3
                    ? Icons.contact_phone_rounded
                    : Icons.person_add_rounded,
              );
            },
          ),
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
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        print("DEBUG: Starting minimal contact fetch...");
        // 1. Fetch ONLY names and IDs (lightweight)
        final contacts = await FlutterContacts.getContacts(
          withProperties: false,
        );

        print("DEBUG: Fetched ${contacts.length} summary contacts.");

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
                      value: selectedType,
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
                            personID: IDGen.generate(),
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
                personDao.increaseAffection(contact.personID);
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
                                      'ID: ${contact.personID}',
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
                                contact.personID,
                                amount: 5,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sent a gift! (+5 ❤️)'),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 20,
                            ),
                            onPressed: () {
                              // TODO: Chat
                            },
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

  Widget _buildDirectoryList(BuildContext context) {
    final personDao = context.watch<PersonDAO>();
    final managementDao = context.read<PersonManagementDAO>();

    return StreamBuilder<List<PersonData>>(
      stream: personDao.getAllPersons(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final persons = snapshot.data!;

        if (persons.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text('No people in directory'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: persons.length,
          itemBuilder: (context, index) {
            final person = persons[index];
            final currentRelationship = person.relationship;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    person.firstName.isNotEmpty
                        ? person.firstName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text('${person.firstName} ${person.lastName ?? ''}'),
                subtitle: Text('Status: ${currentRelationship.toUpperCase()}'),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    await managementDao.updateRelationship(
                      person.personID,
                      value,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Moved ${person.firstName} to ${value.toUpperCase()}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'friend', child: Text('Friend')),
                    const PopupMenuItem(value: 'dating', child: Text('Dating')),
                    const PopupMenuItem(value: 'family', child: Text('Family')),
                    const PopupMenuItem(value: 'none', child: Text('Remove')),
                  ],
                ),
              ),
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
                      value: selectedType,
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
                          personID: IDGen.generate(),
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
      case 0:
        return 'Friend';
      case 1:
        return 'Dating';
      case 2:
        return 'Family';
      default:
        return 'Friend';
    }
  }
}
