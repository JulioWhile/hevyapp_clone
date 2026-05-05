import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:hevy_app/app/theme/colors.dart';

List<String> decodeWorkoutMediaPaths(String? value) {
  if (value == null || value.trim().isEmpty) return const [];
  final decoded = json.decode(value) as List<dynamic>;
  return decoded.whereType<String>().toList();
}

String? encodeWorkoutMediaPaths(List<String> paths) {
  if (paths.isEmpty) return null;
  return json.encode(paths);
}

class WorkoutMediaPicker extends StatelessWidget {
  const WorkoutMediaPicker({
    super.key,
    required this.paths,
    required this.enabled,
    required this.onChanged,
  });

  final List<String> paths;
  final bool enabled;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!enabled && paths.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length + (enabled ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (enabled && index == 0) {
            return _AddMediaTile(onTap: () => _showPicker(context));
          }

          final path = paths[enabled ? index - 1 : index];
          return _MediaTile(
            path: path,
            enabled: enabled,
            onRemove: () {
              final updated = List<String>.from(paths)..remove(path);
              onChanged(updated);
            },
          );
        },
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final action = await showModalBottomSheet<_MediaAction>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Add Photos'),
              onTap: () => Navigator.pop(context, _MediaAction.photos),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Add Video'),
              onTap: () => Navigator.pop(context, _MediaAction.video),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    final picker = ImagePicker();
    if (action == _MediaAction.photos) {
      final photos = await picker.pickMultiImage(imageQuality: 88);
      if (photos.isEmpty) return;
      final persistedPaths = <String>[];
      for (final photo in photos) {
        persistedPaths.add(await _persistPickedFile(photo));
      }
      onChanged([...paths, ...persistedPaths]);
      return;
    }

    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    onChanged([...paths, await _persistPickedFile(video)]);
  }

  Future<String> _persistPickedFile(XFile file) async {
    final documents = await getApplicationDocumentsDirectory();
    final mediaDirectory = Directory(p.join(documents.path, 'workout_media'));
    if (!await mediaDirectory.exists()) {
      await mediaDirectory.create(recursive: true);
    }

    final extension = p.extension(file.path).isEmpty
        ? '.jpg'
        : p.extension(file.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$extension';
    final savedFile = await File(
      file.path,
    ).copy(p.join(mediaDirectory.path, fileName));
    return savedFile.path;
  }
}

enum _MediaAction { photos, video }

class _AddMediaTile extends StatelessWidget {
  const _AddMediaTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.textSecondary,
          size: 32,
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.path,
    required this.enabled,
    required this.onRemove,
  });

  final String path;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isVideo = _isVideoPath(path);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(
            width: 108,
            height: 108,
            color: AppColors.surfaceElevated,
            child: isVideo
                ? const Icon(Icons.play_circle_outline_rounded, size: 36)
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textTertiary,
                    ),
                  ),
          ),
          if (enabled)
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
            ),
        ],
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
