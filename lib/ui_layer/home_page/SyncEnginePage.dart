import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/DocumentationBlock.dart';
import 'package:ice_gate/ui_layer/projects_page/google_drive_folder_picker_page.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SnowfallOverlay.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/utils/l10n_extensions.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';

class SyncEnginePage extends StatefulWidget {
  const SyncEnginePage({super.key});

  @override
  State<SyncEnginePage> createState() => _SyncEnginePageState();
}

class _SyncEnginePageState extends State<SyncEnginePage> {
  final DocumentationBlock docBlock = DocumentationBlock(); // This should be a singleton ideally, check instantiation
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uptime = docBlock.uptimeSeconds.watch(context);
    final health = docBlock.systemHealth.watch(context);
    final history = docBlock.syncHistory.watch(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                    Color(0xFF020617),
                  ],
                ),
              ),
            ),
          ),

          // Snowfall Effect
          const SnowfallOverlay(opacity: 0.1),

          // Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, l10n, health),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildMetricsGrid(context, l10n, uptime, health),
                        const SizedBox(height: 24),
                        _buildPrimaryActions(context, l10n),
                        const SizedBox(height: 16),
                        _buildAdvancedActions(context, l10n),
                        const SizedBox(height: 32),
                        _buildActivityLog(context, l10n, history),
                        const SizedBox(height: 100), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildBottomNav(context, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, double health) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.sync_engine_title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: health > 90 ? Colors.greenAccent : Colors.orangeAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (health > 90 ? Colors.greenAccent : Colors.orangeAccent).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    health > 90 ? "ALL SYSTEMS OPERATIONAL" : "DEGRADED PERFORMANCE",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.hub_outlined, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, AppLocalizations l10n, int uptime, double health) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildGlassCard(
          l10n.system_health,
          "${health.toStringAsFixed(1)}%",
          subtitle: "+0.2% improvement",
          icon: Icons.favorite_border,
          accentColor: Colors.blueAccent,
        ),
        _buildGlassCard(
          l10n.uptime,
          _formatUptime(uptime),
          subtitle: "Since last restart",
          icon: Icons.timer_outlined,
          accentColor: Colors.purpleAccent,
        ),
        _buildGlassCard(
          l10n.sync_method,
          docBlock.syncMethod.value,
          subtitle: "Bidirectional",
          icon: Icons.sync_alt,
          accentColor: Colors.orangeAccent,
        ),
        _buildGlassCard(
          l10n.refresh_rate,
          "${docBlock.refreshRate.value.inMinutes}m",
          subtitle: "Real-time Priority",
          icon: Icons.refresh,
          accentColor: Colors.greenAccent,
        ),
      ],
    );
  }

  Widget _buildGlassCard(String title, String value, {required String subtitle, required IconData icon, required Color accentColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Icon(icon, color: accentColor.withValues(alpha: 0.5), size: 14),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            l10n.initialize_drive,
            Icons.cloud_upload_outlined,
            const Color(0xFF3B82F6),
            () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => FractionallySizedBox(
                  heightFactor: 0.85,
                  child: GoogleDriveFolderPickerPage(
                    onFolderSelected: (id, name) async {
                      Navigator.pop(ctx);
                      docBlock.obsidianFolderName.value = name;
                      await docBlock.syncWithGoogleDrive();
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            l10n.test_connection,
            Icons.bolt,
            const Color(0xFF8B5CF6),
            () {}, // Test Connection Logic
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            "MAINTENANCE & REPAIR",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        _buildActionButton(
          "REPAIR DATA BUCKET",
          Icons.rebase_edit,
          Colors.orangeAccent,
          () async {
            // Show confirmation dialog
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                title: const Text("Repair Local Data?", style: TextStyle(color: Colors.white)),
                content: const Text(
                  "This will scan your local database and re-associate orphaned records with your current account and the correct tenant bucket. This can resolve 'Checkpoints' or 'Missing Records' issues.",
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("REPAIR", style: TextStyle(color: Colors.orangeAccent)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              // Trigger repair logic
              try {
                final authBlock = Provider.of<AuthBlock>(context, listen: false);
                await authBlock.repairTenantBucket();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Repair complete. Please wait for sync to finish.")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Repair failed: $e")),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog(BuildContext context, AppLocalizations l10n, List<Map<String, dynamic>> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recent_activity,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.live_logs,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (history.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                "NO RECENT ACTIVITY",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11, letterSpacing: 2),
              ),
            ),
          )
        else
          ...history.map((item) => _buildLogEntry(item)),
      ],
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> item) {
    final title = item['title'] as String;
    final details = item['details'] as String?;
    final timestamp = item['timestamp'] as DateTime;
    final isError = item['isError'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: isError ? Colors.redAccent : Colors.blueAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm:ss').format(timestamp),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (details != null)
                  Text(
                    details,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.storage_outlined, "Drives"),
              _buildNavItem(1, Icons.auto_awesome_mosaic_outlined, "Notion"),
              _buildNavItem(2, Icons.history, "History"),
              _buildNavItem(3, Icons.settings_outlined, "Settings"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white24,
              size: 20,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatUptime(int seconds) {
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}H ${twoDigits(d.inMinutes.remainder(60))}M";
    }
    return "${twoDigits(d.inMinutes)}M ${twoDigits(d.inSeconds.remainder(60))}S";
  }
}
