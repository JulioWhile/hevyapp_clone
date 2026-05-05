import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/constants/app_constants.dart';
import '../providers/profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Unit System ───────────────────────────
            _SectionHeader(title: 'Preferences'),
            const SizedBox(height: 8),
            Container(
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
                children: [
                  ListTile(
                    title: const Text('Unit System'),
                    subtitle: Text(
                      settings.unitSystem == 'metric'
                          ? 'Kilograms (kg)'
                          : 'Pounds (lbs)',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ToggleButtons(
                        isSelected: [
                          settings.unitSystem == 'metric',
                          settings.unitSystem == 'imperial',
                        ],
                        onPressed: (index) {
                          final unit = index == 0 ? 'metric' : 'imperial';
                          ref.read(settingsDaoProvider).updateUnitSystem(unit);
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: AppColors.primary,
                        color: AppColors.textSecondary,
                        constraints: const BoxConstraints(
                          minWidth: 50,
                          minHeight: 32,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        children: const [Text('kg'), Text('lbs')],
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Default Rest Timer'),
                    subtitle: Text(
                      '${settings.defaultRestTimerSeconds}s',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () => _showRestTimerPicker(
                      context,
                      ref,
                      settings.defaultRestTimerSeconds,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── About ─────────────────────────────────
            _SectionHeader(title: 'About'),
            const SizedBox(height: 8),
            Container(
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
              child: const Column(
                children: [
                  ListTile(
                    title: Text('Version'),
                    trailing: Text(
                      '0.1.0',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showRestTimerPicker(
    BuildContext context,
    WidgetRef ref,
    int currentValue,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Default Rest Timer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              ...AppConstants.restTimerPresets.map((seconds) {
                final isSelected = seconds == currentValue;
                final label = seconds >= 60
                    ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
                    : '${seconds}s';
                return ListTile(
                  title: Text(label),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () {
                    ref.read(settingsDaoProvider).updateRestTimer(seconds);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
