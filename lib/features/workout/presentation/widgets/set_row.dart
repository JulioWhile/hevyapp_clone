import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/app/theme/colors.dart';
import '../providers/workout_providers.dart';

/// A single set row: [type badge] [set#] [previous ghost] [weight] [reps] [✓]
class SetRow extends ConsumerWidget {
  const SetRow({
    super.key,
    required this.exerciseIndex,
    required this.setIndex,
    required this.set,
    this.displayLabel,
  });

  final int exerciseIndex;
  final int setIndex;
  final ActiveSet set;
  final String? displayLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = set.isCompleted;

    return Dismissible(
      key: ValueKey('set_${exerciseIndex}_$setIndex'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
      ),
      onDismissed: (_) {
        ref.read(activeWorkoutProvider.notifier).deleteSet(exerciseIndex, setIndex);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.only(left: 8, right: 4, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? AppColors.accent.withValues(alpha: 0.34) : AppColors.border.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // ─── Set number / type badge ──────────────
            GestureDetector(
              onTap: () => _showSetTypeMenu(context, ref),
              child: Container(
                width: 36,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _setTypeBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _setTypeLabel,
                  style: TextStyle(
                    color: _setTypeTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ─── Previous performance (ghost text) ────
            Expanded(
              child: Text(
                _previousText,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),

            // ─── Weight input ─────────────────────────
            Expanded(
              child: _NumberInput(
                value: set.weight,
                isDecimal: true,
                hintText: set.previousWeight?.toStringAsFixed(1) ?? '0',
                isCompleted: isCompleted,
                onChanged: (val) {
                  ref.read(activeWorkoutProvider.notifier).updateSet(
                        exerciseIndex,
                        setIndex,
                        weight: val,
                      );
                },
              ),
            ),
            const SizedBox(width: 8),

            // ─── Reps input ───────────────────────────
            Expanded(
              child: _NumberInput(
                value: set.reps.toDouble(),
                isDecimal: false,
                hintText: set.previousReps?.toString() ?? '0',
                isCompleted: isCompleted,
                onChanged: (val) {
                  ref.read(activeWorkoutProvider.notifier).updateSet(
                        exerciseIndex,
                        setIndex,
                        reps: val.toInt(),
                      );
                },
              ),
            ),
            const SizedBox(width: 4),

            // ─── Delete button ───────────────────────
            GestureDetector(
              onTap: () => ref.read(activeWorkoutProvider.notifier).deleteSet(exerciseIndex, setIndex),
              child: const SizedBox(
                width: 32,
                height: 48,
                child: Icon(Icons.delete_outline_rounded, color: AppColors.textTertiary, size: 18),
              ),
            ),

            // ─── Complete checkbox ────────────────────
            SizedBox(
              width: 48,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final willComplete = !set.isCompleted;
                  ref.read(activeWorkoutProvider.notifier).updateSet(
                        exerciseIndex,
                        setIndex,
                        isCompleted: willComplete,
                      );
                  if (willComplete) {
                    final workout = ref.read(activeWorkoutProvider);
                    final timerSeconds = workout?.exercises[exerciseIndex].restTimerSeconds;
                    if (timerSeconds != null) {
                      ref.read(restTimerProvider.notifier).start(timerSeconds);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? AppColors.accent : AppColors.surfaceHighlight,
                  foregroundColor: isCompleted ? AppColors.background : AppColors.textTertiary,
                  padding: EdgeInsets.zero,
                  elevation: isCompleted ? 2 : 0,
                  shadowColor: AppColors.accent.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isCompleted ? Colors.transparent : AppColors.border,
                      width: 1,
                    ),
                  ),
                ),
                child: const Icon(Icons.check_rounded, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _setTypeLabel {
    if (displayLabel != null) return displayLabel!;
    return switch (set.setType) {
      'warmup' => 'W',
      'dropset' => 'D',
      'failure' => 'F',
      _ => '${set.setNumber}',
    };
  }

  Color get _setTypeBgColor {
    return switch (set.setType) {
      'warmup' => AppColors.warmup.withValues(alpha: 0.15),
      'dropset' => AppColors.dropset.withValues(alpha: 0.15),
      'failure' => AppColors.failure.withValues(alpha: 0.15),
      _ => AppColors.surfaceElevated,
    };
  }

  Color get _setTypeTextColor {
    return switch (set.setType) {
      'warmup' => AppColors.warmup,
      'dropset' => AppColors.dropset,
      'failure' => AppColors.failure,
      _ => AppColors.textSecondary,
    };
  }

  String get _previousText {
    if (set.previousWeight != null && set.previousReps != null) {
      return '${set.previousWeight!.toStringAsFixed(1)} × ${set.previousReps}';
    }
    return '-';
  }

  void _showSetTypeMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SetTypeOption('Normal', 'normal', '', ref, context),
              _SetTypeOption('Warmup', 'warmup', 'W', ref, context),
              _SetTypeOption('Drop Set', 'dropset', 'D', ref, context),
              _SetTypeOption('Failure', 'failure', 'F', ref, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _SetTypeOption(String label, String type, String badge, WidgetRef ref, BuildContext ctx) {
    final isSelected = set.setType == type;
    return ListTile(
      leading: badge.isNotEmpty
          ? Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _colorForType(type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(badge, style: TextStyle(color: _colorForType(type), fontWeight: FontWeight.w700, fontSize: 13)),
            )
          : const SizedBox(width: 28),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
      onTap: () {
        ref.read(activeWorkoutProvider.notifier).updateSet(exerciseIndex, setIndex, setType: type);
        Navigator.pop(ctx);
      },
    );
  }

  Color _colorForType(String type) => switch (type) {
        'warmup' => AppColors.warmup,
        'dropset' => AppColors.dropset,
        'failure' => AppColors.failure,
        _ => AppColors.textSecondary,
      };
}

/// Compact number input field for weight/reps.
class _NumberInput extends StatefulWidget {
  const _NumberInput({
    required this.value,
    required this.isDecimal,
    required this.hintText,
    required this.isCompleted,
    required this.onChanged,
  });

  final double value;
  final bool isDecimal;
  final String hintText;
  final bool isCompleted;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
  }

  @override
  void didUpdateWidget(_NumberInput old) {
    super.didUpdateWidget(old);
    if (!_isFocused && old.value != widget.value) {
      _controller.text = _formatValue(widget.value);
    }
  }

  String _formatValue(double val) {
    if (val == 0) return '';
    if (widget.isDecimal) {
      return val == val.truncateToDouble() ? val.toInt().toString() : val.toStringAsFixed(1);
    }
    return val.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: TextField(
          controller: _controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.numberWithOptions(decimal: widget.isDecimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              widget.isDecimal ? RegExp(r'[\d.]') : RegExp(r'\d'),
            ),
          ],
          style: TextStyle(
            color: widget.isCompleted ? AppColors.accent : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: AppColors.textTertiary.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: widget.isCompleted
                ? AppColors.accent.withValues(alpha: 0.08)
                : AppColors.surfaceHighlight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.isCompleted ? Colors.transparent : AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: widget.isCompleted ? Colors.transparent : AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          onChanged: (text) {
            final val = double.tryParse(text) ?? 0.0;
            widget.onChanged(val);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
