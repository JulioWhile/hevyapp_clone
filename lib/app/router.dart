import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/workout/presentation/providers/workout_providers.dart';
import '../features/workout/presentation/screens/active_workout_screen.dart';
import 'theme/colors.dart';

/// Route paths.
abstract final class AppRoutes {
  static const home = '/';
  static const analytics = '/analytics';
  static const history = '/history';
  static const profile = '/profile';
}

/// 4 real shell branches — Home (hub), Progress, History, Profile.
/// The center FAB is a visual overlay that launches the workout modal.
/// Routines are accessible from the Home hub, not a separate tab.
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _AppShell(navigationShell: navigationShell);
      },
      branches: [
        // 0 — Home: greeting, quick start, my routines, recent activity
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (c, s) => const HomeScreen(),
            ),
          ],
        ),
        // 1 — Progress / Analytics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.analytics,
              builder: (c, s) => const AnalyticsScreen(),
            ),
          ],
        ),
        // 2 — History
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.history,
              builder: (c, s) => const HistoryScreen(),
            ),
          ],
        ),
        // 3 — Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (c, s) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

// ─── App Shell ────────────────────────────────────────────────
class _AppShell extends ConsumerWidget {
  const _AppShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);

    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          if (activeWorkout != null && activeWorkout.isActive)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 72,
              child: _ActiveWorkoutDock(workout: activeWorkout),
            ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _GlassNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          if (index == -1) {
            // Center FAB sentinel → launch workout modal
            _startWorkout(context, ref);
            return;
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }

  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final active = ref.read(activeWorkoutProvider);
    if (active != null && active.isActive) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ActiveWorkoutScreen(),
          fullscreenDialog: true,
        ),
      );
      return;
    }
    await ref.read(activeWorkoutProvider.notifier).startWorkout();
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

class _ActiveWorkoutDock extends ConsumerWidget {
  const _ActiveWorkoutDock({required this.workout});

  final ActiveWorkoutState workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentExercise = _currentExerciseName(workout);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ActiveWorkoutScreen(),
            fullscreenDialog: true,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${workout.name}  ${_formatDuration(workout.elapsedSeconds)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (currentExercise != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        currentExercise,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Discard workout',
                onPressed: () => _confirmDiscard(context, ref),
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.textSecondary,
              ),
              const Icon(Icons.keyboard_arrow_up_rounded),
            ],
          ),
        ),
      ),
    );
  }

  String? _currentExerciseName(ActiveWorkoutState workout) {
    for (final exercise in workout.exercises) {
      if (exercise.sets.any((set) => !set.isCompleted)) {
        return exercise.exerciseName;
      }
    }
    return workout.exercises.isEmpty
        ? null
        : workout.exercises.last.exerciseName;
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text('This will delete the workout in progress.'),
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

// ─── Glassmorphic Bottom Nav ─────────────────────────────────
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surface.withValues(alpha: 0.9),
                AppColors.background.withValues(alpha: 0.94),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.16),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 0 — Home
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  // 1 — Progress
                  _NavItem(
                    icon: Icons.insights_outlined,
                    selectedIcon: Icons.insights_rounded,
                    label: 'Progress',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  // Center FAB — workout launcher (not a tab)
                  _CenterFab(onTap: () => onTap(-1)),
                  // 2 — History
                  _NavItem(
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history_rounded,
                    label: 'History',
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  // 3 — Profile
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Center FAB ───────────────────────────────────────────────
class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryVariant, AppColors.primary],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

// ─── Nav Item ────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.28)
                      : Colors.transparent,
                ),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
