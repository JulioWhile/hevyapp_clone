import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static int _supersetGen = 0;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(routineDetailProvider(widget.routineId));

    return detailAsync.when(
      data: (detail) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: GestureDetector(
            onTap: () => _editName(context, detail.template.name),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    detail.template.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit_rounded, size: 16, color: AppColors.textTertiary),
              ],
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextFormField(
                initialValue: detail.template.notes,
                decoration: const InputDecoration(
                  hintText: 'Add routine notes...',
                  hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                onChanged: (val) {
                  ref.read(routineDaoProvider).updateRoutine(
                    widget.routineId,
                    notes: val.trim().isEmpty ? null : val.trim(),
                  );
                },
              ),
            ),
            Expanded(
              child: Stack(
          children: [
            detail.exercises.isEmpty
                ? _EmptyState(onAdd: () => _addExercise(context))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 120, top: 8),
                    itemCount: detail.exercises.length,
                    onReorder: (oldIndex, newIndex) => _reorderExercises(detail.exercises, oldIndex, newIndex),
                    proxyDecorator: (child, index, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) => Material(
                          color: Colors.transparent,
                          elevation: 8,
                          shadowColor: Colors.black54,
                          borderRadius: BorderRadius.circular(16),
                          child: child,
                        ),
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final e = detail.exercises[index];
                      return _TemplateExerciseCard(
                        key: ValueKey(e.templateExercise.id),
                        exercise: e,
                        onRemove: () => _removeExercise(e.templateExercise.id),
                        onUpdateSets: (sets) => _updateTemplateExercise(e.templateExercise.id, targetSets: sets),
                        onUpdateReps: (reps) => _updateTemplateExercise(e.templateExercise.id, targetReps: reps),
                        onUpdateWeight: (w) => _updateTemplateExercise(e.templateExercise.id, targetWeight: w),
                      );
                    },
                  ),

            // ─── Sticky "Add Exercise" Button ──────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withValues(alpha: 0.0),
                      AppColors.background,
                      AppColors.background,
                    ],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).padding.bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _addExercise(context),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: const Text('Add Exercise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Routine'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Routine name',
            filled: true,
            fillColor: AppColors.surfaceHighlight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
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

    ref.read(exerciseFilterProvider.notifier).update((_) => const ExerciseFilter());

    final result = await showModalBottomSheet<(List<int>, bool)?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExercisePickerForRoutine(),
    );

    if (result != null && result.$1.isNotEmpty) {
      final selected = result.$1;
      final isSuperset = result.$2;
      final dao = ref.read(routineDaoProvider);
      final detail = await ref.read(routineDetailProvider(widget.routineId).future);
      int orderIndex = detail.exercises.length;
      final int? groupId = isSuperset ? ++_supersetGen : null;

      for (final exerciseId in selected) {
        await dao.addExerciseToRoutine(
          templateId: widget.routineId,
          exerciseId: exerciseId,
          orderIndex: orderIndex++,
          supersetGroupId: groupId,
        );
      }
      ref.invalidate(routineDetailProvider(widget.routineId));
    }
  }

  Future<void> _removeExercise(int templateExerciseId) async {
    HapticFeedback.lightImpact();
    await ref.read(routineDaoProvider).removeExerciseFromRoutine(templateExerciseId);
    ref.invalidate(routineDetailProvider(widget.routineId));
  }

  Future<void> _updateTemplateExercise(int id, {int? targetSets, int? targetReps, double? targetWeight, int? orderIndex}) async {
    await ref.read(routineDaoProvider).updateTemplateExercise(
      id,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      orderIndex: orderIndex,
    );
    ref.invalidate(routineDetailProvider(widget.routineId));
  }

  Future<void> _reorderExercises(List<RoutineExerciseWithDetails> exercises, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    HapticFeedback.mediumImpact();

    final dao = ref.read(routineDaoProvider);
    final reordered = List<RoutineExerciseWithDetails>.from(exercises);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Update all order indices
    for (int i = 0; i < reordered.length; i++) {
      await dao.updateTemplateExercise(reordered[i].templateExercise.id, orderIndex: i);
    }
    ref.invalidate(routineDetailProvider(widget.routineId));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

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
              child: Icon(Icons.fitness_center_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add exercises to this routine',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 17, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to start building.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateExerciseCard extends StatelessWidget {
  const _TemplateExerciseCard({
    super.key,
    required this.exercise,
    required this.onRemove,
    required this.onUpdateSets,
    required this.onUpdateReps,
    required this.onUpdateWeight,
  });

  final RoutineExerciseWithDetails exercise;
  final VoidCallback onRemove;
  final ValueChanged<int> onUpdateSets;
  final ValueChanged<int> onUpdateReps;
  final ValueChanged<double> onUpdateWeight;

  @override
  Widget build(BuildContext context) {
    final te = exercise.templateExercise;
    final ex = exercise.exercise;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: 0, // Will be overridden by ReorderableListView
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: const Icon(Icons.drag_indicator_rounded, color: AppColors.textTertiary, size: 20),
              ),
            ),
            // Exercise info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Sets stepper
                        _MiniStepper(
                          label: 'Sets',
                          value: te.targetSets,
                          onChanged: onUpdateSets,
                        ),
                        const SizedBox(width: 4),
                        Text(' × ', style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        // Reps stepper
                        _MiniStepper(
                          label: 'Reps',
                          value: te.targetReps,
                          onChanged: onUpdateReps,
                        ),
                        const SizedBox(width: 4),
                        Text(' @ ', style: TextStyle(color: AppColors.textTertiary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        // Weight stepper
                        _MiniStepper(
                          label: 'kg',
                          value: (te.targetWeight * 2).round(),
                          onChanged: (v) => onUpdateWeight(v / 2.0),
                          step: 5,
                          min: 0,
                          isDouble: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textTertiary, size: 20),
              onPressed: onRemove,
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline stepper for sets/reps/weight — tap + / - to adjust.
class _MiniStepper extends StatelessWidget {
  const _MiniStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 1,
    this.isDouble = false,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final double step;
  final int min;
  final bool isDouble;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepButton(Icons.remove_rounded, () {
            if (value > min) {
              HapticFeedback.selectionClick();
              onChanged((value - step).round());
            }
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              isDouble ? '${(value / 2).toStringAsFixed(1)} $label' : '$value $label',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _stepButton(Icons.add_rounded, () {
            HapticFeedback.selectionClick();
            onChanged((value + step).round());
          }),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppColors.primary),
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
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textTertiary, borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Expanded(child: Text('Add Exercises', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                if (_selectedIds.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.pop(context, (_selectedIds.toList(), _isSuperset)),
                    child: Text('Add (${_selectedIds.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surfaceHighlight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
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
                      width: 40, height: 40, alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 22)
                          : const Icon(Icons.fitness_center_rounded, color: AppColors.textTertiary, size: 18),
                    ),
                    title: Text(ex.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                    subtitle: Text('${_cap(ex.primaryMuscleGroup)} · ${_cap(ex.equipment)}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => isSelected ? _selectedIds.remove(ex.id) : _selectedIds.add(ex.id));
                    },
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedIds.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.link_rounded, size: 18, color: _isSuperset ? AppColors.primary : AppColors.textTertiary),
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
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, (_selectedIds.toList(), _isSuperset)),
                        icon: const Icon(Icons.add_rounded),
                        label: Text('Add ${_selectedIds.length} Exercise${_selectedIds.length > 1 ? 's' : ''}${_isSuperset ? ' as Superset' : ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
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

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
