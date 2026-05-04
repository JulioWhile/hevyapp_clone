import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/app/theme/colors.dart';
import '../providers/workout_providers.dart';

/// Floating rest timer bar — shown at the top of the active workout when timer is running.
class RestTimerBar extends ConsumerStatefulWidget {
  const RestTimerBar({super.key});

  @override
  ConsumerState<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends ConsumerState<RestTimerBar> with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  bool _wasUrgent = false;

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(restTimerProvider);

    if (!timer.isRunning && timer.remainingSeconds <= 0) {
      _pulseController?.stop();
      return const SizedBox.shrink();
    }

    final isUrgent = timer.isRunning && timer.remainingSeconds <= 10;

    if (isUrgent && !_wasUrgent) {
      _pulseController?.dispose();
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true);
    } else if (!isUrgent && _wasUrgent) {
      _pulseController?.stop();
      _pulseController?.reset();
    }
    _wasUrgent = isUrgent;

    final pulseOpacity = _pulseController != null && isUrgent
        ? Tween<double>(begin: 0.15, end: 0.35).animate(_pulseController!)
        : null;

    return AnimatedBuilder(
      animation: _pulseController ?? (AlwaysStoppedAnimation(0)),
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isUrgent
                ? AppColors.error.withValues(alpha: pulseOpacity?.value ?? 0.3)
                : AppColors.warningMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUrgent
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Icon(Icons.timer_rounded, color: isUrgent ? AppColors.error : AppColors.warning, size: 22),
          const SizedBox(width: 10),

          // Countdown text.
          Text(
            _formatTime(timer.remainingSeconds),
            style: TextStyle(
              color: isUrgent ? AppColors.error : AppColors.warning,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(width: 12),

          // Progress bar.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: timer.progress,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation(isUrgent ? AppColors.error : AppColors.warning),
                minHeight: 6,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // +30s button.
          GestureDetector(
            onTap: () => ref.read(restTimerProvider.notifier).addTime(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isUrgent ? AppColors.error : AppColors.warning).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+30s',
                style: TextStyle(
                  color: isUrgent ? AppColors.error : AppColors.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Stop button.
          GestureDetector(
            onTap: () => ref.read(restTimerProvider.notifier).stop(),
            child: Icon(Icons.close_rounded, color: isUrgent ? AppColors.error : AppColors.warning, size: 20),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
