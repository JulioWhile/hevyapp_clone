import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import '../providers/history_providers.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(workoutDetailProvider(workoutId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Detail'),
      ),
      body: detailAsync.when(
        data: (data) {
          final w = data.workout;
          final dateStr = DateFormat('EEEE, MMM d, yyyy').format(w.startedAt);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Header ──────────────────────────────
              Text(
                w.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),

              const SizedBox(height: 16),

              // ─── Stats row ───────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCol(
                      label: 'Duration',
                      value: _formatDuration(w.durationSeconds),
                      icon: Icons.timer_outlined,
                    ),
                    _StatCol(
                      label: 'Volume',
                      value: '${data.totalVolume.toStringAsFixed(0)} ${ref.watch(unitLabelProvider)}',
                      icon: Icons.fitness_center_rounded,
                    ),
                    _StatCol(
                      label: 'Sets',
                      value: '${data.totalSets}',
                      icon: Icons.format_list_numbered_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Exercises ───────────────────────────
              ...data.exercises.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.exercise.name,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Set header.
                        Row(
                          children: [
                            const SizedBox(width: 40, child: Text('SET', style: _headerStyle)),
                            Expanded(child: Text(ref.watch(unitLabelUpperProvider), style: _headerStyle, textAlign: TextAlign.center)),
                            const Expanded(child: Text('REPS', style: _headerStyle, textAlign: TextAlign.center)),
                            const SizedBox(width: 32),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Set rows.
                        ...e.sets.map((s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '${s.setNumber}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      s.weight.toStringAsFixed(1),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.textPrimary),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${s.reps}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.textPrimary),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: Icon(
                                      s.isCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      color: s.isCompleted
                                          ? AppColors.accent
                                          : AppColors.textTertiary,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  )),
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

const _headerStyle = TextStyle(
  color: AppColors.textTertiary,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

class _StatCol extends StatelessWidget {
  const _StatCol({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
