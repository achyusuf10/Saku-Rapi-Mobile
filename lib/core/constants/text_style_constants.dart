import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyleConstants {
  static TextStyle get h1 => GoogleFonts.plusJakartaSans(fontSize: 80.sp);
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(fontSize: 61.sp);
  static TextStyle get h3 => GoogleFonts.plusJakartaSans(fontSize: 47.sp);
  static TextStyle get h4 => GoogleFonts.plusJakartaSans(fontSize: 36.sp);
  static TextStyle get h5 => GoogleFonts.plusJakartaSans(fontSize: 27.sp);
  static TextStyle get h6 => GoogleFonts.plusJakartaSans(fontSize: 21.sp);
  static TextStyle get h7 => GoogleFonts.plusJakartaSans(fontSize: 18.sp);
  static TextStyle get b1 => GoogleFonts.plusJakartaSans(fontSize: 16.sp);
  static TextStyle get b2 => GoogleFonts.plusJakartaSans(fontSize: 14.sp);
  static TextStyle get caption =>
      GoogleFonts.plusJakartaSans(fontSize: min((13).sp, 20));
  static TextStyle get overline => GoogleFonts.plusJakartaSans(fontSize: 9.sp);
  static TextStyle get label1 => GoogleFonts.plusJakartaSans(fontSize: 14.sp);
  static TextStyle get label2 => GoogleFonts.plusJakartaSans(fontSize: 12.sp);
  static TextStyle get label3 => GoogleFonts.plusJakartaSans(fontSize: 10.sp);
}
