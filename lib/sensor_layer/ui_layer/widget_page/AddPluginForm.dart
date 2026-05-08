import 'package:flutter/material.dart';

import 'package:ice_gate/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'PluginList/AvailablePlugins.dart';
import 'package:ice_gate/data_layer/Protocol/Plugin/BasePluginProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Home/PluginProtocol.dart'
    show PluginCategory;

// --- DATA MODEL ---
class FormData {
  final String title;
  String? description;
  final String name;

  FormData({required this.title, this.description, this.name = 'Add Widget'});
}

// Remove local _InternalPlugin definition

// --- MAIN WIDGET ---
class AddPluginForm extends StatefulWidget {
  final FormData data;
  final String scope;

  const AddPluginForm({super.key, required this.data, this.scope = 'home'});

  @override
  State<AddPluginForm> createState() => _WidgetFormDataState();
}

class _WidgetFormDataState extends State<AddPluginForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  late ExternalWidgetsDAO externalWidgetsDAO;
  late InternalWidgetsDAO internalWidgetsDAO;

  // 0 = App Shortcuts (Internal), 1 = Web Widgets (External)
  int _selectedTab = 0;

  // Plugin selection state
  bool _isPluginMode = true; // true = plugin list, false = custom URL
  BasePluginProtocol? _selectedPlugin;
  PluginCategory? _selectedCategory;

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
    _searchController.dispose();
    super.dispose();
  }

  List<BasePluginProtocol> _filterPlugins(List<BasePluginProtocol> plugins) {
    final query = _searchController.text.trim().toLowerCase();
    return plugins.where((p) {
      final matchesQuery = query.isEmpty
          ? true
          : (p.name.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query) ||
              p.tags.any((t) => t.toLowerCase().contains(query)));
      final matchesCategory =
          _selectedCategory == null ? true : p.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  int _gridColumnsForWidth(double w) {
    if (w >= 1100) return 6;
    if (w >= 860) return 5;
    if (w >= 680) return 4;
    return 3;
  }

  Widget _buildSearchAndFilters(List<BasePluginProtocol> plugins) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = plugins.map((p) => p.category).toSet().toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search plugins…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear_rounded),
                  ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
              ),
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(c.name),
                    selected: _selectedCategory == c,
                    onSelected: (_) => setState(() {
                      _selectedCategory = _selectedCategory == c ? null : c;
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPluginBrowser(List<BasePluginProtocol> plugins) {
    final filtered = _filterPlugins(plugins);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchAndFilters(plugins),
        const SizedBox(height: 14),
        _buildPluginGrid(filtered),
      ],
    );
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
    final l10n = AppLocalizations.of(context)!;
    try {
      if (_selectedTab == 0) {
        // --- INTERNAL MODE ---
        if (_selectedPlugin == null) {
          _showError(l10n.please_select_app_page);
          return;
        }

        // Allow multiple widgets in all scopes now that UI supports list rendering
        final personId =
            context.read<PersonBlock>().information.value.profiles.id ?? "";

        await internalWidgetsDAO.insertInternalWidget(
          personID: personId,
          name: _selectedPlugin!.name,
          url: _selectedPlugin!.url,
          alias: _selectedPlugin!.name.toLowerCase().replaceAll(' ', '_'),
          imageUrl:
              _selectedPlugin!.imageUrl ??
              "assets/internalwidget/default_plugin.png",
          scope: widget.scope,
        );
      } else {
        // --- EXTERNAL MODE ---
        if (_isPluginMode) {
          if (_selectedPlugin == null) {
            _showError(l10n.please_select_plugin);
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
            personID:
                context.read<PersonBlock>().information.value.profiles.id ?? "",
          );
        } else {
          final String name = _nameController.text.trim();
          final String urlText = _urlController.text.trim();

          if (name.isEmpty || urlText.isEmpty) {
            _showError(l10n.please_fill_all_fields);
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
            personID:
                context.read<PersonBlock>().information.value.profiles.id ?? "",
          );
        }
      }

      if (mounted) {
        // 1. Close dialog
        Navigator.of(context).pop();

        // 2. Navigate if applicable
        // if (isInternal && urlToNavigate != null) {
        //   context.push(urlToNavigate);
        // }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.widget_added_success)),
        );
      }
    } catch (e) {
      _showError(l10n.error_adding_widget(e.toString()));
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
                color: Colors.black.withValues(alpha: 0.12),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabs() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTabButton(0, l10n.app_shortcut, Icons.dashboard_rounded),
          _buildTabButton(1, l10n.web_widget, Icons.language_rounded),
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
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
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
    return _buildPluginBrowser(AvailablePlugins.internal);
  }

  Widget _buildExternalToggle() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSubToggle(true, l10n.plugins, Icons.apps),
          _buildSubToggle(false, l10n.custom_url, Icons.link),
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
                size: 14,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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
    return _buildPluginBrowser(AvailablePlugins.all);
  }

  Widget _buildPluginGrid(List<BasePluginProtocol> plugins) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridColumnsForWidth(MediaQuery.sizeOf(context).width),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.92,
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
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
                  size: 18,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
                const SizedBox(height: 8),
                Text(
                  plugin.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (plugin.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      plugin.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomUrlForm() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: _inputDecoration(
            l10n.widget_name_hint,
            Icons.label_outline,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _urlController,
          decoration: _inputDecoration(l10n.url_hint, Icons.link),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context)!;
    return ElevatedButton(
      onPressed: _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
      ),
      child: Text(
        l10n.add_widget,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
