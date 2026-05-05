import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/database/daos/workout_dao.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import 'package:hevy_app/features/history/presentation/widgets/muscle_split_card.dart';
import 'package:hevy_app/features/workout/presentation/providers/workout_providers.dart';
import 'package:hevy_app/features/workout/presentation/widgets/exercise_picker_sheet.dart';
import 'package:hevy_app/features/workout/presentation/widgets/workout_media_picker.dart';
import '../providers/history_providers.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final int workoutId;

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  bool _isEditing = false;
  int? _loadedWorkoutId;
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
    _durationController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(workoutDetailProvider(widget.workoutId));
    final unitLabel = ref.watch(unitLabelProvider);
    final unitLabelUpper = ref.watch(unitLabelUpperProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        data: (data) {
          final w = data.workout;
          final dateStr = DateFormat('EEEE, MMM d, yyyy').format(w.startedAt);
          final timeStr = DateFormat('h:mm a').format(w.startedAt);
          final durationMin = w.durationSeconds ~/ 60;
          _syncControllers(w, durationMin);
          final vol = data.totalVolume;
          final volumeFormatted = vol >= 1000
              ? '${(vol / 1000).toStringAsFixed(1)}k'
              : vol.toStringAsFixed(0);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: AppColors.surface,
                actions: [
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                    ),
                    tooltip: _isEditing ? 'Done' : 'Edit',
                    onPressed: () async {
                      FocusScope.of(context).unfocus();

                      if (_isEditing) {
                        await _saveWorkoutDetails(w.id);
                        if (!mounted) return;
                        setState(() => _isEditing = false);
                        ref.invalidate(workoutDetailProvider(widget.workoutId));
                        ref.invalidate(workoutHistoryProvider);
                      } else {
                        _syncControllers(w, durationMin, force: true);
                        setState(() => _isEditing = true);
                      }
                    },
                  ),
                  _isEditing
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.share_rounded),
                          tooltip: 'Export',
                          onPressed: () =>
                              _exportWorkout(ref, widget.workoutId),
                        ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryMuted.withValues(alpha: 0.6),
                          AppColors.surface,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.paddingOf(context).top + kToolbarHeight + 18,
                        20,
                        20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isEditing
                              ? TextField(
                                  controller: _titleController,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                  textCapitalization: TextCapitalization.words,
                                  decoration: InputDecoration(
                                    hintText: 'Workout title',
                                    filled: true,
                                    fillColor: Colors.black.withValues(
                                      alpha: 0.18,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  onSubmitted: (_) => _saveWorkoutDetails(w.id),
                                )
                              : Text(
                                  w.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    height: 1.05,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  dateStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_outlined,
                                size: 16,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _isEditing
                                ? _EditableDurationTile(
                                    controller: _durationController,
                                    onSubmitted: (_) =>
                                        _saveWorkoutDetails(w.id),
                                  )
                                : _MetricTile(
                                    icon: Icons.timer_outlined,
                                    value: '${durationMin}m',
                                    label: 'Duration',
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.fitness_center_rounded,
                              value: '$volumeFormatted $unitLabel',
                              label: 'Volume',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.repeat_rounded,
                              value: '${data.totalSets}',
                              label: 'Sets',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      MuscleSplitCard(entries: data.muscleSplit),

                      const SizedBox(height: 20),
                      WorkoutMediaPicker(
                        paths: decodeWorkoutMediaPaths(w.mediaPaths),
                        enabled: _isEditing,
                        onChanged: (paths) async {
                          await ref
                              .read(workoutDaoProvider)
                              .updateWorkoutMediaPaths(
                                w.id,
                                encodeWorkoutMediaPaths(paths),
                              );
                          ref.invalidate(
                            workoutDetailProvider(widget.workoutId),
                          );
                        },
                      ),

                      // Notes — editable in both modes
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _notesController,
                        readOnly: !_isEditing,
                        decoration: InputDecoration(
                          hintText: 'Workout notes...',
                          hintStyle: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                          border: _isEditing
                              ? const OutlineInputBorder()
                              : InputBorder.none,
                          enabledBorder: _isEditing ? null : InputBorder.none,
                          focusedBorder: _isEditing ? null : InputBorder.none,
                          filled: _isEditing,
                          fillColor: AppColors.surfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        onFieldSubmitted: _isEditing
                            ? (_) => _saveWorkoutDetails(w.id)
                            : null,
                      ),

                      const SizedBox(height: 28),
                      const Text('EXERCISES', style: _headerStyle),
                      const SizedBox(height: 12),

                      ...data.exercises.asMap().entries.map((entry) {
                        final exIdx = entry.key;
                        final e = entry.value;
                        return _EditableExerciseCard(
                          exerciseIndex: exIdx,
                          exercise: e,
                          unitLabel: unitLabelUpper,
                          isEditing: _isEditing,
                          workoutId: widget.workoutId,
                          onChanged: () => ref.invalidate(
                            workoutDetailProvider(widget.workoutId),
                          ),
                        );
                      }),

                      if (_isEditing)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: OutlinedButton.icon(
                            onPressed: () => _addExerciseToWorkout(),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Add Exercise'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _addExerciseToWorkout() async {
    await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExercisePickerSheet(),
    );
    // ExercisePickerSheet doesn't return selected IDs, it adds directly.
    // Fallback: refresh after picker closes.
    if (mounted) {
      ref.invalidate(workoutDetailProvider(widget.workoutId));
    }
  }

  void _syncControllers(
    Workout workout,
    int durationMin, {
    bool force = false,
  }) {
    if (!force && _isEditing && _loadedWorkoutId == workout.id) return;
    if (!force && _loadedWorkoutId == workout.id) return;

    _loadedWorkoutId = workout.id;
    _titleController.text = workout.name;
    _notesController.text = workout.notes ?? '';
    _durationController.text = '$durationMin';
  }

  Future<void> _saveWorkoutDetails(int workoutId) async {
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    final minutes = int.tryParse(_durationController.text.trim());
    final dao = ref.read(workoutDaoProvider);

    if (title.isNotEmpty) {
      await dao.updateWorkoutName(workoutId, title);
    }
    await dao.updateWorkoutNotes(workoutId, notes.isEmpty ? null : notes);
    if (minutes != null && minutes > 0) {
      await dao.updateWorkoutDuration(workoutId, minutes * 60);
    }
  }
}

class _EditableExerciseCard extends ConsumerWidget {
  const _EditableExerciseCard({
    required this.exerciseIndex,
    required this.exercise,
    required this.unitLabel,
    required this.isEditing,
    required this.workoutId,
    required this.onChanged,
  });

  final int exerciseIndex;
  final ExerciseWithSets exercise;
  final String unitLabel;
  final bool isEditing;
  final int workoutId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(workoutDaoProvider);
    final we = exercise.workoutExercise;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.58),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                if (exercise.exercise.gifUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/gifs/${exercise.exercise.gifUrl}',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.exercise.name,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onPressed: () {
                      dao.removeExerciseFromWorkout(we.id);
                      onChanged();
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                const SizedBox(
                  width: 40,
                  child: Text('SET', style: _headerStyle),
                ),
                Expanded(
                  child: Text(
                    unitLabel,
                    style: _headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'REPS',
                    style: _headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isEditing) const SizedBox(width: 40),
              ],
            ),
          ),
          ...exercise.sets.asMap().entries.map((sEntry) {
            final sIdx = sEntry.key;
            final s = sEntry.value;
            return _EditableSetRow(
              set: s,
              setIndex: sIdx,
              workoutExerciseId: we.id,
              isEditing: isEditing,
              dao: dao,
              onChanged: onChanged,
            );
          }),
          if (isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton.icon(
                  onPressed: () async {
                    await dao.addSet(
                      workoutExerciseId: we.id,
                      setNumber: exercise.sets.length + 1,
                    );
                    onChanged();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Set'),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EditableSetRow extends StatelessWidget {
  const _EditableSetRow({
    required this.set,
    required this.setIndex,
    required this.workoutExerciseId,
    required this.isEditing,
    required this.dao,
    required this.onChanged,
  });

  final WorkoutSet set;
  final int setIndex;
  final int workoutExerciseId;
  final bool isEditing;
  final WorkoutDao dao;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (set.setType) {
      'warmup' => 'W',
      'dropset' => 'D',
      'failure' => 'F',
      _ => '${set.setNumber}',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: set.isCompleted
              ? AppColors.accent.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (isEditing)
              GestureDetector(
                onTap: () => _showSetTypeMenu(context),
                child: Container(
                  width: 32,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _typeColor(set.setType).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: _typeColor(set.setType),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: 32,
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    color: set.isCompleted
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: isEditing
                  ? _CompactInput(
                      value: set.weight,
                      isDecimal: true,
                      hint: set.weight.toStringAsFixed(1),
                      onSubmitted: (v) {
                        dao.updateSet(setId: set.id, weight: v);
                        onChanged();
                      },
                    )
                  : Text(
                      set.weight.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isEditing
                  ? _CompactInput(
                      value: set.reps.toDouble(),
                      isDecimal: false,
                      hint: '${set.reps}',
                      onSubmitted: (v) {
                        dao.updateSet(setId: set.id, reps: v.toInt());
                        onChanged();
                      },
                    )
                  : Text(
                      '${set.reps}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
            if (isEditing)
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  dao.deleteSet(set.id);
                  onChanged();
                },
              ),
            if (!isEditing)
              SizedBox(
                width: 32,
                child: Icon(
                  set.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: set.isCompleted
                      ? AppColors.accent
                      : AppColors.textTertiary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) => switch (type) {
    'warmup' => AppColors.warmup,
    'dropset' => AppColors.dropset,
    'failure' => AppColors.failure,
    _ => AppColors.textSecondary,
  };

  void _showSetTypeMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['normal', 'warmup', 'dropset', 'failure'].map((type) {
              final isSelected = set.setType == type;
              return ListTile(
                title: Text(type[0].toUpperCase() + type.substring(1)),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  dao.updateSet(setId: set.id, setType: type);
                  onChanged();
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _CompactInput extends StatefulWidget {
  const _CompactInput({
    required this.value,
    required this.isDecimal,
    required this.hint,
    required this.onSubmitted,
  });

  final double value;
  final bool isDecimal;
  final String hint;
  final ValueChanged<double> onSubmitted;

  @override
  State<_CompactInput> createState() => _CompactInputState();
}

class _CompactInputState extends State<_CompactInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(_CompactInput old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.text = _fmt(widget.value);
    }
  }

  String _fmt(double v) {
    if (v == 0) {
      return '';
    }
    if (widget.isDecimal) {
      return v == v.truncateToDouble()
          ? v.toInt().toString()
          : v.toStringAsFixed(1);
    }
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) _submit();
      },
      child: TextField(
        controller: _ctrl,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(
          decimal: widget.isDecimal,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            widget.isDecimal ? RegExp(r'[\d.]') : RegExp(r'\d'),
          ),
        ],
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: AppColors.surfaceHighlight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          isDense: true,
        ),
        onSubmitted: (_) => _submit(),
      ),
    );
  }

  void _submit() {
    final val = double.tryParse(_ctrl.text) ?? 0.0;
    widget.onSubmitted(val);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

Future<void> _exportWorkout(WidgetRef ref, int workoutId) async {
  try {
    final dao = ref.read(workoutDaoProvider);
    final data = await dao.exportWorkout(workoutId);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/workout_$workoutId.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: data['name'] as String);
  } catch (_) {}
}

const _headerStyle = TextStyle(
  color: AppColors.textTertiary,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.58)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableDurationTile extends StatelessWidget {
  const _EditableDurationTile({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.58)),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              suffixText: 'm',
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onFieldSubmitted: onSubmitted,
          ),
          const SizedBox(height: 2),
          const Text(
            'Duration',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
