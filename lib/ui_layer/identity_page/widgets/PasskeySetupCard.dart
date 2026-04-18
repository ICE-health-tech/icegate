import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/ui_layer/animation_page/components/entry_constants.dart';
import 'package:provider/provider.dart';

class PasskeySetupCard extends StatelessWidget {
  const PasskeySetupCard({super.key});

  @override
  Widget build(BuildContext context) {
    final authBlock = context.watch<AuthBlock>();
    
    // Don't show if not logged in
    if (authBlock.status.value != AuthStatus.authenticated) {
      return const SizedBox.shrink();
    }

    final isEnrolled = authBlock.isPasskeyEnrolled.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EntryColors.arcticSilver.withValues(alpha: 0.1),
            EntryColors.midSilver.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: EntryColors.glassBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle backdrop icon
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.fingerprint_rounded,
                size: 120,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEnrolled) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "IDENTITY SECURED",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Passkey is Active",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "This device is linked to your biometric identity. You can now use FaceID or TouchID for seamless entry.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => _handleSetup(context, authBlock),
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.green),
                      label: const Text(
                        "RE-REGISTER IDENTITY",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EntryColors.midSilver.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: EntryColors.arcticSilver,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "SECURITY UPGRADE",
                          style: TextStyle(
                            color: EntryColors.midSilver,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Switch to Passkey",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enjoy faster, passwordless logins using FaceID or TouchID. It's more secure and easier.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _handleSetup(context, authBlock),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EntryColors.midSilver,
                        foregroundColor: EntryColors.obsidianBase,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "SETUP NOW",
                            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSetup(BuildContext context, AuthBlock authBlock) async {
    final result = await authBlock.enrollPasskey(context);
    
    if (result == "success" && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Passkey enrolled successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result != "canceled" && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to enroll: $result"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    // "canceled" result is quietly ignored
  }
}
