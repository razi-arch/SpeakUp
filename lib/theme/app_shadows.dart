import 'package:flutter/material.dart';

class AppShadows {
  // Warm ink-tinted shadows — never blue or purple tinted
  static const _c1 = Color(0x0F1C1917); // 6% ink
  static const _c2 = Color(0x141C1917); // 8% ink
  static const _c3 = Color(0x1A1C1917); // 10% ink

  static const xs = [
    BoxShadow(color: _c1, blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const sm = [
    BoxShadow(color: _c2, blurRadius: 8,  offset: Offset(0, 2)),
    BoxShadow(color: _c1, blurRadius: 2,  offset: Offset(0, 1)),
  ];
  static const md = [
    BoxShadow(color: _c2, blurRadius: 20, offset: Offset(0, 4)),
    BoxShadow(color: _c1, blurRadius: 4,  offset: Offset(0, 2)),
  ];
  static const lg = [
    BoxShadow(color: _c3, blurRadius: 40, offset: Offset(0, 12)),
    BoxShadow(color: _c2, blurRadius: 8,  offset: Offset(0, 4)),
  ];
}
