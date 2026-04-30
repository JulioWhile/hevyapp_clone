import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/database/daos/workout_dao.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import 'package:hevy_app/features/workout/presentation/providers/workout_providers.dart';

final maxWeightHistoryProvider = FutureProvider.family<List<ChartDataPoint>, int>((ref, exerciseId) {
  return ref.watch(workoutDaoProvider).getMaxWeightHistory(exerciseId);
});

final volumeHistoryProvider = FutureProvider.family<List<ChartDataPoint>, int>((ref, exerciseId) {
  return ref.watch(workoutDaoProvider).getVolumeHistory(exerciseId);
});

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── Header Info ──────────────────────────
          Row(
            children: [
              _buildInfoChip(Icons.fitness_center_rounded, _capitalize(exercise.primaryMuscleGroup)),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.build_circle_outlined, _capitalize(exercise.equipment)),
            ],
          ),
          const SizedBox(height: 32),

          // ─── Max Weight Chart ─────────────────────
          Text(
            'Max Weight History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildChart(ref, exercise.id, true),
          ),
          const SizedBox(height: 40),

          // ─── Volume Chart ─────────────────────────
          Text(
            'Total Volume History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildChart(ref, exercise.id, false),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(WidgetRef ref, int exerciseId, bool isMaxWeight) {
    final asyncData = isMaxWeight 
        ? ref.watch(maxWeightHistoryProvider(exerciseId))
        : ref.watch(volumeHistoryProvider(exerciseId));
    final unitLabel = ref.watch(unitLabelProvider);

    return asyncData.when(
      data: (data) {
        if (data.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: const Text(
              'No data yet. Complete workouts to see progress.',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          );
        }

        // If only 1 point, duplicate it slightly so it draws a line
        if (data.length == 1) {
          data = [
            ChartDataPoint(date: data[0].date.subtract(const Duration(days: 1)), value: data[0].value),
            data[0],
          ];
        }

        final spots = data.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.value);
        }).toList();

        final minY = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
        final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
        
        final padding = (maxY - minY) * 0.2;
        final actualMinY = minY - padding < 0 ? 0.0 : minY - padding;
        final actualMaxY = maxY + padding;

        return Container(
          padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10, left: 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: AppColors.border, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) return const SizedBox();
                      // Only show a few labels on bottom to avoid crowding
                      if (data.length > 5 && index % (data.length ~/ 4) != 0 && index != data.length - 1) {
                        return const SizedBox();
                      }
                      final date = data[index].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          DateFormat('MMM d').format(date),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY > 0 ? (maxY / 4) : 1,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      if (value == actualMinY || value == actualMaxY) return const SizedBox();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
                        textAlign: TextAlign.right,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: actualMinY,
              maxY: actualMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: AppColors.surface,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      final date = data[touchedSpot.x.toInt()].date;
                      return LineTooltipItem(
                        '\${touchedSpot.y.toStringAsFixed(1)} $unitLabel\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        children: [
                          TextSpan(
                            text: DateFormat('MMM d, yyyy').format(date),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.normal),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: \$e', style: const TextStyle(color: AppColors.error))),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
