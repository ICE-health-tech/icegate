import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/utils/L10nExtensions.dart';

class NoteManagerPage extends StatefulWidget {
  const NoteManagerPage({super.key});

  @override
  State<NoteManagerPage> createState() => _NoteManagerPageState();
}

class _NoteManagerPageState extends State<NoteManagerPage> {
  final _searchController = TextEditingController();
  final _notionSecretController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _notionSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final block = context.watch<DocumentationBlock>();
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background Aesthetic Gradients
          Positioned(
            top: -150,
            right: -100,
            child: _buildBlurCircle(colorScheme.primary.withValues(alpha: 0.12), 400),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: _buildBlurCircle(
              colorScheme.secondary.withValues(alpha: 0.08),
              350,
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Premium Integrated Header
                _buildHeader(context, colorScheme),

                // Stats Section (Active Services, Total Notes, Health)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: _buildStatsSection(context, block, colorScheme),
                  ),
                ),

                // Search & Filter Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: _buildSearchSection(context, colorScheme),
                  ),
                ),

                // Connections List Heading
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 24, 16),
                    child: Row(
                      children: [
                        Text(
                          l10n.integrations_enabled_connections,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.integrations_filters,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Active Connections List
                Watch(
                  (context) => SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildConnectionItem(
                          context: context,
                          name: l10n.integrations_internal_notes,
                          subtitle: l10n.integrations_primary_vault,
                          icon: Icons.article_rounded,
                          color: Colors.blue,
                          isConnected: true,
                          onCardTap: () => _navigateToExplorer(context),
                          onAction: () => _navigateToExplorer(context),
                          actionLabel: l10n.integrations_explore,
                        ),
                        _buildConnectionItem(
                          context: context,
                          name: l10n.integrations_google_drive,
                          subtitle: block.isGoogleDriveConnected.value
                              ? l10n.integrations_synced_cloud
                              : l10n.integrations_cloud_storage,
                          icon: Icons.add_to_drive_rounded,
                          color: Colors.green,
                          isConnected: block.isGoogleDriveConnected.value,
                          isLoading:
                              block.isSyncing.value &&
                              block.syncType.value == 'drive',
                          onCardTap: () {
                            if (block.isGoogleDriveConnected.value) {
                              _navigateToGoogleDriveExplorer(context);
                            } else {
                              block.syncWithGoogleDrive();
                            }
                          },
                          onAction: () => block.syncWithGoogleDrive(),
                          actionLabel: block.isGoogleDriveConnected.value
                              ? l10n.integrations_sync_now
                              : l10n.integrations_connect,
                        ),
                        _buildConnectionItem(
                          context: context,
                          name: l10n.integrations_notion_sync,
                          subtitle: l10n.integrations_database_pipeline,
                          icon: Icons.grid_view_rounded,
                          color: Colors.indigo,
                          isConnected: block.notionSecret.value != null,
                          isLoading:
                              block.isSyncing.value &&
                              block.syncType.value == 'notion',
                          onCardTap: () => _showNotionDialog(context, block),
                          onAction: () {
                            if (block.notionSecret.value != null) {
                              block.fetchFromNotionAuto();
                            } else {
                              _showNotionDialog(context, block);
                            }
                          },
                          actionLabel: block.notionSecret.value != null
                              ? l10n.integrations_fetch
                              : l10n.integrations_setup,
                        ),
                        _buildConnectionItem(
                          context: context,
                          name: l10n.integrations_slack_docs,
                          subtitle: l10n.integrations_shared_channels,
                          icon: Icons.forum_rounded,
                          color: Colors.orange,
                          isConnected: false,
                          onCardTap: () {},
                          onAction: () {},
                          actionLabel: l10n.integrations_notify_me,
                          isPlaceholder: true,
                        ),
                      ]),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final l10n = context.l10n;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.integrations_title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  l10n.integrations_subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showNewSourceDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    DocumentationBlock block,
    ColorScheme colorScheme,
  ) {
    return Watch((context) {
      final l10n = context.l10n;
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              l10n.integrations_active_services,
              '${block.activeConnectionsCount.value}/${block.totalServicesAvailable}',
              Icons.lan_rounded,
              colorScheme.primary,
              colorScheme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              l10n.integrations_total_notes,
              '${block.files.value.length}',
              Icons.description_rounded,
              colorScheme.secondary,
              colorScheme,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const Spacer(),
              Icon(
                Icons.north_east_rounded,
                size: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context, ColorScheme colorScheme) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          icon: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            size: 20,
          ),
          hintText: l10n.integrations_search_hint,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.3),
            fontSize: 14,
          ),
          border: InputBorder.none,
          suffixIcon: Icon(
            Icons.sort_by_alpha_rounded,
            color: colorScheme.primary,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionItem({
    required BuildContext context,
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onCardTap,
    required VoidCallback onAction,
    required String actionLabel,
    bool isConnected = false,
    bool isPlaceholder = false,
    bool isLoading = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surface,
      child: InkWell(
        onTap: isLoading ? null : onCardTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPlaceholder
                                ? Colors.grey
                                : (isConnected ? Colors.green : Colors.red),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isPlaceholder)
                ElevatedButton(
                  onPressed: isLoading ? null : onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.primary,
                    foregroundColor: isConnected
                        ? colorScheme.primary
                        : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue,
                          ),
                        )
                      : Text(
                          actionLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )
              else
                Icon(
                  Icons.lock_clock_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToExplorer(BuildContext context) {
    final block = context.read<DocumentationBlock>();
    if (block.rootDir != null) {
      context.push('/projects/documents/folder', extra: block.rootDir);
    }
  }

  void _navigateToGoogleDriveExplorer(BuildContext context) {
    final block = context.read<DocumentationBlock>();
    if (block.googleDriveRootDir != null) {
      context.push(
        '/projects/documents/folder',
        extra: block.googleDriveRootDir,
      );
    }
  }

  void _showNotionDialog(BuildContext context, DocumentationBlock block) {
    final l10n = context.l10n;
    _notionSecretController.text = block.notionSecret.value ?? '';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.integrations_notion_config_title),
        content: TextField(
          controller: _notionSecretController,
          decoration: InputDecoration(
            labelText: l10n.integrations_notion_secret_label,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              block.setNotionSecret(_notionSecretController.text);
              Navigator.pop(dialogContext);
              if (_notionSecretController.text.isNotEmpty) {
                block.fetchFromNotionAuto();
              }
            },
            child: Text(l10n.integrations_save_fetch),
          ),
        ],
      ),
    );
  }

  void _showNewSourceDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.integrations_marketplace_soon)),
    );
  }
}
