import 'package:flutter/material.dart';

class AppColors {
  // ── Primary palette ──────────────────────────────

  // Forest Green — primary action, success, child home, confirm
  static const green      = Color(0xFF2D9B6F);
  static const greenMid   = Color(0xFFA8DFC8);
  static const greenLight = Color(0xFFE8F7F1);
  static const greenDark  = Color(0xFF1E7050); // button press-depth shadow

  // Amber — stars, rewards, badges, highlights
  static const amber      = Color(0xFFF0A500);
  static const amberMid   = Color(0xFFF9D87A);
  static const amberLight = Color(0xFFFEF4DC);
  static const amberDark  = Color(0xFFB07800); // button press-depth shadow

  // Terracotta — speech practice, record button, wrong answer
  static const rose       = Color(0xFFE8634A);
  static const roseMid    = Color(0xFFF2B9AD);
  static const roseLight  = Color(0xFFFCEEE9);
  static const roseDark   = Color(0xFFB04030); // button press-depth shadow

  // Denim Blue — AAC board, info states, calm learning
  static const sky        = Color(0xFF3D8FBF);
  static const skyMid     = Color(0xFFA8CDE8);
  static const skyLight   = Color(0xFFE8F3FA);
  static const skyDark    = Color(0xFF2A6A96); // button press-depth shadow

  // ── Ink neutrals — warm stone, NOT cold grey ─────
  // Source: Tailwind Stone palette
  static const ink        = Color(0xFF1C1917); // primary text
  static const ink2       = Color(0xFF57534E); // secondary text
  static const ink3       = Color(0xFFA8A29E); // captions, placeholders
  static const ink4       = Color(0xFFD6D3D1); // dividers, borders
  static const ink5       = Color(0xFFF5F4F2); // subtle backgrounds, tags
  static const bg         = Color(0xFFF7F4EF); // page/screen background (warm off-white)
  static const bgCard     = Color(0xFFFFFFFF); // card surface
  static const bgRaised   = Color(0xFFF0EDE8); // slightly raised surface
}
