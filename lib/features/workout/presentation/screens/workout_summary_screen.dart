import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/database/daos/settings_dao.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import 'package:hevy_app/features/history/presentation/providers/history_providers.dart';
import 'package:hevy_app/features/history/presentation/widgets/muscle_split_card.dart';
import 'package:hevy_app/features/workout/presentation/providers/workout_providers.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.workoutId,
    required this.newPRs,
  });

  final int workoutId;
  final List<NewPR> newPRs;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _metricsController;
  late Animation<double> _checkScale;
  late Animation<double> _metricsSlide;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _metricsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _metricsSlide = CurvedAnimation(
      parent: _metricsController,
      curve: Curves.easeOutCubic,
    );

    // Stagger the animations
    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _metricsController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _metricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(workoutDetailProvider(widget.workoutId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.accentMuted.withValues(alpha: 0.28),
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0, 0.28, 1],
          ),
        ),
        child: detailAsync.when(
          data: (data) {
            final w = data.workout;
            final unitLabel = ref.watch(unitLabelProvider);
            final vol = data.totalVolume;
            final volumeFormatted = vol >= 1000
                ? '${(vol / 1000).toStringAsFixed(1)}k'
                : vol.toStringAsFixed(0);
            final durationMin = w.durationSeconds ~/ 60;

            return Stack(
              children: [
                ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 20,
                    20,
                    160,
                  ),
                  children: [
                    // ─── Celebration Header ──────────────
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          ScaleTransition(
                            scale: _checkScale,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Workout Complete',
                            style: GoogleFonts.lexend(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            w.name,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'EEEE, MMM d · h:mm a',
                            ).format(w.startedAt),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _WorkoutDetailsEditor(
                      workout: w,
                      durationMinutes: durationMin,
                      onNameSubmitted: (value) async {
                        final name = value.trim();
                        if (name.isEmpty || name == w.name) return;
                        await ref
                            .read(workoutDaoProvider)
                            .updateWorkoutName(w.id, name);
                        ref.invalidate(workoutDetailProvider(widget.workoutId));
                        ref.invalidate(workoutHistoryProvider);
                      },
                      onNotesChanged: (value) {
                        ref
                            .read(workoutDaoProvider)
                            .updateWorkoutNotes(
                              w.id,
                              value.trim().isEmpty ? null : value.trim(),
                            );
                      },
                      onDurationSubmitted: (value) async {
                        final minutes = int.tryParse(value.trim());
                        if (minutes == null || minutes <= 0) return;
                        await ref
                            .read(workoutDaoProvider)
                            .updateWorkoutDuration(w.id, minutes * 60);
                        ref.invalidate(workoutDetailProvider(widget.workoutId));
                        ref.invalidate(workoutHistoryProvider);
                      },
                    ),

                    const SizedBox(height: 16),

                    // ─── Metrics Bento Grid ──────────────
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_metricsSlide),
                      child: FadeTransition(
                        opacity: _metricsSlide,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Duration
                                Expanded(
                                  child: _MetricCard(
                                    icon: Icons.timer_outlined,
                                    value: '$durationMin',
                                    unit: 'm',
                                    label: 'Duration',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Volume
                                Expanded(
                                  child: _MetricCard(
                                    icon: Icons.fitness_center_rounded,
                                    value: volumeFormatted,
                                    unit: '',
                                    label: 'Volume ($unitLabel)',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Total Sets — full width
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    AppColors.surface,
                                    AppColors.surfaceElevated,
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceHighlight,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.repeat_rounded,
                                          color: AppColors.textTertiary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Total Sets',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${data.totalSets}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    MuscleSplitCard(entries: data.muscleSplit),

                    // ─── New PRs ──────────────────────────
                    if (widget.newPRs.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        'ACHIEVEMENTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.newPRs.map(
                        (pr) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warning.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Gold left accent
                              Container(
                                width: 4,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  color: AppColors.warning,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'New Personal Record',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${pr.exerciseName} • ${pr.value.toStringAsFixed(1)} $unitLabel',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (pr.previousValue != null)
                                      Text(
                                        'Previous: ${pr.previousValue!.toStringAsFixed(1)} $unitLabel',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ─── Exercise Breakdown ───────────────
                    const SizedBox(height: 28),
                    Text(
                      'EXERCISES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...data.exercises.map(
                      (e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.exercise.name,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              e.sets
                                  .where((s) => s.isCompleted)
                                  .map(
                                    (s) =>
                                        '${s.weight.toStringAsFixed(1)}$unitLabel × ${s.reps}',
                                  )
                                  .join(' · '),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ─── Sticky Bottom Actions ──────────────
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
                    padding: EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      MediaQuery.of(context).padding.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
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
      ),
    );
  }
}

class _WorkoutDetailsEditor extends StatelessWidget {
  const _WorkoutDetailsEditor({
    required this.workout,
    required this.durationMinutes,
    required this.onNameSubmitted,
    required this.onNotesChanged,
    required this.onDurationSubmitted,
  });

  final Workout workout;
  final int durationMinutes;
  final ValueChanged<String> onNameSubmitted;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<String> onDurationSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Details',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          _SummaryTextField(
            key: ValueKey('summary-name-${workout.id}-${workout.name}'),
            label: 'Title',
            initialValue: workout.name,
            icon: Icons.title_rounded,
            textCapitalization: TextCapitalization.words,
            onSubmitted: onNameSubmitted,
          ),
          const SizedBox(height: 12),
          _SummaryTextField(
            key: ValueKey('summary-notes-${workout.id}-${workout.notes ?? ''}'),
            label: 'Description',
            initialValue: workout.notes ?? '',
            icon: Icons.notes_rounded,
            maxLines: 3,
            onChanged: onNotesChanged,
            onSubmitted: onNotesChanged,
          ),
          const SizedBox(height: 12),
          _SummaryTextField(
            key: ValueKey(
              'summary-duration-${workout.id}-${workout.durationSeconds}',
            ),
            label: 'Workout Time',
            initialValue: '$durationMinutes',
            icon: Icons.timer_outlined,
            suffixText: 'min',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: onDurationSubmitted,
          ),
        ],
      ),
    );
  }
}

class _SummaryTextField extends StatelessWidget {
  const _SummaryTextField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.icon,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final String initialValue;
  final IconData icon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        filled: true,
        fillColor: AppColors.surfaceHighlight.withValues(alpha: 0.58),
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
      ),
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 24),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.lexend(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0,
                height: 1,
              ),
              children: [
                TextSpan(text: value),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
