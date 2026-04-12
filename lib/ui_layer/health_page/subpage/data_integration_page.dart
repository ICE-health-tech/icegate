import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DataIntegrationPage extends StatefulWidget {
  const DataIntegrationPage({super.key});

  @override
  State<DataIntegrationPage> createState() => _DataIntegrationPageState();
}

class _DataIntegrationPageState extends State<DataIntegrationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pipelineController;
  bool _isSshStreaming = false;
  final List<String> _sshLogs = [];
  Timer? _logTimer;
  final ScrollController _terminalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pipelineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pipelineController.dispose();
    _logTimer?.cancel();
    _terminalScrollController.dispose();
    super.dispose();
  }

  void _toggleSshStream() {
    setState(() {
      _isSshStreaming = !_isSshStreaming;
      if (_isSshStreaming) {
        _startLogSimulation();
      } else {
        _logTimer?.cancel();
      }
    });
  }

  void _startLogSimulation() {
    _sshLogs.clear();
    _sshLogs.add("[SYSTEM] Initializing SSH tunnel to remote host...");
    _sshLogs.add("[SSH] Connecting to root@192.168.1.100:22...");
    _sshLogs.add("[SSH] Authentication successful (RSA key).");
    _sshLogs.add("[SYSTEM] Starting remote data stream...");
    
    _logTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          final timestamp = DateTime.now().toString().split(' ').last;
          final value = (math.Random().nextDouble() * 100).toStringAsFixed(3);
          _sshLogs.add("[$timestamp] DATA IN: sensor_payload=$value unit=mV");
          if (_sshLogs.length > 50) _sshLogs.removeAt(0);
        });
        
        // Auto-scroll terminal
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_terminalScrollController.hasClients) {
            _terminalScrollController.animateTo(
              _terminalScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background Glows
          _AmbientGlow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            offset: const Offset(-100, -100),
            size: 300,
          ),
          _AmbientGlow(
            color: colorScheme.secondary.withValues(alpha: 0.1),
            offset: const Offset(200, 400),
            size: 400,
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, colorScheme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        "Physical Sensor Pipeline",
                        Icons.sensors_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildPipelineVisualization(colorScheme),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        "Remote SSH Data Stream",
                        Icons.terminal_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildSSHConfigCard(colorScheme),
                      if (_isSshStreaming) ...[
                        const SizedBox(height: 24),
                        _buildLiveConsole(colorScheme),
                      ],
                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
        centerTitle: false,
        title: Text(
          "Data Integrations",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineVisualization(ColorScheme colorScheme) {
    return _GlassCard(
      child: Column(
        children: [
          _buildPipelineStep(
            "Physical World",
            Icons.public_rounded,
            "Environment Data",
            true,
          ),
          _buildPipelineArrow(),
          _buildPipelineStep(
            "Sensor Hub",
            Icons.developer_board_rounded,
            "Signal Conditioning",
            true,
          ),
          // Waveform Overlay
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
            child: const _RealtimeWaveform(),
          ),
          _buildPipelineArrow(),
          _buildPipelineStep(
            "Edge Processor",
            Icons.memory_rounded,
            "Stream Processing",
            false,
          ),
          _buildPipelineArrow(),
          _buildPipelineStep(
            "Ice Gate Cloud",
            Icons.cloud_done_rounded,
            "Synced & Ready",
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep(
    String label,
    IconData icon,
    String subtitle,
    bool isActive,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? activeColor.withValues(alpha: 0.15)
                      : colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isActive
                        ? activeColor
                        : colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              icon,
              color:
                  isActive
                      ? activeColor
                      : colorScheme.onSurface.withValues(alpha: 0.2),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color:
                      isActive
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      isActive
                          ? colorScheme.onSurface.withValues(alpha: 0.6)
                          : colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isActive)
            _PulseDot(color: colorScheme.primary)
          else
            Icon(
              Icons.lock_clock_rounded,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
        ],
      ),
    );
  }

  Widget _buildPipelineArrow() {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _pipelineController,
      builder: (context, child) {
        return Container(
          height: 30,
          margin: const EdgeInsets.only(left: 35),
          child: CustomPaint(
            painter: _ArrowPainter(
              progress: _pipelineController.value,
              color: colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSSHConfigCard(ColorScheme colorScheme) {
    return _GlassCard(
      child: Column(
        children: [
          _buildTextField("Remote Host", "e.g. 192.168.1.100", Icons.dns_rounded),
          _buildTextField("Port", "22", Icons.numbers_rounded),
          _buildTextField("Username", "root", Icons.person_rounded),
          _buildTextField("Private Key Path", "/path/to/key", Icons.key_rounded),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSshStreaming
                    ? Colors.redAccent.withValues(alpha: 0.1)
                    : colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: _isSshStreaming ? Colors.redAccent : colorScheme.primary,
                side: BorderSide(
                  color: _isSshStreaming
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : colorScheme.primary.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _toggleSshStream,
              icon: Icon(_isSshStreaming ? Icons.stop_rounded : Icons.bolt_rounded, size: 20),
              label: Text(
                _isSshStreaming ? "TERMINATE STREAM" : "INITIALIZE REMOTE STREAM",
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLiveConsole(ColorScheme colorScheme) {
    return _GlassCard(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "LIVE TERMINAL LOGS",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 1.0,
              ),
            ),
            const _PulseDot(color: Colors.greenAccent),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            controller: _terminalScrollController,
            itemCount: _sshLogs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  _sshLogs[index],
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ));
  }

  Widget _buildTextField(String label, String hint, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
          hintText: hint,
          hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.2)),
          prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

class _RealtimeWaveform extends StatefulWidget {
  const _RealtimeWaveform();

  @override
  State<_RealtimeWaveform> createState() => _RealtimeWaveformState();
}

class _RealtimeWaveformState extends State<_RealtimeWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 2),
        )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _WaveformPainter(
            progress: _controller.value,
            color: colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final midY = size.height / 2;
    
    path.moveTo(0, midY);

    for (double i = 0; i < size.width; i++) {
        final x = i;
        final y = midY + 
            math.sin((i / size.width * 2 * math.pi) + (progress * 2 * math.pi)) * 20 * math.sin(progress * math.pi);
        path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // Dynamic spikes
    final spikePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < 10; i++) {
        final x = (size.width / 10) * i + (progress * 50) % (size.width / 10);
        final height = 10 + 15 * math.sin(progress * 2 * math.pi + i);
        canvas.drawLine(
          Offset(x, midY - height),
          Offset(x, midY + height),
          spikePaint,
        );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) => true;
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final Offset offset;
  final double size;

  const _AmbientGlow({
    required this.color,
    required this.offset,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size / 2,
              spreadRadius: size / 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.3 + (_controller.value * 0.7)),
            boxShadow: [
              BoxShadow(
                color: widget.color,
                blurRadius: 4 * _controller.value,
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ArrowPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height);
    
    canvas.drawPath(path, paint);

    // Active particle
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final particleY = size.height * progress;
    canvas.drawCircle(Offset(0, particleY), 3, activePaint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.progress != progress;
}
