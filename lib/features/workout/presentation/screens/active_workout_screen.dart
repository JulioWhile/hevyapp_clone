import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/constants/app_constants.dart';
import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import 'package:hevy_app/main.dart';
import '../providers/workout_providers.dart';
import '../widgets/exercise_picker_sheet.dart';
import '../widgets/set_row.dart';
import '../widgets/rest_timer_bar.dart';
import 'workout_summary_screen.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);

    if (workout == null) {
      return const Scaffold(
        body: Center(child: Text('No active workout')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldDiscard = await _showDiscardDialog(context);
          if (shouldDiscard == true && context.mounted) {
            ref.read(restTimerProvider.notifier).stop();
            ref.read(activeWorkoutProvider.notifier).discardWorkout();
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final shouldDiscard = await _showDiscardDialog(context);
              if (shouldDiscard == true && context.mounted) {
                ref.read(restTimerProvider.notifier).stop();
                ref.read(activeWorkoutProvider.notifier).discardWorkout();
                Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workout.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                _formatDuration(workout.elapsedSeconds),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () {},
            ),
          ],
        ),
        bottomNavigationBar: _StickyFooter(workout: workout, ref: ref),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Hero Header ────────────────────────────
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surfaceElevated,
                    AppColors.background,
                  ],
                ),
                border: const Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Workout Notes ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                initialValue: workout.notes,
                decoration: InputDecoration(
                  hintText: 'Add workout note...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                maxLines: null,
                textInputAction: TextInputAction.done,
                onChanged: (val) {
                  ref.read(activeWorkoutProvider.notifier).updateWorkoutNotes(val);
                },
              ),
            ),
            
            const SizedBox(height: 8),

            // ─── Exercise list ──────────────────────────
            Expanded(
              child: workout.exercises.isEmpty
                  ? _EmptyWorkoutState(ref: ref, context: context)
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: workout.exercises.length + 1,
                      itemBuilder: (context, index) {
                        if (index == workout.exercises.length) {
                          return _AddExerciseButton(ref: ref, context: context);
                        }
                        return _ExerciseCard(
                          exerciseIndex: index,
                          exercise: workout.exercises[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDiscardDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Discard Workout?'),
        content: const Text('This workout will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _StickyFooter extends StatelessWidget {
  const _StickyFooter({required this.workout, required this.ref});

  final ActiveWorkoutState workout;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, -8),
            blurRadius: 24,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ─── Rest Timer Mini ──────────────────────
          Expanded(
            child: const RestTimerBar(),
          ),
          const SizedBox(width: 16),
          // ─── Finish Button ────────────────────────
          ElevatedButton.icon(
            onPressed: workout.exercises.isEmpty
                ? null
                : () async {
                    final workoutId = workout.workoutId!;
                    ref.read(restTimerProvider.notifier).stop();
                    await ref.read(activeWorkoutProvider.notifier).finishWorkout();
                    
                    // ignore: avoid_manual_providers_as_ref
                    final db = ref.read(databaseProvider);
                    final newPRs = await db.settingsDao.checkAndRecordPRs(workoutId);
                    
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => WorkoutSummaryScreen(
                            workoutId: workoutId,
                            newPRs: newPRs,
                          ),
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.flag_rounded),
            label: const Text('Finish Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state — prompts user to add exercises.
class _EmptyWorkoutState extends StatelessWidget {
  const _EmptyWorkoutState({required this.ref, required this.context});

  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add an exercise to get started',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showExercisePicker(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }
}

/// Add exercise button at the bottom of the list.
class _AddExerciseButton extends StatelessWidget {
  const _AddExerciseButton({required this.ref, required this.context});

  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: OutlinedButton.icon(
        onPressed: () => _showExercisePicker(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Exercise'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}

/// Card for a single exercise during active workout — shows exercise name + set rows.
class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.exerciseIndex,
    required this.exercise,
  });

  final int exerciseIndex;
  final ActiveExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    final groupId = exercise.supersetGroupId;
    final isSuperset = groupId != null;

    // Determine position within the superset group.
    bool isFirstInGroup = false;
    bool isLastInGroup = false;
    bool showSupersetLabel = false;
    if (isSuperset && workout != null) {
      final exercises = workout.exercises;
      isFirstInGroup = exerciseIndex == 0 ||
          exercises[exerciseIndex - 1].supersetGroupId != groupId;
      isLastInGroup = exerciseIndex == exercises.length - 1 ||
          exercises[exerciseIndex + 1].supersetGroupId != groupId;
      showSupersetLabel = isFirstInGroup;
    }

    final borderRadius = isSuperset
        ? BorderRadius.vertical(
            top: const Radius.circular(12),
            bottom: isLastInGroup ? const Radius.circular(12) : Radius.zero,
          )
        : BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSupersetLabel)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                const Text(
                  'SUPERSET',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        Container(
          margin: isSuperset
              ? EdgeInsets.fromLTRB(12, isFirstInGroup ? 0 : 0, 12, isLastInGroup ? 4 : 0)
              : const EdgeInsets.fromLTRB(12, 8, 12, 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: borderRadius,
            border: Border.all(color: isSuperset ? AppColors.warning.withValues(alpha: 0.3) : AppColors.border, width: 0.5),
          ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Exercise header ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                if (exercise.gifUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/gifs/${exercise.gifUrl}',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                _RestTimerChip(exerciseIndex: exerciseIndex, exercise: exercise),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textTertiary, size: 20),
                  color: AppColors.surfaceElevated,
                  onSelected: (value) {
                    if (value == 'remove') {
                      ref.read(activeWorkoutProvider.notifier).removeExercise(exerciseIndex);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                          SizedBox(width: 8),
                          Text('Remove Exercise', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Exercise notes ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextFormField(
              initialValue: exercise.notes,
              decoration: InputDecoration(
                hintText: 'Add exercise note...',
                hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              maxLines: null,
              textInputAction: TextInputAction.done,
              onChanged: (val) {
                ref.read(activeWorkoutProvider.notifier).updateExerciseNotes(exerciseIndex, val);
              },
            ),
          ),

          // ─── Context Cards ────────────────────────────
          _ContextCards(exerciseId: exercise.exerciseId),
          const SizedBox(height: 8),

          // ─── Set header row ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 36, child: Text('SET', style: _headerStyle)),
                const SizedBox(width: 8),
                const Expanded(child: Text('PREVIOUS', style: _headerStyle)),
                Expanded(child: Text(ref.watch(unitLabelUpperProvider), style: _headerStyle, textAlign: TextAlign.center)),
                const SizedBox(width: 8),
                const Expanded(child: Text('REPS', style: _headerStyle, textAlign: TextAlign.center)),
                const SizedBox(width: 40),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ─── Set rows ─────────────────────────────────
          ...(() {
            int normal = 0;
            return exercise.sets.map((s) {
              if (s.setType == 'normal') return '${++normal}';
              return switch (s.setType) {
                'warmup' => 'W',
                'dropset' => 'D',
                'failure' => 'F',
                _ => '${s.setNumber}',
              };
            }).toList();
          })().asMap().entries.map((entry) {
            final setIndex = entry.key;
            final set = exercise.sets[setIndex];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 250 + setIndex * 40),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: SetRow(
                exerciseIndex: exerciseIndex,
                setIndex: setIndex,
                set: set,
                displayLabel: entry.value,
              ),
            );
          }),

          // ─── Add set button ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(activeWorkoutProvider.notifier).addSet(exerciseIndex);
                },
                icon: Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
                label: Text('Add Set', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
        ),
      ],
    );
  }
}

/// Tappable chip showing the rest timer duration for an exercise.
class _RestTimerChip extends ConsumerWidget {
  const _RestTimerChip({required this.exerciseIndex, required this.exercise});

  final int exerciseIndex;
  final ActiveExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = exercise.restTimerSeconds;
    return GestureDetector(
      onTap: () => _showRestTimerPicker(context, ref, exerciseIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: seconds != null
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.textTertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: seconds != null
                ? AppColors.primary.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 14,
              color: seconds != null ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              seconds != null ? '${seconds}s' : 'OFF',
              style: TextStyle(
                color: seconds != null ? AppColors.primary : AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showRestTimerPicker(BuildContext context, WidgetRef ref, int exerciseIndex) {
  final workout = ref.read(activeWorkoutProvider);
  final current = workout?.exercises[exerciseIndex].restTimerSeconds;

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Rest Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              leading: const Icon(Icons.timer_off_outlined, color: AppColors.textTertiary),
              title: const Text('OFF'),
              subtitle: const Text('No auto-start on set completion', style: TextStyle(fontSize: 12)),
              trailing: current == null ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () {
                ref.read(activeWorkoutProvider.notifier).updateExerciseRestTimer(exerciseIndex, null);
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            ...AppConstants.restTimerPresets.map((seconds) {
              final label = seconds >= 60 ? '${seconds ~/ 60}m' : '${seconds}s';
              return ListTile(
                leading: Icon(Icons.timer_outlined, color: AppColors.primary.withValues(alpha: 0.6)),
                title: Text('$label (${seconds}s)'),
                trailing: current == seconds ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  ref.read(activeWorkoutProvider.notifier).updateExerciseRestTimer(exerciseIndex, seconds);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    ),
  );
}

final _previousPerformanceProvider = FutureProvider.family<List<WorkoutSet>, int>((ref, exerciseId) {
  return ref.watch(workoutDaoProvider).getPreviousPerformance(exerciseId);
});

class _ContextCards extends ConsumerWidget {
  const _ContextCards({required this.exerciseId});
  final int exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_previousPerformanceProvider(exerciseId));
    final unitLabel = ref.watch(unitLabelUpperProvider);

    return asyncData.when(
      data: (sets) {
        if (sets.isEmpty) return const SizedBox.shrink();
        
        // Find best set (max weight) from previous
        final bestSet = sets.reduce((curr, next) => curr.weight > next.weight ? curr : next);
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildCard(
                icon: Icons.history_rounded,
                title: 'Last Workout',
                value: bestSet.weight.toStringAsFixed(1),
                subtitle: '$unitLabel x ${bestSet.reps}',
                isPrimary: false,
              ),
              const SizedBox(width: 8),
              _buildCard(
                icon: Icons.flag_rounded,
                title: 'Goal Today',
                value: (bestSet.weight + 2.5).toStringAsFixed(1),
                subtitle: '$unitLabel x ${bestSet.reps}',
                isPrimary: true,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard({required IconData icon, required String title, required String value, required String subtitle, required bool isPrimary}) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPrimary ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isPrimary ? AppColors.primary : AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPrimary ? AppColors.primary : AppColors.textTertiary, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(width: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  color: AppColors.textTertiary,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

void _showExercisePicker(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ExercisePickerSheet(),
  );
}
