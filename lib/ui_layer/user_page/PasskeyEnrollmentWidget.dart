import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';

class PasskeyEnrollmentWidget extends StatefulWidget {
  const PasskeyEnrollmentWidget({super.key});

  @override
  State<PasskeyEnrollmentWidget> createState() => _PasskeyEnrollmentWidgetState();
}

class _PasskeyEnrollmentWidgetState extends State<PasskeyEnrollmentWidget> {
  bool _isEnrolling = false;

  Future<void> _handleEnrollment(AuthBlock authBlock) async {
    setState(() => _isEnrolling = true);
    
    final result = await authBlock.enrollPasskey(context);
    
    if (mounted) {
      setState(() => _isEnrolling = false);
      if (result == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passkey Enrolled Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result != "canceled") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authBlock = context.watch<AuthBlock>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Watch((context) {
      if (authBlock.isPasskeyEnrolled.value) {
        return _buildEnrolledStatus(colorScheme, textTheme);
      }

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSecurityIcon(colorScheme),
            const SizedBox(height: 20),
            Text(
              "FAST TRACK UPGRADE",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Enroll this device as a Passkey to bypass passwords entirely for your next entry. Secure, biometric, and cinematic.",
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isEnrolling ? null : () => _handleEnrollment(authBlock),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isEnrolling
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        "ENROLL PASSKEY",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSecurityIcon(ColorScheme colorScheme) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.fingerprint_rounded, size: 32, color: colorScheme.primary),
          if (_isEnrolling)
            const Positioned.fill(
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation(Colors.white24),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnrolledStatus(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Text(
            "FAST-TRACK ACTIVE",
            style: textTheme.labelLarge?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
