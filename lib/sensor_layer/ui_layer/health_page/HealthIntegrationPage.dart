import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/AppleHealthServices.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/HuaweiCloudService.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/AnalysisCharts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HealthIntegrationPage extends StatefulWidget {
  const HealthIntegrationPage({super.key});

  @override
  State<HealthIntegrationPage> createState() => _HealthIntegrationPageState();
}

class _HealthIntegrationPageState extends State<HealthIntegrationPage> {
  final _searchController = TextEditingController();
  final _huaweiIdController = TextEditingController();
  final _huaweiSecretController = TextEditingController();
  bool _isHuaweiConnected = false;
  DateTime? _huaweiLastSync;
  bool _isHuaweiConnecting = false;
  bool _showDeveloperSettings = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    final connected = await HuaweiCloudService.isConnected();
    final lastSync = await HuaweiCloudService.getLastSync();
    final keys = await HuaweiCloudService.getKeys();
    
    setState(() {
      _isHuaweiConnected = connected;
      _huaweiLastSync = lastSync;
      _huaweiIdController.text = keys['id'] ?? "";
      _huaweiSecretController.text = keys['secret'] ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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

          // Decorative Blur Orbs
          Positioned(
            top: -100,
            right: -100,
            child: _buildBlurOrb(colorScheme.primary.withValues(alpha: 0.15), 400),
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: _buildBlurOrb(colorScheme.secondary.withValues(alpha: 0.1), 500),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 56)),
                _buildHeader(context, colorScheme),
                _buildSearchAndFilter(colorScheme),
                _buildCategoryHeader("NATIVE ECOSYSTEM", colorScheme),
                _buildNativeSection(colorScheme),
                _buildCategoryHeader("TRENDS · 7 DAYS", colorScheme),
                _buildDataStreamsSection(colorScheme),
                _buildCategoryHeader("DEVICE SOURCE HUB", colorScheme),
                _buildDeviceSourceSection(colorScheme),
                _buildCategoryHeader("CLOUD PIPELINES", colorScheme),
                _buildCloudSection(colorScheme),
                _buildCategoryHeader("HARDWARE & SENSORS", colorScheme),
                _buildSensorSection(colorScheme),
                _buildCategoryHeader("DIY & IoT PIPELINES", colorScheme),
                _buildIoTSection(colorScheme),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),

