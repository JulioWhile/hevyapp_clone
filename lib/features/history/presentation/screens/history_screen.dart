import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/database/app_database.dart';
import 'package:hevy_app/core/providers/unit_providers.dart';
import 'package:hevy_app/features/workout/presentation/widgets/workout_media_picker.dart';
import '../providers/history_providers.dart';
import 'workout_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: historyAsync.when(
          data: (workouts) {
            if (workouts.isEmpty) {
              return const _EmptyHistory();
            }

            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.paddingOf(context).bottom + 126,
              ),
              itemCount: workouts.length + 1,
              separatorBuilder: (_, index) => index == 0
                  ? const SizedBox(height: 14)
                  : const SizedBox(height: 18),
              itemBuilder: (context, index) {
                if (index == 0) return const _HistoryHeader();
                return _WorkoutFeedCard(workout: workouts[index - 1]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: GoogleFonts.lexend(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Workouts',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WorkoutFeedCard extends ConsumerStatefulWidget {
  const _WorkoutFeedCard({required this.workout});

  final Workout workout;

  @override
  ConsumerState<_WorkoutFeedCard> createState() => _WorkoutFeedCardState();
}

class _WorkoutFeedCardState extends ConsumerState<_WorkoutFeedCard> {
  late final PageController _pageController;
  int _pageIndex = 0;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = ref.watch(unitLabelProvider);
    final detailAsync = ref.watch(workoutDetailProvider(widget.workout.id));
    final recordCountAsync = ref.watch(
      workoutRecordCountProvider(widget.workout.id),
    );
    final mediaPaths = decodeWorkoutMediaPaths(widget.workout.mediaPaths);

    return detailAsync.when(
      data: (detail) => _buildCard(
        context,
        detail,
        mediaPaths,
        unitLabel,
        recordCountAsync.maybeWhen(data: (count) => count, orElse: () => 0),
      ),
      loading: () => const _FeedCardSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WorkoutDetailData detail,
    List<String> mediaPaths,
    String unitLabel,
    int recordCount,
  ) {
    final workout = widget.workout;
    final pageCount = mediaPaths.isEmpty ? 1 : mediaPaths.length + 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.65)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(
            workout: workout,
            onMore: () => _showPostMenu(detail, unitLabel, recordCount),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _openDetail,
            child: Text(
              workout.name.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _PostMetrics(
            duration: _formatDuration(workout.durationSeconds),
            volume: _formatVolume(detail.totalVolume, unitLabel),
            records: recordCount,
          ),
          const SizedBox(height: 12),
          if (mediaPaths.isEmpty)
            _ExercisePreviewPage(detail: detail, onOpen: _openDetail)
          else
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: pageCount,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (context, index) {
                  if (index < mediaPaths.length) {
                    return _WorkoutMediaPage(path: mediaPaths[index]);
                  }
                  return _ExercisePreviewPage(
                    detail: detail,
                    onOpen: _openDetail,
                    fillHeight: true,
                  );
                },
              ),
            ),
          if (pageCount > 1) ...[
            const SizedBox(height: 8),
            Center(
              child: _PageDots(count: pageCount, index: _pageIndex),
            ),
          ],
          const SizedBox(height: 8),
          _PostActions(
            isLiked: _isLiked,
            onLike: () => setState(() => _isLiked = !_isLiked),
            onComment: _openDetail,
            onShare: () => _shareWorkout(detail, unitLabel, recordCount),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  void _openDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(workoutId: widget.workout.id),
      ),
    );
  }

  void _showPostMenu(
    WorkoutDetailData detail,
    String unitLabel,
    int recordCount,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('View details'),
                onTap: () {
                  Navigator.pop(context);
                  _openDetail();
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share_rounded),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareWorkout(detail, unitLabel, recordCount);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareWorkout(
    WorkoutDetailData detail,
    String unitLabel,
    int recordCount,
  ) async {
    final workout = widget.workout;
    final exerciseCount = detail.exercises.length;
    await Share.share(
      '${workout.name}\n'
      'Time: ${_formatDuration(workout.durationSeconds)}\n'
      'Volume: ${_formatVolume(detail.totalVolume, unitLabel)}\n'
      'Records: $recordCount\n'
      'Exercises: $exerciseCount',
    );
  }

  String _formatVolume(double vol, String unit) {
    final value = NumberFormat.decimalPattern().format(vol.round());
    return '$value $unit';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes}min';
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.workout, required this.onMore});

  final Workout workout;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceElevated,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'juliowhile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                _relativeDate(workout.startedAt),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'More',
          onPressed: onMore,
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    );
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDay = DateTime(date.year, date.month, date.day);
    final days = today.difference(workoutDay).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }
}

