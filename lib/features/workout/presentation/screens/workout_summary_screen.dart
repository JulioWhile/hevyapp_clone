import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/database/daos/settings_dao.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import 'package:hevy_app/features/history/presentation/providers/history_providers.dart';


class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({super.key, required this.workoutId, required this.newPRs});

  final int workoutId;
  final List<NewPR> newPRs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(workoutDetailProvider(workoutId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout Complete'),
        automaticallyImplyLeading: false,
      ),
      body: detailAsync.when(
        data: (data) {
          final w = data.workout;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Celebration header ──────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: AppColors.accent, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      w.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMM d · h:mm a').format(w.startedAt),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Stats cards ─────────────────────────
              Row(
                children: [
                  Expanded(child: _StatCard(icon: Icons.timer_outlined, label: 'Duration', value: _formatDuration(w.durationSeconds))),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(icon: Icons.fitness_center_rounded, label: 'Volume', value: '${data.totalVolume.toStringAsFixed(0)} ${ref.watch(unitLabelProvider)}')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(icon: Icons.format_list_numbered_rounded, label: 'Sets', value: '${data.totalSets}')),
                ],
              ),

              // ─── New PRs ─────────────────────────────
              if (newPRs.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  '🏆 New Personal Records!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent),
                ),
                const SizedBox(height: 12),
                ...newPRs.map((pr) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded, color: AppColors.accent, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pr.exerciseName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(
                                  '${pr.displayType}: ${pr.value.toStringAsFixed(1)}${pr.previousValue != null ? ' (was ${pr.previousValue!.toStringAsFixed(1)})' : ''}',
                                  style: const TextStyle(color: AppColors.accent, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: 24),

              // ─── Exercises breakdown ─────────────────
              Text('Exercises', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...data.exercises.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.exercise.name, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(
                          e.sets.where((s) => s.isCompleted).map((s) => '${s.weight}${ref.watch(unitLabelProvider)} × ${s.reps}').join(' · '),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 24),

              // ─── Done button ─────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Done', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}
