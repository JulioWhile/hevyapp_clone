import 'package:flutter/material.dart';

/// High-performance athletic dark palette.
abstract final class AppColors {
  // ─── Backgrounds ─────────────────────────────────────────
  static const background = Color(0xFF101113);
  static const surface = Color(0xFF171819);
  static const surfaceDim = Color(0xFF121314);
  static const surfaceElevated = Color(0xFF202225);
  static const surfaceHighlight = Color(0xFF30343A);

  // ─── Primary (Electric Blue) ─────────────────────────────
  static const primary = Color(0xFF4B8EFF);
  static const primaryVariant = Color(0xFFADC6FF);
  static const primaryMuted = Color(0xFF153865);

  // ─── Accent (Goal Green) ─────────────────────────────────
  static const accent = Color(0xFF53E16F);
  static const accentMuted = Color(0xFF0A4E22);

  // ─── Semantics ───────────────────────────────────────────
  static const warning = Color(0xFFFFB874);
  static const warningMuted = Color(0xFF6A3B00);
  static const error = Color(0xFFFF6B61);
  static const errorMuted = Color(0xFF6D1614);

  // ─── Text ────────────────────────────────────────────────
  static const textPrimary = Color(0xFFEDEBE8);
  static const textSecondary = Color(0xFFC1C6D7);
  static const textTertiary = Color(0xFF858B99);

  // ─── Borders & Dividers ──────────────────────────────────
  static const border = Color(0xFF383D46);
  static const divider = Color(0xFF2B3038);

  // ─── Set type badge colors ───────────────────────────────
  static const warmup = Color(0xFFF59E0B);
  static const dropset = Color(0xFFD946EF); // Fuchsia 500
  static const failure = Color(0xFFFF6B61);
}

