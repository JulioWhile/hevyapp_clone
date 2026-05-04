import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';

import '../providers/profile_providers.dart';
import 'settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutCountAsync = ref.watch(workoutCountProvider);
    final prsAsync = ref.watch(allPRsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            // ─── Header ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_rounded, size: 20, color: AppColors.textSecondary),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Stats Row ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _GlassStatCard(
                    value: workoutCountAsync.when(
                      data: (c) => '$c',
                      loading: () => '-',
                      error: (_, __) => '-',
                    ),
                    label: 'Workouts',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GlassStatCard(
                    value: prsAsync.when(
                      data: (prs) => '${prs.length}',
                      loading: () => '-',
                      error: (_, __) => '-',
                    ),
                    label: 'Records',
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ─── Personal Records ─────────────────────────
            const Text(
              'PERSONAL RECORDS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            prsAsync.when(
              data: (prs) {
                if (prs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.emoji_events_rounded, size: 36, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'Complete workouts to see your PRs here.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: prs.map((prEntry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prEntry.exercise.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Best: ${prEntry.pr.value.toStringAsFixed(1)} ${ref.watch(unitLabelProvider)}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '🏆 PR',
                                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  const _GlassStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.7), size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
