import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ChallengeBlock.dart';
import 'package:ice_gate/data_layer/Protocol/Social/SocialBlockProtocol.dart';

class ChallengeDialog extends StatefulWidget {
  final ChallengeBlock challengeBlock;
  final VoidCallback onSuccess;

  const ChallengeDialog({
    super.key,
    required this.challengeBlock,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context,
    ChallengeBlock block,
    VoidCallback onSuccess,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChallengeDialog(
        challengeBlock: block,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<ChallengeDialog> {
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final success = widget.challengeBlock.verify(_inputController.text);
    if (success) {
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      _inputController.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final challenge = widget.challengeBlock.activeChallenge.watch(context);
    final error = widget.challengeBlock.error.watch(context);

    if (challenge == null) {
      // Should not happen if dialog is shown correctly
      return const SizedBox.shrink();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: challenge.level.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    challenge.type.icon,
                    color: challenge.level.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Anti-Slack Challenge",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        "${challenge.level.name} Difficulty",
                        style: TextStyle(
                          fontSize: 12,
                          color: challenge.level.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    widget.challengeBlock.cancel();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Question Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    challenge.question,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (challenge.type == ChallengeType.math)
                    Text(
                      challenge.question, // Real question is the math expression
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else if (challenge.phrase != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Text(
                        challenge.phrase!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Input Section
            TextField(
              controller: _inputController,
              focusNode: _focusNode,
              onSubmitted: (_) => _handleSubmit(),
              keyboardType:
                  challenge.type == ChallengeType.math
                      ? TextInputType.number
                      : TextInputType.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText:
                    challenge.type == ChallengeType.math
                        ? "Enter answer"
                        : "Type phrase exactly",
                errorText: error,
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),

            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: challenge.level.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Verify & Unlock",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Complete the challenge to disable the block",
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
