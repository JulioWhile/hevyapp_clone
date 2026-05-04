import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import '../providers/history_providers.dart';
import 'workout_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: historyAsync.when(
          data: (workouts) {
            if (workouts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('History', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 56, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            const Text('No workouts yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const Text('Completed workouts will appear here', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group by month
            final grouped = <String, List<Workout>>{};
            for (final w in workouts) {
              final key = DateFormat('MMMM yyyy').format(w.startedAt);
              grouped.putIfAbsent(key, () => []).add(w);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                Text('History', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 20),
                ...grouped.entries.expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 10),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...entry.value.map((w) => _WorkoutHistoryItem(workout: w)),
                ]),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _WorkoutHistoryItem extends ConsumerWidget {
  const _WorkoutHistoryItem({required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitLabel = ref.watch(unitLabelProvider);
    final detailAsync = ref.watch(workoutDetailProvider(workout.id));
    final day = DateFormat('d').format(workout.startedAt);
    final month = DateFormat('MMM').format(workout.startedAt);
    final duration = _formatDuration(workout.durationSeconds);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workoutId: workout.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Date square
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(day, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary, height: 1)),
                    Text(month.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    detailAsync.when(
                      data: (data) => Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 13, color: AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Text(duration, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                          const SizedBox(width: 12),
                          Icon(Icons.fitness_center_rounded, size: 13, color: AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Text(_formatVolume(data.totalVolume, unitLabel), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        ],
                      ),
                      loading: () => const SizedBox(height: 14),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.surfaceHighlight),
            ],
          ),
        ),
      ),
    );
  }

  String _formatVolume(double vol, String unit) {
    if (vol >= 1000) return '${(vol / 1000).toStringAsFixed(1)}k $unit';
    return '${vol.toStringAsFixed(0)} $unit';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
