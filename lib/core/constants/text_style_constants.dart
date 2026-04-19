import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyleConstants {
  static TextStyle get h1 => GoogleFonts.nunitoSans(fontSize: 80.sp);
  static TextStyle get h2 => GoogleFonts.nunitoSans(fontSize: 61.sp);
  static TextStyle get h3 => GoogleFonts.nunitoSans(fontSize: 47.sp);
  static TextStyle get h4 => GoogleFonts.nunitoSans(fontSize: 36.sp);
  static TextStyle get h5 => GoogleFonts.nunitoSans(fontSize: 27.sp);
  static TextStyle get h6 => GoogleFonts.nunitoSans(fontSize: 21.sp);
  static TextStyle get h7 => GoogleFonts.nunitoSans(fontSize: 18.sp);
  static TextStyle get b1 => GoogleFonts.nunitoSans(fontSize: 16.sp);
  static TextStyle get b2 => GoogleFonts.nunitoSans(fontSize: 14.sp);
  static TextStyle get caption =>
      GoogleFonts.nunitoSans(fontSize: min((13).sp, 20));
  static TextStyle get overline => GoogleFonts.nunitoSans(fontSize: 9.sp);
  static TextStyle get label1 => GoogleFonts.nunitoSans(fontSize: 14.sp);
  static TextStyle get label2 => GoogleFonts.nunitoSans(fontSize: 12.sp);
  static TextStyle get label3 => GoogleFonts.nunitoSans(fontSize: 10.sp);
}