class _PostMetrics extends StatelessWidget {
  const _PostMetrics({
    required this.duration,
    required this.volume,
    required this.records,
  });

  final String duration;
  final String volume;
  final int records;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PostMetric(label: 'Time', value: duration),
        ),
        Expanded(
          child: _PostMetric(label: 'Volume', value: volume),
        ),
        Expanded(
          child: _PostMetric(
            label: 'Records',
            value: records > 0 ? '$records' : '-',
            leading: records > 0 ? Icons.workspace_premium_rounded : null,
          ),
        ),
      ],
    );
  }
}

class _PostMetric extends StatelessWidget {
  const _PostMetric({required this.label, required this.value, this.leading});

  final String label;
  final String value;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (leading != null) ...[
              Icon(leading, color: AppColors.warning, size: 16),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkoutMediaPage extends StatelessWidget {
  const _WorkoutMediaPage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideoPath(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: AppColors.surfaceElevated,
        child: isVideo
            ? const Center(
                child: Icon(Icons.play_circle_outline_rounded, size: 56),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 40),
                ),
              ),
      ),
    );
  }

  bool _isVideoPath(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.avi');
  }
}

class _ExercisePreviewPage extends StatelessWidget {
  const _ExercisePreviewPage({
    required this.detail,
    required this.onOpen,
    this.fillHeight = false,
  });

  final WorkoutDetailData detail;
  final VoidCallback onOpen;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final preview = detail.exercises.take(3).toList();
    final remaining = detail.exercises.length - preview.length;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.divider.withValues(alpha: 0.65)),
            bottom: BorderSide(
              color: AppColors.divider.withValues(alpha: 0.65),
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: fillHeight
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            ...preview.map(
              (exercise) => _ExercisePreviewRow(exercise: exercise),
            ),
            if (remaining > 0) ...[
              const SizedBox(height: 2),
              Text(
                'See $remaining more exercises',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExercisePreviewRow extends StatelessWidget {
  const _ExercisePreviewRow({required this.exercise});

  final ExerciseWithSets exercise;

  @override
  Widget build(BuildContext context) {
    final completedSets = exercise.sets.where((set) => set.isCompleted).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 42,
              height: 42,
              color: Colors.white,
              child: exercise.exercise.gifUrl == null
                  ? const Icon(
                      Icons.fitness_center_rounded,
                      color: Colors.black54,
                    )
                  : _StaticAssetImage(
                      assetPath: 'assets/gifs/${exercise.exercise.gifUrl}',
                      fit: BoxFit.cover,
                      fallback: const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.black54,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$completedSets sets ${exercise.exercise.name}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticAssetImage extends StatefulWidget {
  const _StaticAssetImage({
    required this.assetPath,
    required this.fallback,
    this.fit,
  });

  final String assetPath;
  final Widget fallback;
  final BoxFit? fit;

  @override
  State<_StaticAssetImage> createState() => _StaticAssetImageState();
}

class _StaticAssetImageState extends State<_StaticAssetImage> {
  ui.Image? _image;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadFirstFrame();
  }

  @override
  void didUpdateWidget(covariant _StaticAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath == widget.assetPath) return;
    _image?.dispose();
    _image = null;
    _failed = false;
    _loadFirstFrame();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadFirstFrame() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();

      if (!mounted) {
        frame.image.dispose();
        return;
      }

      setState(() => _image = frame.image);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (_failed || image == null) return widget.fallback;

    return RawImage(
      image: image,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (dotIndex) {
        final isSelected = dotIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.textTertiary,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Like',
          onPressed: onLike,
          color: isLiked ? AppColors.primary : null,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          iconSize: 21,
          icon: Icon(
            isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Comment',
          onPressed: onComment,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          iconSize: 21,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Share',
          onPressed: onShare,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          iconSize: 21,
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
    );
  }
}

class _FeedCardSkeleton extends StatelessWidget {
  const _FeedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'History',
            style: GoogleFonts.lexend(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 56,
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No workouts yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Completed workouts will appear here',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
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
}
