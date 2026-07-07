import 'package:flutter/material.dart';

class AppRadius {
  static const sm   = BorderRadius.all(Radius.circular(10));  // chips, tags, small inputs
  static const md   = BorderRadius.all(Radius.circular(14));  // symbol cards, fields
  static const lg   = BorderRadius.all(Radius.circular(20));  // module cards, section cards
  static const xl   = BorderRadius.all(Radius.circular(26));  // profile cards, large panels
  static const pill = BorderRadius.all(Radius.circular(999)); // buttons, progress bars, pills
}
