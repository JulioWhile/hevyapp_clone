import 'package:flutter/material.dart';

/// Premium dark theme color palette (Midnight Slate + Neon Accents)
abstract final class AppColors {
  // ─── Backgrounds ─────────────────────────────────────────
  static const background = Color(0xFF09090B); // Zinc 950
  static const surface = Color(0xFF18181B); // Zinc 900
  static const surfaceElevated = Color(0xFF27272A); // Zinc 800
  static const surfaceHighlight = Color(0xFF3F3F46); // Zinc 700

  // ─── Primary (Vibrant Indigo) ────────────────────────────
  static const primary = Color(0xFF6366F1); // Indigo 500
  static const primaryVariant = Color(0xFF4F46E5); // Indigo 600
  static const primaryMuted = Color(0xFF3730A3); // Indigo 800

  // ─── Accent (Neon Cyan/Emerald for success) ──────────────
  static const accent = Color(0xFF10B981); // Emerald 500
  static const accentMuted = Color(0xFF065F46); // Emerald 800

  // ─── Semantics ───────────────────────────────────────────
  static const warning = Color(0xFFF59E0B);
  static const warningMuted = Color(0xFF92400E);
  static const error = Color(0xFFEF4444);
  static const errorMuted = Color(0xFF991B1B);

  // ─── Text ────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFAFAFA); // Zinc 50
  static const textSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const textTertiary = Color(0xFF71717A); // Zinc 500

  // ─── Borders & Dividers ──────────────────────────────────
  static const border = Color(0xFF27272A); // Zinc 800
  static const divider = Color(0xFF27272A);

  // ─── Set type badge colors ───────────────────────────────
  static const warmup = Color(0xFFF59E0B);
  static const dropset = Color(0xFFD946EF); // Fuchsia 500
  static const failure = Color(0xFFEF4444);
}

