import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyleConstants {
  static TextStyle get h1 => GoogleFonts.ibmPlexSans(fontSize: 80.sp);
  static TextStyle get h2 => GoogleFonts.ibmPlexSans(fontSize: 61.sp);
  static TextStyle get h3 => GoogleFonts.ibmPlexSans(fontSize: 47.sp);
  static TextStyle get h4 => GoogleFonts.ibmPlexSans(fontSize: 36.sp);
  static TextStyle get h5 => GoogleFonts.ibmPlexSans(fontSize: 27.sp);
  static TextStyle get h6 => GoogleFonts.ibmPlexSans(fontSize: 21.sp);
  static TextStyle get h7 => GoogleFonts.ibmPlexSans(fontSize: 18.sp);
  static TextStyle get b1 => GoogleFonts.ibmPlexSans(fontSize: 16.sp);
  static TextStyle get b2 => GoogleFonts.ibmPlexSans(fontSize: 14.sp);
  static TextStyle get caption =>
      GoogleFonts.ibmPlexSans(fontSize: min((13).sp, 20));
  static TextStyle get overline => GoogleFonts.ibmPlexSans(fontSize: 9.sp);
  static TextStyle get label1 => GoogleFonts.ibmPlexSans(fontSize: 14.sp);
  static TextStyle get label2 => GoogleFonts.ibmPlexSans(fontSize: 12.sp);
  static TextStyle get label3 => GoogleFonts.ibmPlexSans(fontSize: 10.sp);
}
