import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/main.dart';
import 'package:hevy_app/features/workout/presentation/providers/workout_providers.dart';
import 'package:hevy_app/features/workout/presentation/screens/active_workout_screen.dart';
import '../providers/routine_providers.dart';
import 'routine_editor_screen.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── Premium Header ───────────────────────
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Routines',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  ),
                  onPressed: () => _createRoutine(context, ref),
                ),
              ),
            ],
          ),

          routinesAsync.when(
            data: (routines) {
              if (routines.isEmpty) {
                return SliverFillRemaining(child: _EmptyRoutinesState(onTap: () => _createRoutine(context, ref)));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _RoutineCard(routine: routines[index]),
                    childCount: routines.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }

  Future<void> _createRoutine(BuildContext context, WidgetRef ref) async {
    final name = await _showNameDialog(context);
    if (name == null || name.isEmpty) return;

    final dao = ref.read(routineDaoProvider);
    final routineId = await dao.createRoutine(name);

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoutineEditorScreen(routineId: routineId),
        ),
      );
    }
  }

  Future<String?> _showNameDialog(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Routine'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g., Push Day, Leg Day...',
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.surfaceHighlight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoutinesState extends StatelessWidget {
  const _EmptyRoutinesState({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat_rounded,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Build Your First Routine',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Routines let you pre-load your exercises so you can jump straight into training.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Routine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine});

  final WorkoutTemplate routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(routineDetailProvider(routine.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoutineEditorScreen(routineId: routine.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        detailAsync.when(
                          data: (detail) {
                            if (detail.exercises.isEmpty) {
                              return const Text('No exercises added', style: TextStyle(fontSize: 13, color: AppColors.textTertiary));
                            }
                            return Text(
                              '${detail.exercises.length} exercises · ${detail.exercises.map((e) => e.exercise.name).join(', ')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            );
                          },
                          loading: () => const SizedBox(height: 16),
                          error: (_, __) => const SizedBox(height: 16),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.textTertiary, size: 20),
                    color: AppColors.surfaceElevated,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RoutineEditorScreen(routineId: routine.id),
                          ),
                        );
                      } else if (value == 'duplicate') {
                        final newId = await ref.read(routineDaoProvider).duplicateRoutine(routine.id);
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RoutineEditorScreen(routineId: newId),
                            ),
                          );
                        }
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surfaceElevated,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Delete Routine?'),
                            content: Text('Are you sure you want to delete "${routine.name}"? This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref.read(routineDaoProvider).deleteRoutine(routine.id);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 18),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Start Workout Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _startFromRoutine(context, ref),
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Start Workout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startFromRoutine(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(routineDaoProvider);
    final exercises = await dao.getRoutineExercises(routine.id);
    final db = ref.read(databaseProvider);

    // Start workout from template.
    await ref.read(activeWorkoutProvider.notifier).startWorkout(
          name: routine.name,
          templateId: routine.id,
        );

    // Add each exercise from the template.
    for (final re in exercises) {
      final exercise = await db.exerciseDao.getById(re.exercise.id);
      await ref.read(activeWorkoutProvider.notifier).addExercise(exercise, supersetGroupId: re.templateExercise.supersetGroupId);

      // Add additional sets based on template target.
      final currentExerciseIndex =
          ref.read(activeWorkoutProvider)!.exercises.length - 1;
      for (int i = 1; i < re.templateExercise.targetSets; i++) {
        await ref.read(activeWorkoutProvider.notifier).addSet(currentExerciseIndex);
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
