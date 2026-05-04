import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/app/theme/colors.dart';

import 'package:hevy_app/features/exercises/presentation/providers/exercise_providers.dart';
import 'package:hevy_app/features/exercises/presentation/screens/create_exercise_screen.dart';
import '../providers/workout_providers.dart';

/// Bottom sheet for picking exercises to add to the active workout.
class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({super.key});

  @override
  ConsumerState<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  final Set<int> _selectedIds = {};
  bool _isSuperset = false;
  static int _supersetCounter = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(filteredExercisesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ─── Handle bar ─────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ─── Header ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add Exercise',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  TextButton(
                    onPressed: _addSelected,
                    child: Text('Add (${_selectedIds.length})'),
                  ),
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
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ─── Search ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                          ref.read(exerciseFilterProvider.notifier).update(
                                (state) => state.copyWith(query: ''),
                              );
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _query = value);
                ref.read(exerciseFilterProvider.notifier).update(
                      (state) => state.copyWith(query: value),
                    );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ─── Exercise list ─────────────────────────
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Center(
                    child: Text(
                      'No exercises found',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final isSelected = _selectedIds.contains(exercise.id);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      leading: SizedBox(
                        width: 40,
                        height: 40,
                        child: exercise.gifUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/gifs/${exercise.gifUrl}',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _pickerFallback(isSelected),
                                ),
                              )
                            : _pickerFallback(isSelected),
                      ),
                      title: Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${_capitalize(exercise.primaryMuscleGroup)} · ${_capitalize(exercise.equipment)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(exercise.id);
                          } else {
                            _selectedIds.add(exercise.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),

          // ─── Add button (when selected) ────────────
          if (_selectedIds.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedIds.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 18,
                              color: _isSuperset ? AppColors.primary : AppColors.textTertiary,
                            ),
                            const SizedBox(width: 8),
                            const Text('Superset', style: TextStyle(fontSize: 14)),
                            const Spacer(),
                            Switch(
                              value: _isSuperset,
                              onChanged: (v) => setState(() => _isSuperset = v),
                              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                              activeThumbColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addSelected,
                        child: Text('Add ${_selectedIds.length} Exercise${_selectedIds.length > 1 ? 's' : ''}${_isSuperset ? ' as Superset' : ''}'),
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

  Future<void> _addSelected() async {
    final dao = ref.read(exerciseDaoProvider);
    final int? groupId = _isSuperset ? ++_supersetCounter : null;
    for (final id in _selectedIds) {
      final exercise = await dao.getById(id);
      await ref.read(activeWorkoutProvider.notifier).addExercise(exercise, supersetGroupId: groupId);
    }
    if (mounted) {
      // Reset the search filter.
      ref.read(exerciseFilterProvider.notifier).update(
            (state) => const ExerciseFilter(),
          );
      Navigator.pop(context);
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _pickerFallback(bool isSelected) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
          : const Icon(Icons.fitness_center_rounded, color: AppColors.textTertiary, size: 18),
    );
  }
}
