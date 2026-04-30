import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/database/daos/routine_dao.dart';
import 'package:hevy_app/features/exercises/presentation/providers/exercise_providers.dart';
import '../providers/routine_providers.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({super.key, required this.routineId});

  final int routineId;

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(routineDetailProvider(widget.routineId));

    return detailAsync.when(
      data: (detail) => Scaffold(
        appBar: AppBar(
          title: Text(detail.template.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              onPressed: () => _editName(context, detail.template.name),
            ),
          ],
        ),
        body: detail.exercises.isEmpty
            ? _EmptyState(onAdd: () => _addExercise(context))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: detail.exercises.length + 1,
                itemBuilder: (context, index) {
                  if (index == detail.exercises.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: OutlinedButton.icon(
                        onPressed: () => _addExercise(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Exercise'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    );
                  }
                  return _TemplateExerciseCard(
                    exercise: detail.exercises[index],
                    onRemove: () => _removeExercise(detail.exercises[index].templateExercise.id),
                  );
                },
              ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Future<void> _editName(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Rename Routine'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Routine name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await ref.read(routineDaoProvider).updateRoutine(widget.routineId, name: newName);
      ref.invalidate(routineDetailProvider(widget.routineId));
    }
  }

  Future<void> _addExercise(BuildContext context) async {
    if (!context.mounted) return;

    // Reset filter before showing picker.
    ref.read(exerciseFilterProvider.notifier).update((_) => const ExerciseFilter());

    final selected = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExercisePickerForRoutine(),
    );

    if (selected != null && selected.isNotEmpty) {
      final dao = ref.read(routineDaoProvider);
      final detail = await ref.read(routineDetailProvider(widget.routineId).future);
      int orderIndex = detail.exercises.length;

      for (final exerciseId in selected) {
        await dao.addExerciseToRoutine(
          templateId: widget.routineId,
          exerciseId: exerciseId,
          orderIndex: orderIndex++,
        );
      }
      ref.invalidate(routineDetailProvider(widget.routineId));
    }
  }

  Future<void> _removeExercise(int templateExerciseId) async {
    await ref.read(routineDaoProvider).removeExerciseFromRoutine(templateExerciseId);
    ref.invalidate(routineDetailProvider(widget.routineId));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Add exercises to this routine', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }
}

class _TemplateExerciseCard extends StatelessWidget {
  const _TemplateExerciseCard({required this.exercise, required this.onRemove});

  final RoutineExerciseWithDetails exercise;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final te = exercise.templateExercise;
    final ex = exercise.exercise;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          ex.name,
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${te.targetSets} sets × ${te.targetReps} reps',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 20),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

/// Simplified exercise picker for routines (returns list of selected exercise IDs).
class _ExercisePickerForRoutine extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ExercisePickerForRoutine> createState() => _ExercisePickerForRoutineState();
}

class _ExercisePickerForRoutineState extends ConsumerState<_ExercisePickerForRoutine> {
  final _searchController = TextEditingController();
  final Set<int> _selectedIds = {};

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
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Expanded(child: Text('Add Exercise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                if (_selectedIds.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selectedIds.toList()),
                    child: Text('Add (${_selectedIds.length})'),
                  ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Search exercises...', prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary)),
              onChanged: (value) {
                ref.read(exerciseFilterProvider.notifier).update((state) => state.copyWith(query: value));
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) => ListView.builder(
                itemCount: exercises.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final ex = exercises[index];
                  final isSelected = _selectedIds.contains(ex.id);
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36, alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20)
                          : const Icon(Icons.fitness_center_rounded, color: AppColors.textTertiary, size: 18),
                    ),
                    title: Text(ex.name, style: TextStyle(fontSize: 14, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                    subtitle: Text('${_cap(ex.primaryMuscleGroup)} · ${_cap(ex.equipment)}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () => setState(() => isSelected ? _selectedIds.remove(ex.id) : _selectedIds.add(ex.id)),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          if (_selectedIds.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedIds.toList()),
                    child: Text('Add ${_selectedIds.length} Exercise${_selectedIds.length > 1 ? 's' : ''}'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
