import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/features/exercises/presentation/screens/create_exercise_screen.dart';
import 'package:hevy_app/features/exercises/presentation/screens/exercise_detail_screen.dart';
import '../providers/exercise_providers.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(filteredExercisesProvider);
    final muscleGroupsAsync = ref.watch(muscleGroupsProvider);
    final filter = ref.watch(exerciseFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateExerciseScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ─── Search bar ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(exerciseFilterProvider.notifier).update(
                                (state) => state.copyWith(query: ''),
                              );
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(exerciseFilterProvider.notifier).update(
                      (state) => state.copyWith(query: value),
                    );
              },
            ),
          ),

          // ─── Muscle group filter chips ──────────────
          muscleGroupsAsync.when(
            data: (groups) => SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: groups.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FilterChip(
                      label: const Text('All'),
                      selected: filter.muscleGroup == null,
                      onSelected: (_) {
                        ref.read(exerciseFilterProvider.notifier).update(
                              (state) => state.copyWith(muscleGroup: () => null),
                            );
                      },
                    );
                  }
                  final group = groups[index - 1];
                  return FilterChip(
                    label: Text(_capitalize(group)),
                    selected: filter.muscleGroup == group,
                    onSelected: (_) {
                      ref.read(exerciseFilterProvider.notifier).update(
                            (state) => state.copyWith(
                              muscleGroup: () => filter.muscleGroup == group ? null : group,
                            ),
                          );
                    },
                  );
                },
              ),
            ),
            loading: () => const SizedBox(height: 42),
            error: (_, _) => const SizedBox(height: 42),
          ),

          const SizedBox(height: 8),

          // ─── Exercise list ──────────────────────────
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textTertiary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No exercises found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    return _ExerciseTile(exercise: exercises[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Individual exercise tile in the list.
class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _ExerciseThumb(exercise: exercise),
        title: Text(
          exercise.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
              ),
        ),
        subtitle: Text(
          '${_capitalize(exercise.primaryMuscleGroup)} · ${_capitalize(exercise.equipment)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textTertiary,
          size: 20,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExerciseDetailScreen(exercise: exercise),
            ),
          );
        },
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Exercise thumbnail — shows GIF if available, otherwise a colored muscle group icon.
class _ExerciseThumb extends StatelessWidget {
  const _ExerciseThumb({required this.exercise});

  final Exercise exercise;

  Color get _color => switch (exercise.primaryMuscleGroup) {
        'chest' => const Color(0xFFEF4444),
        'back' => const Color(0xFF3B82F6),
        'shoulders' => const Color(0xFFF97316),
        'biceps' => const Color(0xFF8B5CF6),
        'triceps' => const Color(0xFFA855F7),
        'forearms' => const Color(0xFF6366F1),
        'quads' => const Color(0xFF22C55E),
        'hamstrings' => const Color(0xFF14B8A6),
        'glutes' => const Color(0xFF06B6D4),
        'calves' => const Color(0xFF10B981),
        'core' => const Color(0xFFEAB308),
        'cardio' => const Color(0xFFEC4899),
        _ => AppColors.textTertiary,
      };

  @override
  Widget build(BuildContext context) {
    if (exercise.gifUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/gifs/${exercise.gifUrl}',
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.fitness_center_rounded, color: _color, size: 20),
    );
  }
}
