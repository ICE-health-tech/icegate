import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class HealthIntegrationPage extends StatefulWidget {
  const HealthIntegrationPage({super.key});

  @override
  State<HealthIntegrationPage> createState() => _HealthIntegrationPageState();
}

class _HealthIntegrationPageState extends State<HealthIntegrationPage> {
  final _searchController = TextEditingController();

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
            child: _buildBlurOrb(colorScheme.primary.withOpacity(0.15), 400),
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: _buildBlurOrb(colorScheme.secondary.withOpacity(0.1), 500),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(context, colorScheme),
                _buildSearchAndFilter(colorScheme),
                _buildCategoryHeader("NATIVE ECOSYSTEM", colorScheme),
                _buildNativeSection(colorScheme),
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
                    colorScheme.primary.withOpacity(0.5),
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
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
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hub_rounded, size: 14, color: colorScheme.primary),
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
                color: Colors.white.withOpacity(0.5),
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
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              icon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 20),
              hintText: "Search for a device or sensor...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
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
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.05), thickness: 1)),
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
            description: "Sync steps, sleep and heart rate",
            icon: Icons.favorite_rounded,
            color: Colors.redAccent,
            status: "Connected",
            onTap: () {},
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
            color: Colors.white.withOpacity(0.5),
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
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(description, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
            ),
            Text(
              status.toUpperCase(),
              style: TextStyle(
                color: status == "Connected" ? Colors.greenAccent : Colors.white.withOpacity(0.3),
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
          color: Colors.white.withOpacity(isPlaceholder ? 0.01 : 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(isPlaceholder ? 0.02 : 0.05)),
          gradient: isPlaceholder ? null : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            Text(brand, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold)),
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
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                    ),
                    const SizedBox(width: 8),
                    Text(protocol, style: TextStyle(color: color.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              id,
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 10,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}