          // Bottom Glow Line
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    colorScheme.primary.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hub_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "UPLINK ACTIVE",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Sensor Hub",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
            Text(
              "Connect hardware, wearables and IoT streams",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              icon: Icon(
                Icons.search_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 20,
              ),
              hintText: "Search for a device or sensor...",
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 14,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Divider(
                color: Colors.white.withValues(alpha: 0.05),
                thickness: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNativeSection(ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildIntegrationCard(
            name: "Apple Health",
            description: "Sync steps, sleep, heart rate and weight",
            icon: Icons.favorite_rounded,
            color: Colors.redAccent,
            status: "Connected",
            onTap: () async {
              final authorized = await HealthService.requestPermissions();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      authorized
                          ? "HealthKit Access Granted"
                          : "HealthKit Access Denied",
                    ),
                    backgroundColor: authorized ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _buildIntegrationCard(
            name: "Google Fit",
            description: "Cross-platform health sync",
            icon: Icons.fitbit_rounded,
            color: Colors.blueAccent,
            status: "Tap to Connect",
            onTap: () {},
          ),
        ]),
      ),
    );
  }

  Widget _buildDataStreamsSection(ColorScheme colorScheme) {
    final personId = context.watch<AuthBlock>().user.value?['id'] as String?;
    final dao = context.watch<HealthMetricsDAO>();

    if (personId == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverToBoxAdapter(
        child: StreamBuilder<List<HealthMetricsLocal>>(
          stream: dao.watchAllMetrics(personId),
          builder: (context, snapshot) {
            final series = _metricsLast7(snapshot.data ?? []);
            final steps = series.map((m) => m.steps?.toDouble()).toList();
            final hr = series.map((m) => m.heartRate?.toDouble()).toList();
            final sleep = series.map((m) => m.sleepHours).toList();

            return SizedBox(
              height: 118,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildStreamMiniCard(
                      'Steps',
                      'LIVE',
                      Colors.greenAccent,
                      steps,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStreamMiniCard(
                      'Heart',
                      'LIVE',
                      Colors.redAccent,
                      hr,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStreamMiniCard(
                      'Sleep',
                      'LIVE',
                      Colors.purpleAccent,
                      sleep,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Last 7 calendar rows by [date], oldest → newest (sparkline left→right).
  List<HealthMetricsLocal> _metricsLast7(List<HealthMetricsLocal> all) {
    if (all.isEmpty) return [];
    final sorted = [...all]..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.length <= 7) return sorted;
    return sorted.sublist(sorted.length - 7);
  }

  Widget _buildStreamMiniCard(
    String label,
    String status,
    Color color,
    List<double?> series,
  ) {
    final chartData =
        series.isEmpty || series.every((e) => e == null) ? <double?>[0] : series;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SimpleLineChart(
                data: chartData,
                color: color,
                height: 44,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSourceSection(ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildDeviceSourceCard(
            "Apple Health",
            "Native Bridge",
            Colors.white,
            true,
          ),
          const SizedBox(height: 12),
          _buildDeviceSourceCard(
            "realme Link (GT6)",
            "Synced via HealthKit",
            Colors.blueAccent,
            true,
          ),
          const SizedBox(height: 12),
          _buildDeviceSourceCard(
            "Manual Input",
            "User Defined",
            Colors.grey,
            false,
          ),
        ]),
      ),
    );
  }

  Widget _buildDeviceSourceCard(
    String name,
    String type,
    Color color,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isActive ? Icons.developer_board_rounded : Icons.create_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "ACTIVE",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCloudSection(ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildIntegrationCard(
            name: "Huawei Cloud",
            description: _isHuaweiConnected 
                ? "Last sync: ${_huaweiLastSync != null ? DateFormat('HH:mm').format(_huaweiLastSync!) : 'Just now'}"
                : "Direct sync for GT6/Huawei Watch",
            icon: Icons.cloud_sync_rounded,
            color: Colors.red,
            status: _isHuaweiConnected ? "Connected" : "Not Linked",
            onTap: () => _showHuaweiConnectionSheet(colorScheme),
          ),
        ]),
      ),
    );
  }

  void _showHuaweiConnectionSheet(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.cloud_sync_rounded, color: Colors.red, size: 32),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Huawei Health Kit",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                "Synchronize high-fidelity sleep and heart rate data directly from Huawei Cloud servers.",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              
              // Developer Settings Toggle
              InkWell(
                onTap: () => setSheetState(() => _showDeveloperSettings = !_showDeveloperSettings),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.terminal_rounded, size: 14, color: _showDeveloperSettings ? Colors.red : Colors.white24),
                      const SizedBox(width: 8),
                      Text(
                        "DEVELOPER CONFIGURATION",
                        style: TextStyle(
                          color: _showDeveloperSettings ? Colors.red : Colors.white24, 
                          fontSize: 10, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 1
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _showDeveloperSettings ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.white24,
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_showDeveloperSettings) ...[
                const SizedBox(height: 16),
                _buildKeyField("CLIENT ID", _huaweiIdController, "Enter Huawei Client ID"),
                const SizedBox(height: 12),
                _buildKeyField("CLIENT SECRET", _huaweiSecretController, "Enter Huawei Client Secret", isPassword: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      await HuaweiCloudService.saveKeys(
                        _huaweiIdController.text,
                        _huaweiSecretController.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Credentials Saved Locally"))
                      );
                    },
                    child: const Text("SAVE CREDENTIALS", style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              if (_isHuaweiConnected) ...[
                 _buildConnectionInfo("Connection Status", "ACTIVE / ENCRYPTED", Colors.greenAccent),
                 const SizedBox(height: 16),
                 _buildConnectionInfo("Data Pipeline", "REST / OAUTH2", Colors.blueAccent),
                 const SizedBox(height: 40),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.white.withValues(alpha: 0.05),
                       padding: const EdgeInsets.all(18),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     ),
                     onPressed: () async {
                       await HuaweiCloudService.disconnect();
                       await _loadStates();
                       if (mounted) Navigator.pop(context);
                     },
                     child: const Text("TERMINATE CONNECTION", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                   ),
                 ),
              ] else ...[
                const Text(
                  "ESTABLISH UPLINK",
                  style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isHuaweiConnecting ? null : () async {
                      setSheetState(() => _isHuaweiConnecting = true);
                      await HuaweiCloudService.connect();
                      await _loadStates();
                      if (mounted) Navigator.pop(context);
                    },
                    child: _isHuaweiConnecting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("SIGN IN WITH HUAWEI ID", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionInfo(String label, String value, Color color) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
        const Spacer(),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildKeyField(String label, TextEditingController controller, String hint, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorSection(ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildListDelegate([
          _buildSensorGridCard(
            name: AppLocalizations.of(context)!.health_smart_scale_title,
            brand: "Health / Health Connect",
            icon: Icons.monitor_weight_rounded,
            color: Colors.purpleAccent,
            onTap: () async {
              final healthBlock = context.read<HealthBlock>();
              final l10n = AppLocalizations.of(context)!;
              final authorized = await HealthService.requestPermissions();
              if (!mounted) return;
              if (!authorized) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.health_smart_scale_sync_denied)),
                );
                return;
              }
              final weight = await healthBlock.syncFromSmartScale();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    weight > 0
                        ? l10n.health_smart_scale_sync_ok
                        : l10n.health_smart_scale_sync_empty,
                  ),
                ),
              );
              if (weight > 0) context.push('/health/weight');
            },
          ),
          _buildSensorGridCard(
            name: "Smart Watch",
            brand: "Apple/Garmin",
            icon: Icons.watch_rounded,
            color: Colors.cyanAccent,
            onTap: () {},
          ),
          _buildSensorGridCard(
            name: "Smart Ring",
            brand: "Oura/Helio",
            icon: Icons.album_outlined,
            color: Colors.deepPurpleAccent,
            onTap: () {},
          ),
          _buildSensorGridCard(
            name: "Chest Strap",
            brand: "Polar H10",
            icon: Icons.monitor_heart_rounded,
            color: Colors.orangeAccent,
            onTap: () {},
          ),
          _buildSensorGridCard(
            name: "Add Device",
            brand: "Bluetooth/ANT+",
            icon: Icons.add_rounded,
            color: Colors.white.withValues(alpha: 0.5),
            isPlaceholder: true,
            onTap: () {},
          ),
        ]),
      ),
    );
  }

  Widget _buildIoTSection(ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildIoTCard(
            name: "ESP32 Controller",
            protocol: "MQTT / WebSockets",
            id: "esp32-node-01",
            color: Colors.tealAccent,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildIoTCard(
            name: "STM32 Nucleo",
            protocol: "Serial / BLE",
            id: "stm32-pulse-v2",
            color: Colors.blue,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildIoTCard(
            name: "Arduino Nano",
            protocol: "HID / Serial",
            id: "arduino-temp-04",
            color: Colors.lightBlueAccent,
            onTap: () {},
          ),
        ]),
      ),
    );
  }

  Widget _buildIntegrationCard({
    required String name,
    required String description,
    required IconData icon,
    required Color color,
    required String status,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: status == "Connected"
                    ? Colors.greenAccent
                    : Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGridCard({
    required String name,
    required String brand,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isPlaceholder = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isPlaceholder ? 0.01 : 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: isPlaceholder ? 0.02 : 0.05),
          ),
          gradient: isPlaceholder
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.05), Colors.transparent],
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            Text(
              brand,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIoTCard({
    required String name,
    required String protocol,
    required String id,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      protocol,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              id,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
