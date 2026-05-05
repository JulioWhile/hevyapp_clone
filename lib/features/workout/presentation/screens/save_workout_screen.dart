import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import 'package:hevy_app/features/history/presentation/providers/history_providers.dart';
import 'package:hevy_app/features/workout/presentation/providers/workout_providers.dart';
import 'package:hevy_app/features/workout/presentation/screens/workout_summary_screen.dart';
import 'package:hevy_app/features/workout/presentation/widgets/workout_media_picker.dart';
import 'package:hevy_app/main.dart';

class SaveWorkoutScreen extends ConsumerStatefulWidget {
  const SaveWorkoutScreen({super.key});

  @override
  ConsumerState<SaveWorkoutScreen> createState() => _SaveWorkoutScreenState();
}

class _SaveWorkoutScreenState extends ConsumerState<SaveWorkoutScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late int _durationSeconds;
  List<String> _mediaPaths = const [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final workout = ref.read(activeWorkoutProvider);
    _titleController = TextEditingController(text: workout?.name ?? 'Workout');
    _notesController = TextEditingController(text: workout?.notes ?? '');
    _durationSeconds = workout?.elapsedSeconds ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);

    if (workout == null || workout.workoutId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Save Workout')),
        body: const Center(child: Text('No active workout to save.')),
      );
    }

    final completedSets = workout.exercises.fold<int>(
      0,
      (total, exercise) =>
          total + exercise.sets.where((set) => set.isCompleted).length,
    );
    final volume = workout.exercises.fold<double>(
      0,
      (total, exercise) =>
          total +
          exercise.sets.fold<double>(
            0,
            (sum, set) => sum + (set.isCompleted ? set.weight * set.reps : 0),
          ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Workout'),
        actions: [
          TextButton(
            onPressed: _isSaving
                ? null
                : () => _saveWorkout(workout.workoutId!),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            TextField(
              controller: _titleController,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                hintText: 'Workout title',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('EEEE, MMM d').format(workout.startedAt),
              style: const TextStyle(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 20),
            _SaveStatsRow(
              duration: _formatDuration(_durationSeconds),
              volume: volume,
              sets: completedSets,
            ),
            const SizedBox(height: 22),
            _DurationTile(
              duration: _formatDuration(_durationSeconds),
              onTap: _showDurationEditor,
            ),
            const SizedBox(height: 18),
            WorkoutMediaPicker(
              paths: _mediaPaths,
              enabled: true,
              onChanged: (paths) => setState(() => _mediaPaths = paths),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'How did it go?',
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _PreferenceRow(
              icon: Icons.lock_outline_rounded,
              title: 'Visibility',
              value: 'Private',
            ),
            const _PreferenceRow(
              icon: Icons.sync_rounded,
              title: 'Sync With',
              value: 'None',
            ),
            const SizedBox(height: 18),
            ...workout.exercises.map(
              (exercise) => _ExerciseReviewTile(exercise: exercise),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _confirmDiscard,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.errorMuted),
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Discard Workout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDurationEditor() async {
    var hours = _durationSeconds ~/ 3600;
    var minutes = (_durationSeconds % 3600) ~/ 60;
    var seconds = _durationSeconds % 60;

    final updatedSeconds = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Duration',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _NumberStepper(
                    label: 'Hours',
                    value: hours,
                    onChanged: (value) => hours = value,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberStepper(
                    label: 'Minutes',
                    value: minutes,
                    max: 59,
                    onChanged: (value) => minutes = value,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumberStepper(
                    label: 'Seconds',
                    value: seconds,
                    max: 59,
                    onChanged: (value) => seconds = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  (hours * 3600) + (minutes * 60) + seconds,
                ),
                child: const Text('Update Duration'),
              ),
            ),
          ],
        ),
      ),
    );

    if (updatedSeconds != null) {
      setState(() => _durationSeconds = updatedSeconds);
      await ref
          .read(activeWorkoutProvider.notifier)
          .updateWorkoutDuration(updatedSeconds);
    }
  }

  Future<void> _saveWorkout(int workoutId) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(activeWorkoutProvider.notifier);
      final db = ref.read(databaseProvider);
      final title = _titleController.text.trim().isEmpty
          ? 'Workout'
          : _titleController.text.trim();

      await notifier.updateWorkoutName(title);
      await notifier.updateWorkoutNotes(_notesController.text.trim());
      await notifier.updateWorkoutDuration(_durationSeconds);
      await db.workoutDao.updateWorkoutMediaPaths(
        workoutId,
        encodeWorkoutMediaPaths(_mediaPaths),
      );
      ref.read(restTimerProvider.notifier).stop();
      await notifier.finishWorkout(durationSeconds: _durationSeconds);
      final newPRs = await db.settingsDao.checkAndRecordPRs(workoutId);

      ref.invalidate(workoutHistoryProvider);
      ref.invalidate(workoutDetailProvider(workoutId));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WorkoutSummaryScreen(workoutId: workoutId, newPRs: newPRs),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text('This will delete the workout you are logging.'),
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

    if (discard != true) return;

    ref.read(restTimerProvider.notifier).stop();
    await ref.read(activeWorkoutProvider.notifier).discardWorkout();

    if (!mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${remainingSeconds}s';
    return '${remainingSeconds}s';
  }
}

class _SaveStatsRow extends ConsumerWidget {
  const _SaveStatsRow({
    required this.duration,
    required this.volume,
    required this.sets,
  });

  final String duration;
  final double volume;
  final int sets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(unitLabelProvider);

    return Row(
      children: [
        Expanded(
          child: _StatTile(label: 'Duration', value: duration),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Volume',
            value: '${volume.toStringAsFixed(0)} $unit',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(label: 'Sets', value: '$sets'),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({required this.duration, required this.onTap});

  final String duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      tileColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: const Icon(Icons.timer_outlined),
      title: const Text('Duration'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(duration, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _ExerciseReviewTile extends StatelessWidget {
  const _ExerciseReviewTile({required this.exercise});

  final ActiveExercise exercise;

  @override
  Widget build(BuildContext context) {
    final completedSets = exercise.sets.where((set) => set.isCompleted).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedSets completed sets',
                  style: const TextStyle(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.drag_indicator_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _NumberStepper extends StatefulWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.max,
  });

  final String label;
  final int value;
  final int? max;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<_NumberStepper> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _value == 0 ? null : () => _setValue(_value - 1),
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_value',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.max != null && _value >= widget.max!
                    ? null
                    : () => _setValue(_value + 1),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setValue(int value) {
    setState(() => _value = value);
    widget.onChanged(value);
  }
}
