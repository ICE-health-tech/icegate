import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/Home/PluginProtocol.dart';
import 'package:provider/provider.dart';
import '../../data_layer/DataSources/local_database/Database.dart';
import 'PluginList/AvailablePlugins.dart';
import '../../data_layer/Protocol/Plugin/BasePluginProtocol.dart';

// --- DATA MODEL ---
class FormData {
  final String title;
  String? description;
  final String name;

  FormData({required this.title, this.description, this.name = 'Add Widget'});
}

// Simple concrete class for internal shortcuts to reuse UI logic
class _InternalPlugin extends BasePluginProtocol {
  const _InternalPlugin({
    required super.name,
    required super.url,
    required super.icon,
    required super.description,
    super.category = PluginCategory.other,
  }) : super(protocol: 'internal', host: 'app');
}

// --- MAIN WIDGET ---
class AddPluginForm extends StatefulWidget {
  final FormData data;

  const AddPluginForm({super.key, required this.data});

  @override
  State<AddPluginForm> createState() => _WidgetFormDataState();
}

class _WidgetFormDataState extends State<AddPluginForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  late ExternalWidgetsDAO externalWidgetsDAO;
  late InternalWidgetsDAO internalWidgetsDAO;

  // 0 = App Shortcuts (Internal), 1 = Web Widgets (External)
  int _selectedTab = 0;

  // Plugin selection state
  bool _isPluginMode = true; // true = plugin list, false = custom URL
  BasePluginProtocol? _selectedPlugin;

  @override
  void initState() {
    super.initState();
    externalWidgetsDAO = context.read<ExternalWidgetsDAO>();
    internalWidgetsDAO = context.read<InternalWidgetsDAO>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Map<String, String> _parseUrl(String url) {
    Uri? uri = Uri.tryParse(url);
    if (uri != null && uri.hasAuthority) {
      return {
        'protocol': uri.scheme.isNotEmpty ? uri.scheme : 'https',
        'host': uri.host.isNotEmpty ? uri.host : 'N/A',
        'url': uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : ''),
      };
    } else {
      return {'protocol': 'https', 'host': 'N/A', 'url': url};
    }
  }

  Future<void> _handleSubmit() async {
    try {
      if (_selectedTab == 0) {
        // --- INTERNAL MODE ---
        if (_selectedPlugin == null) {
          _showError("Please select an app page");
          return;
        }

        await internalWidgetsDAO.insertInternalWidget(
          
          name: _selectedPlugin!.name,
          url: _selectedPlugin!.url,
          alias: _selectedPlugin!.name.toLowerCase().replaceAll(' ', '_'),
            imageUrl: _selectedPlugin!.imageUrl ?? "assets/internalwidget/default.png",
          );
      } else {
        // --- EXTERNAL MODE ---
        if (_isPluginMode) {
          if (_selectedPlugin == null) {
            _showError("Please select a plugin");
            return;
          }

          final protocol = ExternalWidgetProtocol(
            name: _selectedPlugin!.name,
            protocol: _selectedPlugin!.protocol,
            host: _selectedPlugin!.host,
            url: _selectedPlugin!.url,
            imageUrl: _selectedPlugin!.imageUrl,
            dateAdded: DateTime.now().toIso8601String(),
          );
          await externalWidgetsDAO.insertNewWidget(
            externalWidgetProtocol: protocol,
          );
        } else {
          final String name = _nameController.text.trim();
          final String urlText = _urlController.text.trim();

          if (name.isEmpty || urlText.isEmpty) {
            _showError("Please fill in all fields");
            return;
          }

          final parsedData = _parseUrl(urlText);
          final protocol = ExternalWidgetProtocol(
            name: name,
            protocol: parsedData['protocol'] ?? "https",
            host: parsedData['host'] ?? "",
            url: parsedData['url'] ?? "",
            imageUrl: "",
            dateAdded: DateTime.now().toIso8601String(),
          );
          await externalWidgetsDAO.insertNewWidget(
            externalWidgetProtocol: protocol,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Widget added successfully")),
        );
      }
    } catch (e) {
      _showError("Error adding widget: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 6000),
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 24),
              _buildMainTabs(),
              const SizedBox(height: 24),

              if (_selectedTab == 0)
                _buildInternalGrid()
              else ...[
                _buildExternalToggle(),
                const SizedBox(height: 20),
                if (_isPluginMode)
                  _buildExternalPluginGrid()
                else
                  _buildCustomUrlForm(),
              ],

              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.data.description != null)
                Text(
                  widget.data.description!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: Colors.black),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTabButton(0, 'App Shortcut', Icons.dashboard_rounded),
          _buildTabButton(1, 'Web Widget', Icons.language_rounded),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTab = index;
          _selectedPlugin = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInternalGrid() {
    const internalShortcuts = [
      _InternalPlugin(
        name: 'Health',
        url: '/health',
        icon: Icons.favorite_rounded,
        description: 'Track activity and health metrics.',
        category: PluginCategory.fitness,
      ),
      _InternalPlugin(
        name: 'Finance',
        url: '/finance',
        icon: Icons.account_balance_wallet_rounded,
        description: 'Manage accounts and assets.',
        category: PluginCategory.finance,
      ),
      _InternalPlugin(
        name: 'Projects',
        url: '/projects',
        icon: Icons.rocket_launch_rounded,
        description: 'Organize tasks and notes.',
        category: PluginCategory.productivity,
      ),
      _InternalPlugin(
        name: 'Focus',
        url: '/health/focus',
        icon: Icons.timer_rounded,
        description: 'Immersive focus mode.',
        category: PluginCategory.productivity,
      ),
      _InternalPlugin(
        name: 'Social',
        url: '/social',
        icon: Icons.people_alt_rounded,
        description: 'View social insights.',
        category: PluginCategory.social,
      ),
      _InternalPlugin(
        name: 'Profile',
        url: '/profile',
        icon: Icons.person_rounded,
        description: 'View user achievements.',
        category: PluginCategory.other,
      ),
      _InternalPlugin(
        name: 'Notes',
        url: '/projects/editor',
        icon: Icons.edit_note_rounded,
        description: 'Quick notes capturing.',
        category: PluginCategory.productivity,
      ),
      _InternalPlugin(
        name: 'GPS Tracker',
        url: '/widgets/gps',
        icon: Icons.location_on_rounded,
        description: 'Live location tracking.',
        category: PluginCategory.other,
      ),
      _InternalPlugin(
        name: 'Settings',
        url: '/settings',
        icon: Icons.settings_rounded,
        description: 'Customize application.',
        category: PluginCategory.other,
      ),
    ];

    return _buildPluginGrid(internalShortcuts);
  }

  Widget _buildExternalToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSubToggle(true, 'Plugins', Icons.apps),
          _buildSubToggle(false, 'Custom URL', Icons.link),
        ],
      ),
    );
  }

  Widget _buildSubToggle(bool mode, String label, IconData icon) {
    final isSelected = _isPluginMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _isPluginMode = mode;
          _selectedPlugin = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExternalPluginGrid() {
    return _buildPluginGrid(AvailablePlugins.all);
  }

  Widget _buildPluginGrid(List<BasePluginProtocol> plugins) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: plugins.length,
      itemBuilder: (context, index) {
        final plugin = plugins[index];
        final isSelected = _selectedPlugin == plugin;
        final colorScheme = Theme.of(context).colorScheme;

        return GestureDetector(
          onTap: () => setState(() => _selectedPlugin = plugin),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  plugin.icon,
                  size: 24,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
                const SizedBox(height: 10),
                Text(
                  plugin.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    plugin.description,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomUrlForm() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: _inputDecoration(
            'Widget Name (e.g. Facebook)',
            Icons.label_outline,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _urlController,
          decoration: _inputDecoration('URL (e.g. facebook.com)', Icons.link),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
      ),
      child: const Text(
        "Add Widget",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
