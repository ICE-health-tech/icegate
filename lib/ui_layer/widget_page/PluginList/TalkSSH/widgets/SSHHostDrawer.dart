import 'package:flutter/material.dart';
import '../SSHHostModel.dart';
import '../SSHStorageService.dart';

class SSHHostDrawer extends StatelessWidget {
  final SSHStorageService storageService;
  final Function(SSHHostModel) onHostSelected;

  const SSHHostDrawer({
    super.key,
    required this.storageService,
    required this.onHostSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: Colors.black,
      width: 280,
      child: Column(
        children: [
          _buildDrawerHeader(colorScheme),
          Expanded(
            child: _buildSavedHostsList(context, colorScheme),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'PROTO.V1.5',
                  style: TextStyle(
                    color: colorScheme.primary.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.primary.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Icon(Icons.terminal_rounded, color: colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            'UPLINK HUB',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'SELECT TARGET HOST',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.3),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedHostsList(BuildContext context, ColorScheme colorScheme) {
    return FutureBuilder<List<SSHHostModel>>(
      future: storageService.loadHosts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Opacity(
              opacity: 0.2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 40, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text('NO TARGETS STORED', style: TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                ],
              ),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final host = snapshot.data![index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onHostSelected(host);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.dns_outlined, color: colorScheme.primary.withOpacity(0.5), size: 18),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              host.name.toUpperCase(),
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1,
                                fontFamily: 'Courier',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${host.user}@${host.host}',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.3),
                                fontSize: 10,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 14, color: colorScheme.primary.withOpacity(0.3)),
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
}
