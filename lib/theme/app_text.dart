import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppText {
  static TextStyle display({Color color = AppColors.ink}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: 30, fontWeight: FontWeight.w800,
      color: color, letterSpacing: -0.8, height: 1.1);

  static TextStyle heading({Color color = AppColors.ink}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: 22, fontWeight: FontWeight.w700,
      color: color, letterSpacing: -0.4, height: 1.2);

  static TextStyle title({Color color = AppColors.ink}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: 17, fontWeight: FontWeight.w700, color: color);

  static TextStyle button({Color color = Colors.white}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: 15, fontWeight: FontWeight.w700,
      color: color, letterSpacing: -0.2);

  static TextStyle symbolLabel({Color color = AppColors.ink2}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: 12, fontWeight: FontWeight.w600, color: color);

  static TextStyle body({Color color = AppColors.ink2}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: 14, fontWeight: FontWeight.w400,
      color: color, height: 1.6);

  static TextStyle caption({Color color = AppColors.ink3}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: 11, fontWeight: FontWeight.w500, color: color);
}
