import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/Social/SocialBlockProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlockerBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ChallengeBlock.dart';
import 'package:ice_gate/ui_layer/social_page/blocker/widgets/ChallengeDialog.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';

class SocialBlockerPage extends StatelessWidget {
  const SocialBlockerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final blocker = context.watch<SocialBlockerBlock>();
    final challengeBlock = context.watch<ChallengeBlock>();
    final orangeAccent = const Color(0xFFE37E63);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 60)),

          // App Blocker Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text(
                  //   "App Blocker",
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.bold,
                  //     color: colorScheme.onSurface,
                  //   ),
                  // ),
                  Watch((context) {
                    final isActive = blocker.isAnyBlockActive.watch(context);
                    if (!isActive) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: orangeAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: orangeAccent.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: orangeAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: orangeAccent.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "ACTIVE",
                            style: TextStyle(
                              color: orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSection(context, [
              Watch((context) {
                final isEnabled = blocker.isAppBlacklistEnabled.watch(context);

                return _buildTile(
                  context,
                  title: "System Shield Master",
                  subtitle: "Master switch for all app blocking rules.",
                  icon: Icons.shield_rounded,
                  color: orangeAccent,
                  trailing: Switch.adaptive(
                    value: isEnabled,
                    activeColor: orangeAccent,
                    onChanged: (val) async {
                      if (!val) {
                        // Turning OFF -> check for challenge
                        final challenge = blocker.getRequiredChallengeForMaster(
                          false,
                        );
                        if (challenge != null) {
                          challengeBlock.generateChallenge(
                            challenge.type,
                            challenge.level,
                          );
                          ChallengeDialog.show(context, challengeBlock, () {
                            blocker.toggleBlacklist(false);
                          });
                          return;
                        }
                      }
                      blocker.toggleBlacklist(val);
                    },
                  ),
                );
              }),
              _buildDivider(context),
              _buildTile(
                context,
                title: "Select Blocked Apps",
                subtitle: "Choose which apps or categories to restrict.",
                icon: Icons.apps_rounded,
                color: Colors.purple,
                onTap: () {
                  if (!blocker.isSystemAuthGranted.value) {
                    blocker.requestAuth();
                  } else {
                    blocker.openAppPicker();
                  }
                },
              ),
            ]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Schedules & Rules Section
          _buildHeader(
            context,
            "Rules",
            trailing: IconButton(
              icon: Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Challenge System"),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Challenges add friction when you try to disable a block during focus sessions or schedules.",
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 16),
                        Text("• Math: Solve equations to verify focus.",
                            style: TextStyle(fontSize: 13)),
                        Text("• Typing: Type mindfulness phrases.",
                            style: TextStyle(fontSize: 13)),
                        SizedBox(height: 16),
                        Text(
                            "Success rate tracks your discipline across sessions.",
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Got it"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Watch((context) {
            final rules = blocker.rules.watch(context);
            if (rules.isEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No specific schedules added yet",
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _showAddRuleDialog(context, blocker),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text("Create First Rule"),
                        style: TextButton.styleFrom(
                          foregroundColor: orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final rule = rules[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: () => _showAddRuleDialog(
                      context,
                      blocker,
                      existingRule: rule,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: rule.platform.icon == Icons.link_rounded
                                  ? Colors.grey.withValues(alpha: 0.1)
                                  : Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              rule.platform.icon,
                              color: Colors.blue,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rule.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rule.scheduleStart != null
                                      ? "${rule.scheduleStart!.format(context)} - ${rule.scheduleEnd!.format(context)}"
                                      : "During Focus Sessions",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (rule.challengeType != ChallengeType.none) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        rule.challengeType.icon,
                                        size: 10,
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${rule.challengeType.name} | ${rule.challengeLevel.name}",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (rule.totalChallenges > 0) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (rule.successRate > 0.8
                                                      ? Colors.green
                                                      : rule.successRate > 0.5
                                                      ? Colors.orange
                                                      : Colors.red)
                                                  .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          "${(rule.successRate * 100).toInt()}% Success Rate",
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: rule.successRate > 0.8
                                                ? Colors.green
                                                : rule.successRate > 0.5
                                                ? Colors.orange
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${rule.challengesPassed}/${rule.totalChallenges} passed",
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch.adaptive(
                                value: rule.isEnabled,
                                activeColor: orangeAccent,
                                onChanged: (val) {
                                  if (!val &&
                                      rule.challengeType !=
                                          ChallengeType.none) {
                                    final challengeBlock = context
                                        .read<ChallengeBlock>();
                                    challengeBlock.generateChallenge(
                                      rule.challengeType,
                                      rule.challengeLevel,
                                    );

                                    // Start tracking challenge attempt
                                    blocker.recordChallengeAttempt(rule.id);

                                    ChallengeDialog.show(
                                      context,
                                      challengeBlock,
                                      () {
                                        blocker.recordChallengeSuccess(rule.id);
                                        blocker.toggleRule(rule.id, false);
                                      },
                                    );
                                    return;
                                  }
                                  blocker.toggleRule(rule.id, val);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (rule.challengeType !=
                                      ChallengeType.none) {
                                    final challengeBlock =
                                        context.read<ChallengeBlock>();
                                    challengeBlock.generateChallenge(
                                      rule.challengeType,
                                      rule.challengeLevel,
                                    );

                                    // Record attempt for discipline tracking
                                    blocker.recordChallengeAttempt(rule.id);

                                    ChallengeDialog.show(
                                      context,
                                      challengeBlock,
                                      () {
                                        blocker.recordChallengeSuccess(rule.id);
                                        blocker.removeRule(rule.id);
                                      },
                                    );
                                  } else {
                                    blocker.removeRule(rule.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: rules.length),
            );
          }),

          // Add Rule Button (if not empty)
          Watch((context) {
            final rules = blocker.rules.watch(context);
            if (rules.isEmpty)
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => _showAddRuleDialog(context, blocker),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text("Add New Schedule"),
                    style: TextButton.styleFrom(foregroundColor: orangeAccent),
                  ),
                ),
              ),
            );
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Notifications Section
          _buildHeader(context, "System Notifications"),
          SliverToBoxAdapter(
            child: _buildSection(context, [
              _buildTile(
                context,
                title: "All Notifications",
                subtitle:
                    "Manage reminders, live activities, and wisdom board.",
                icon: Icons.notifications_active_rounded,
                color: Colors.blueAccent,
                onTap: () => context.push('/notifications'),
              ),
            ]),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title, {Widget? trailing}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
    );
  }

  void _showAddRuleDialog(
    BuildContext context,
    SocialBlockerBlock blocker, {
    SocialBlockRule? existingRule,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _AddRuleSheet(blocker: blocker, existingRule: existingRule),
    );
  }
}

class _AddRuleSheet extends StatefulWidget {
  final SocialBlockerBlock blocker;
  final SocialBlockRule? existingRule;
  const _AddRuleSheet({required this.blocker, this.existingRule});

  @override
  State<_AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends State<_AddRuleSheet> {
  late TextEditingController ruleNameController;
  late SocialPlatform selectedPlatform;
  late ChallengeType selectedChallengeType;
  late ChallengeLevel selectedLevel;
  late TimeOfDay startTime;
  late TimeOfDay endTime;
  late bool blockDuringFocus;
  late bool useSchedule;
  late List<int> blockedDays;

  @override
  void initState() {
    super.initState();
    final rule = widget.existingRule;
    ruleNameController = TextEditingController(text: rule?.ruleName ?? '');
    selectedPlatform = rule?.platform ?? SocialPlatform.instagram;
    selectedChallengeType = rule?.challengeType ?? ChallengeType.none;
    selectedLevel = rule?.challengeLevel ?? ChallengeLevel.normal;
    startTime = rule?.scheduleStart ?? const TimeOfDay(hour: 9, minute: 0);
    endTime = rule?.scheduleEnd ?? const TimeOfDay(hour: 17, minute: 0);
    blockDuringFocus = rule?.blockDuringFocus ?? true;
    useSchedule = rule?.scheduleStart != null;
    blockedDays = List<int>.from(rule?.blockedDays ?? [1, 2, 3, 4, 5, 6, 7]);
  }

  @override
  void dispose() {
    ruleNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const orangeAccent = Color(0xFFFF9500);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        top: 32,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingRule != null
                      ? "Edit Blocking Rule"
                      : "New Blocking Rule",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildLabel(colorScheme, "Rule Name"),
            const SizedBox(height: 12),
            TextField(
              controller: ruleNameController,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "e.g. Work Study",
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel(colorScheme, "Select Platform Icon"),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: SocialPlatform.values.length,
                itemBuilder: (context, index) {
                  final platform = SocialPlatform.values[index];
                  final isSelected = selectedPlatform == platform;
                  return GestureDetector(
                    onTap: () => setState(() => selectedPlatform = platform),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? orangeAccent.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? orangeAccent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            platform.icon,
                            size: 20,
                            color: isSelected
                                ? orangeAccent
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            platform.name,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? orangeAccent
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),
            _buildLabel(colorScheme, "Target Content"),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => widget.blocker.openAppPicker(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: orangeAccent, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: orangeAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.apps_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Choose Apps to Block",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Select categories or specific apps from iOS",
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            _buildLabel(colorScheme, "Challenge Friction"),
            const SizedBox(height: 6),
            Text(
              "Add friction to discourage disabling the block. You'll need to solve this to unlock apps.",
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: ChallengeType.values.map((type) {
                final isSelected = selectedChallengeType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedChallengeType = type),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? orangeAccent.withValues(alpha: 0.1)
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? orangeAccent : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type.icon,
                            size: 18,
                            color: isSelected ? orangeAccent : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : null,
                              color: isSelected ? orangeAccent : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (selectedChallengeType != ChallengeType.none) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  selectedChallengeType == ChallengeType.math
                      ? "Solve math equations to verify focus"
                      : "Type mindfulness phrases to slow down",
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: ChallengeLevel.values.map((level) {
                  final isSelected = selectedLevel == level;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedLevel = level),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? level.color.withValues(alpha: 0.1)
                              : colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? level.color
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            level.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : null,
                              color: isSelected ? level.color : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Level: ${selectedLevel == ChallengeLevel.easy ? "Short & simple" : selectedLevel == ChallengeLevel.normal ? "Balanced friction" : "Significant effort"}",
                  style: TextStyle(
                    fontSize: 9,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            _buildLabel(colorScheme, "Days to Block"),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = blockedDays.contains(day);
                final label = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (blockedDays.length > 1) blockedDays.remove(day);
                      } else {
                        blockedDays.add(day);
                      }
                    });
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? orangeAccent
                          : colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),
            _buildToggleOption(
              "Link to Focus Pomo",
              "Auto-block when any focus session starts",
              blockDuringFocus,
              (val) => setState(() => blockDuringFocus = val),
            ),

            const SizedBox(height: 16),

            _buildToggleOption(
              "Custom Schedule",
              "Block during specific hours every day",
              useSchedule,
              (val) => setState(() => useSchedule = val),
            ),

            if (useSchedule) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker("From", startTime, () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (time != null) setState(() => startTime = time);
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker("Until", endTime, () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (time != null) setState(() => endTime = time);
                    }),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final name = ruleNameController.text;
                  if (widget.existingRule != null) {
                    final updatedRule = widget.existingRule!.copyWith(
                      ruleName: name,
                      platform: selectedPlatform,
                      blockDuringFocus: blockDuringFocus,
                      scheduleStart: useSchedule ? startTime : null,
                      scheduleEnd: useSchedule ? endTime : null,
                      blockedDays: blockedDays,
                      challengeType: selectedChallengeType,
                      challengeLevel: selectedLevel,
                    );
                    widget.blocker.updateRule(updatedRule);
                  } else {
                    final rule = SocialBlockRule(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      ruleName: name,
                      platform: selectedPlatform,
                      blockDuringFocus: blockDuringFocus,
                      scheduleStart: useSchedule ? startTime : null,
                      scheduleEnd: useSchedule ? endTime : null,
                      blockedDays: blockedDays,
                      challengeType: selectedChallengeType,
                      challengeLevel: selectedLevel,
                      isEnabled: true,
                    );
                    widget.blocker.addRule(rule);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  widget.existingRule != null ? "Save Changes" : "Create Rule",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(ColorScheme colorScheme, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeColor: const Color(0xFFFF9500),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time.format(context),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.access_time_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
