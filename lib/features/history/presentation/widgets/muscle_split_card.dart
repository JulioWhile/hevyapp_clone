import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/features/history/presentation/providers/history_providers.dart';

class MuscleSplitCard extends StatelessWidget {
  const MuscleSplitCard({super.key, required this.entries});

  final List<MuscleSplitEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
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
            'Muscle Split',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on completed sets',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          ...entries.asMap().entries.map((entry) {
            final color = _barColor(entry.key);
            return _MuscleSplitRow(entry: entry.value, color: color);
          }),
        ],
      ),
    );
  }

  Color _barColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.primaryVariant,
      AppColors.accent,
      AppColors.warning,
      AppColors.dropset,
      AppColors.textSecondary,
    ];
    return colors[index % colors.length];
  }
}

class _MuscleSplitRow extends StatelessWidget {
  const _MuscleSplitRow({required this.entry, required this.color});

  final MuscleSplitEntry entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final widthFactor = entry.fraction.clamp(0.04, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${entry.percent}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 10, color: AppColors.surfaceHighlight),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widthFactor,
                  child: Container(height: 10, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
