import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/InternalWidgetBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:provider/provider.dart';

class AddWidgetDialog extends StatefulWidget {
  const AddWidgetDialog({super.key});

  @override
  State<AddWidgetDialog> createState() => _AddWidgetDialogState();
}

class _AddWidgetDialogState extends State<AddWidgetDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  IconData _selectedIcon = Icons.language_rounded;
  int _selectedTabIndex = 0;

  // Available icons for external links
  final List<IconData> _availableIcons = [
    Icons.language_rounded,
    Icons.article_rounded,
    Icons.video_library_rounded,
    Icons.code_rounded,
    Icons.shopping_cart_rounded,
    Icons.gamepad_rounded,
    Icons.music_note_rounded,
    Icons.image_rounded,
    Icons.map_rounded,
    Icons.email_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.star_rounded,
    Icons.bookmark_rounded,
    Icons.dashboard_rounded,
    Icons.analytics_rounded,
  ];

  // All available internal routes with descriptions
  static const List<Map<String, dynamic>> _allInternalRoutes = [
    {
      'name': 'Canvas',
      'url': '/canvas',
      'alias': 'DragCanvasGrid',
      'icon': Icons.grid_view_rounded,
      'desc': 'Organize widgets freely',
    },
    {
      'name': 'Health',
      'url': '/health',
      'alias': 'HealthPage',
      'icon': Icons.favorite_rounded,
      'desc': 'Track health metrics',
    },
    {
      'name': 'Finance',
      'url': '/finance',
      'alias': 'FinancePage',
      'icon': Icons.account_balance_wallet_rounded,
      'desc': 'Monitor assets & crypto',
    },
    {
      'name': 'Social',
      'url': '/social',
      'alias': 'SocialPage',
      'icon': Icons.people_rounded,
      'desc': 'Connect with friends',
    },
    {
      'name': 'Projects',
      'url': '/projects',
      'alias': 'ProjectsPage',
      'icon': Icons.folder_special_rounded,
      'desc': 'Manage your tasks',
    },
    {
      'name': 'Profile',
      'url': '/profile',
      'alias': 'AnalysisDashboardPage',
      'icon': Icons.person_rounded,
      'desc': 'User dashboard',
    },
    {
      'name': 'Widgets',
      'url': '/widgets',
      'alias': 'WidgetPage',
      'icon': Icons.extension_rounded,
      'desc': 'Explore more widgets',
    },
    {
      'name': 'Settings',
      'url': '/settings',
      'alias': 'SettingsWidget',
      'icon': Icons.settings_rounded,
      'desc': 'App configuration',
    },
    {
      'name': 'Personal',
      'url': '/personal-info',
      'alias': 'PersonalInformationPage',
      'icon': Icons.badge_rounded,
      'desc': 'Manage personal data',
    },
    {
      'name': 'Notes',
      'url': '/project_notes',
      'alias': 'ProjectNotesPage',
      'icon': Icons.note_alt_rounded,
      'desc': 'Keep track of ideas',
    },
    {
      'name': 'Block Reminder',
      'url': '/health/block-reminder',
      'alias': 'BlockReminder',
      'icon': Icons.timer_rounded,
      'desc': '5-minute focus block',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _addInternalWidget(BuildContext context, Map<String, dynamic> route) {
    context.read<AppDatabase>().internalWidgetsDAO.insertInternalWidget(
      name: route['name'] as String,
      personID: context.read<PersonBlock>().information.value.profiles.id ?? "",
      imageUrl: '',
      url: route['url'] as String,
      alias: route['alias'] as String,
      scope: 'home',
    );
    Navigator.of(context).pop();
  }

  void _addExternalWidget(BuildContext context) {
    final name = _nameController.text.trim();
    var url = _urlController.text.trim();

    if (name.isEmpty || url.isEmpty) return;

    if (!url.startsWith('http')) {
      url = 'https://$url';
    }

    Uri? uri = Uri.tryParse(url);
    if (uri == null) return;

    final iconString = 'icon|${_selectedIcon.codePoint}';

    final protocolObj = ExternalWidgetProtocol(
      name: name,
      protocol: uri.scheme,
      host: uri.host,
      url: uri.path,
      imageUrl: iconString,
    );

    context.read<AppDatabase>().externalWidgetsDAO.insertNewWidget(
      externalWidgetProtocol: protocolObj,
      personID: context.read<PersonBlock>().information.value.profiles.id ?? "",
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final internalBlock = context.watch<InternalWidgetBlock>();
    final existingUrls = internalBlock.listInternalWidgetHomePage.value
        .map((w) => w.url)
        .toSet();

    final availableInternalRoutes = _allInternalRoutes
        .where((r) => !existingUrls.contains(r['url']))
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Add Widget",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          highlightColor: colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCustomTabs(colorScheme),
                ],
              ),
            ),

            // Content
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedTabIndex == 0
                    ? _buildPluginsGrid(
                        context,
                        availableInternalRoutes,
                        colorScheme,
                      )
                    : _buildCustomUrlForm(context, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabs(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTabItem("Plugins", Icons.grid_view_rounded, 0, colorScheme),
          _buildTabItem("Custom URL", Icons.link_rounded, 1, colorScheme),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    String label,
    IconData icon,
    int index,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPluginsGrid(
    BuildContext context,
    List<Map<String, dynamic>> routes,
    ColorScheme colorScheme,
  ) {
    if (routes.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: colorScheme.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              "All plugins added",
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0, // Square cards
        ),
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return InkWell(
            onTap: () => _addInternalWidget(context, route),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      route['icon'] as IconData,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    route['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  AutoSizeText(
                    route['desc'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 9,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomUrlForm(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      height: 450, // Fixed height for scrollable content
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Card
            Center(
              child: Container(
                width: 90,
                height: 90, // Matching HomePage item size
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _selectedIcon,
                        color: colorScheme.tertiary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _nameController.text.isEmpty
                            ? "Widget"
                            : _nameController.text,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form Fields
            _buildTextField(
              controller: _nameController,
              label: "Name",
              hint: "e.g. GitHub",
              icon: Icons.text_fields_rounded,
              colorScheme: colorScheme,
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _urlController,
              label: "URL",
              hint: "e.g. github.com",
              icon: Icons.link_rounded,
              colorScheme: colorScheme,
              isUrl: true,
            ),

            const SizedBox(height: 24),
            Text(
              "Select Icon",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // Icon Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.start,
                children: _availableIcons.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withOpacity(0.2),
                          width: isSelected ? 0 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => _addExternalWidget(context),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: colorScheme.primary.withOpacity(0.3),
                  elevation: 4,
                ),
                child: const Text(
                  "Add Widget",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    bool isUrl = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: isUrl ? TextInputType.url : TextInputType.text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        prefixIcon: Icon(icon, color: colorScheme.primary.withOpacity(0.7)),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}
