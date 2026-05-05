import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:hevy_app/app/router.dart';
import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import 'package:hevy_app/features/history/presentation/providers/history_providers.dart';
import 'package:hevy_app/features/history/presentation/screens/workout_detail_screen.dart';
import 'package:hevy_app/features/routines/presentation/providers/routine_providers.dart';
import 'package:hevy_app/features/routines/presentation/screens/routine_editor_screen.dart';
import 'package:hevy_app/features/workout/presentation/providers/workout_providers.dart';
import 'package:hevy_app/features/workout/presentation/screens/active_workout_screen.dart';
import 'package:hevy_app/main.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning.';
    if (h < 17) return 'Good Afternoon.';
    return 'Good Evening.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryMuted.withValues(alpha: 0.36),
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0, 0.28, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ─── Top App Bar ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.fitness_center_rounded,
                            color: AppColors.primaryVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'HEVY',
                            style: GoogleFonts.lexend(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            DateFormat('MMM d').format(DateTime.now()),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Greeting ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: GoogleFonts.lexend(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to crush it today?',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Today's Workout Bento Card ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: routinesAsync.when(
                  data: (routines) => routines.isNotEmpty
                      ? _TodaysWorkoutCard(routine: routines.first, ref: ref)
                      : _QuickStartCard(ref: ref),
                  loading: () => _QuickStartCard(ref: ref),
                  error: (_, _) => _QuickStartCard(ref: ref),
                ),
              ),

              const SizedBox(height: 28),

              // ─── Suggested Routines ───────────────────────────
              routinesAsync.when(
                data: (routines) {
                  if (routines.isEmpty) return const SizedBox.shrink();
                  return _SuggestedRoutinesSection(routines: routines);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 28),

              // ─── Recent Activity ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Recent Activity'),
                    const SizedBox(height: 12),
                    historyAsync.when(
                      data: (workouts) {
                        if (workouts.isEmpty) {
                          return _EmptyActivityState();
                        }
                        return Column(
                          children: [
                            ...workouts
                                .take(3)
                                .map((w) => _ActivityItem(workout: w)),
                            const SizedBox(height: 4),
                            Center(
                              child: TextButton(
                                onPressed: () => context.go(AppRoutes.history),
                                child: const Text(
                                  'View All History',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ─── Today's Workout Bento Card ──────────────────────────────
class _TodaysWorkoutCard extends ConsumerWidget {
  const _TodaysWorkoutCard({required this.routine, required this.ref});
  final WorkoutTemplate routine;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final detailAsync = widgetRef.watch(routineDetailProvider(routine.id));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
            AppColors.surfaceDim,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section label
                const _SectionLabel("Today's Workout"),
                const SizedBox(height: 8),
                // Routine title
                Text(
                  routine.name,
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 16),
                // Big metrics
                detailAsync.when(
                  data: (detail) => Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Est. Time',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${detail.exercises.length * 12}',
                                  style: GoogleFonts.lexend(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryVariant,
                                    height: 1,
                                  ),
                                ),
                                TextSpan(
                                  text: ' min',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exercises',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${detail.exercises.length}',
                            style: GoogleFonts.lexend(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  loading: () => const SizedBox(height: 56),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                // Exercise chips
                detailAsync.when(
                  data: (detail) {
                    if (detail.exercises.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final shown = detail.exercises.take(2).toList();
                    final extra = detail.exercises.length - shown.length;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ...shown.map((e) => _ExerciseChip(e.exercise.name)),
                        if (extra > 0) _ExerciseChip('+$extra more'),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Full-width Start button at bottom
          InkWell(
            onTap: () => _startRoutine(context, widgetRef),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryVariant],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'START WORKOUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRoutine(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final dao = ref.read(routineDaoProvider);
    final exercises = await dao.getRoutineExercises(routine.id);
    final db = ref.read(databaseProvider);

    await ref
        .read(activeWorkoutProvider.notifier)
        .startWorkout(name: routine.name, templateId: routine.id);
    for (final re in exercises) {
      final exercise = await db.exerciseDao.getById(re.exercise.id);
      await ref
          .read(activeWorkoutProvider.notifier)
          .addExercise(
            exercise,
            supersetGroupId: re.templateExercise.supersetGroupId,
          );
      final idx = ref.read(activeWorkoutProvider)!.exercises.length - 1;
      for (int i = 1; i < re.templateExercise.targetSets; i++) {
        await ref.read(activeWorkoutProvider.notifier).addSet(idx);
      }
    }
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ActiveWorkoutScreen(),
          fullscreenDialog: true,
        ),
      );
    }
  }
}

// ─── Quick Start Card (no routines) ─────────────────────────
class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel("Quick Start"),
                const SizedBox(height: 10),
                Text(
                  'No Routine Yet',
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start an empty workout to begin logging, or create a Routine first.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              HapticFeedback.mediumImpact();
              await ref.read(activeWorkoutProvider.notifier).startWorkout();
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ActiveWorkoutScreen(),
                    fullscreenDialog: true,
                  ),
                );
              }
            },
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'START EMPTY WORKOUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Exercise Chip ───────────────────────────────────────────
class _ExerciseChip extends StatelessWidget {
  const _ExerciseChip(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Suggested Routines Horizontal Scroll ────────────────────
class _SuggestedRoutinesSection extends ConsumerWidget {
  const _SuggestedRoutinesSection({required this.routines});
  final List<WorkoutTemplate> routines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel('Suggested Routines'),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: routines.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _RoutineCard(routine: routines[index]),
          ),
        ),
      ],
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine});
  final WorkoutTemplate routine;

  static const List<Color> _iconColors = [
    AppColors.warning,
    AppColors.primary,
    AppColors.accent,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(routineDetailProvider(routine.id));
    final color = _iconColors[routine.id % _iconColors.length];

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoutineEditorScreen(routineId: routine.id),
        ),
      ),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              AppColors.surface,
              AppColors.surfaceDim,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.fitness_center_rounded, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            // Name
            Text(
              routine.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Description
            const SizedBox(height: 4),
            detailAsync.when(
              data: (d) => Text(
                d.exercises.isEmpty
                    ? 'No exercises yet'
                    : d.exercises.map((e) => e.exercise.name).join(', '),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => const SizedBox(height: 12),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const Spacer(),
            // Bottom meta
            detailAsync.when(
              data: (d) => Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${d.exercises.length * 12} min',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Activity Item with Date Square ─────────────────────────
class _ActivityItem extends ConsumerWidget {
  const _ActivityItem({required this.workout});
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workoutId: workout.id),
          ),
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
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    Text(
                      month.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    detailAsync.when(
                      data: (data) => Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 13,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            duration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.fitness_center_rounded,
                            size: 13,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatVolume(data.totalVolume, unitLabel),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(height: 14),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.surfaceHighlight,
              ),
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

class _EmptyActivityState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 40,
            color: AppColors.textTertiary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'No workouts yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Complete a workout to see it here',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
