import 'package:flutter/material.dart';

class AppMotion {
  static const spring  = Curves.elasticOut;   // all tap/press interactions
  static const easeOut = Curves.easeOutCubic; // all screen entrances & exits
  // Never use Curves.linear except for countdown progress bars

  static const fast  = Duration(milliseconds: 160); // chip tap, hover states
  static const mid   = Duration(milliseconds: 280); // button press, card tap
  static const slow  = Duration(milliseconds: 400); // screen entrance, toast in
}
