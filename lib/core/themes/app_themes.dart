import 'package:app_saku_rapi/core/constants/text_style_constants.dart';
import 'package:app_saku_rapi/core/themes/app_colors.dart';
import 'package:app_saku_rapi/utils/packages/flash/src/flash.dart';
import 'package:app_saku_rapi/utils/services/screen_util_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // light theme
  static ThemeData lightTheme(BuildContext context) => ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    iconTheme: IconThemeData(
      color: Colors.black,
      size: context.getValueByLayout(
        phonePortrait: 24,
        phoneLandscape: 24.w,
        tabletPortrait: 24.w,
        tabletLandscape: 24.w,
      ),
    ),

    scaffoldBackgroundColor: AppColorScheme.light.background,
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>(
        (states) => AppColorScheme.light.primary,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (states) => AppColorScheme.light.primaryLight.withOpacity(0.5),
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColorScheme.light.primary,
      error: AppColorScheme.light.error,
      tertiary: AppColorScheme.light.accent,
      primaryContainer: AppColorScheme.light.surface,
      secondaryContainer: AppColorScheme.light.surfaceVariant,
      tertiaryContainer: AppColorScheme.light.surfaceVariant,
      outline: AppColorScheme.light.border,
    ),
    textTheme: GoogleFonts.nunitoSansTextTheme(
      TextTheme(
        bodyMedium: TextStyleConstants.caption.copyWith(
          color: AppColorScheme.light.textPrimary,
        ),
        bodyLarge: TextStyleConstants.caption.copyWith(
          color: AppColorScheme.light.textPrimary,
        ),
        bodySmall: TextStyleConstants.caption.copyWith(
          color: AppColorScheme.light.textSecondary,
        ),
        titleMedium: TextStyleConstants.caption.copyWith(
          color: AppColorScheme.light.textSecondary,
        ),
      ),
    ),
    extensions: const [
      FlashBarTheme(),
      FlashToastTheme(),
      AppColorScheme.light,
    ],
    appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(
        size: context.getValueByLayout(
          phonePortrait: 24,
          phoneLandscape: 24.w,
          tabletPortrait: 24.w,
          tabletLandscape: 24.w,
        ),
      ),
      centerTitle: false,
      backgroundColor: const Color(0xFFFAFAFC),
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyleConstants.h7.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColorScheme.light.textPrimary,
      ),
      iconTheme: const IconThemeData(color: Colors.black),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFFAFAFC),
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      radius: Radius.circular(4.r),
      thickness: WidgetStatePropertyAll(4.w),
      thumbColor: WidgetStatePropertyAll(AppColorScheme.light.border),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColorScheme.light.primary,
      strokeCap: StrokeCap.round,
      circularTrackColor: AppColorScheme.light.surfaceVariant,
    ),
    sliderTheme: SliderThemeData(
      padding: EdgeInsets.symmetric(vertical: 8.w),
      activeTrackColor: AppColorScheme.light.primary,
      thumbColor: AppColorScheme.light.primary,
      overlayColor: AppColorScheme.light.primary.withValues(alpha: 0.12),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColorScheme.light.background,
      selectedItemColor: AppColorScheme.light.primary,
      unselectedItemColor: AppColorScheme.light.textSecondary,
      elevation: 10,
      showUnselectedLabels: true,
      selectedIconTheme: IconThemeData(color: AppColorScheme.light.primary),
      unselectedIconTheme: IconThemeData(
        color: AppColorScheme.light.textSecondary,
      ),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyleConstants.caption.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColorScheme.light.primary,
      ),
      unselectedLabelStyle: TextStyleConstants.caption.copyWith(
        fontWeight: FontWeight.w400,
        color: AppColorScheme.light.textSecondary,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColorScheme.light.primary,
      foregroundColor: AppColorScheme.light.onPrimary,
    ),
    dividerTheme: const DividerThemeData(
      // color: AppColors.grey[300],
      thickness: 1,
    ),
    buttonTheme: ButtonThemeData(
      textTheme: ButtonTextTheme.normal,
      buttonColor: AppColorScheme.light.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: Colors.grey[400],
        disabledForegroundColor: Colors.grey[300],
        textStyle: GoogleFonts.poppins(
          fontSize: 14.sp,
          color: AppColorScheme.light.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColorScheme.light.primary,
        foregroundColor: AppColorScheme.light.onPrimary,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: const Color(0xFFFAFAFC),
      filled: true,
      hintStyle: GoogleFonts.nunitoSans(
        color: AppColorScheme.light.textSecondary,
        fontSize: TextStyleConstants.caption.fontSize,
      ),
    ),
    // checkboxTheme: CheckboxThemeData(
    //   fillColor: MaterialStateProperty.resolveWith<Color>(
    //     (states) => AppColors.cyanLight,
    //   ),
    // ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>(
        (states) => AppColorScheme.light.primary,
      ),
    ),

    datePickerTheme: DatePickerThemeData(
      // Background of the dialog surface
      backgroundColor: AppColorScheme.light.background,
      rangePickerBackgroundColor: AppColorScheme.light.background,
      // Header (selected date display)
      headerBackgroundColor: AppColorScheme.light.primary,
      headerForegroundColor: AppColorScheme.light.onPrimary,
      // Day cells
      dayForegroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.light.onPrimary;
        }
        if (states.contains(WidgetState.disabled)) {
          return AppColorScheme.light.textSecondary.withValues(alpha: 0.3);
        }
        return AppColorScheme.light.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.light.primary;
        }
        return Colors.transparent;
      }),
      // Today circle
      todayForegroundColor: WidgetStateProperty.all(
        AppColorScheme.light.primary,
      ),
      todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
      todayBorder: BorderSide(color: AppColorScheme.light.primary, width: 1.5),
      // Range selection highlight (for DateRangePicker)
      rangeSelectionBackgroundColor: AppColorScheme.light.primary.withValues(
        alpha: 0.12,
      ),
      rangeSelectionOverlayColor: WidgetStateProperty.all(
        AppColorScheme.light.primary.withValues(alpha: 0.08),
      ),
      // Year/month picker
      yearForegroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.light.onPrimary;
        }
        return AppColorScheme.light.textPrimary;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.light.primary;
        }
        return Colors.transparent;
      }),
      // Confirm/cancel button
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColorScheme.light.primary,
      ),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColorScheme.light.onPrimary,
      ),
      // Shape
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // --- Range picker (full-screen) specific ---
      rangePickerHeaderBackgroundColor: AppColorScheme.light.primary,
      rangePickerHeaderForegroundColor: AppColorScheme.light.onPrimary,
      rangePickerShape: const RoundedRectangleBorder(),
      rangePickerSurfaceTintColor: Colors.transparent,
    ),
  );

  // dark theme
  static ThemeData darkTheme(BuildContext context) => ThemeData(
    iconTheme: IconThemeData(
      color: Colors.white,
      size: context.getValueByLayout(
        phonePortrait: 24,
        phoneLandscape: 24.w,
        tabletPortrait: 24.w,
        tabletLandscape: 24.w,
      ),
    ),
    useMaterial3: false,
    primaryColor: AppColorScheme.dark.primary,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color.fromARGB(255, 41, 41, 41),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith<Color>(
        (states) => AppColorScheme.dark.primary,
      ),
    ),
    textTheme: GoogleFonts.nunitoSansTextTheme(
      TextTheme(
        bodyMedium: TextStyleConstants.caption.copyWith(color: Colors.white),
        bodyLarge: TextStyleConstants.caption.copyWith(color: Colors.white),
        bodySmall: TextStyleConstants.caption.copyWith(color: Colors.white),
        titleMedium: TextStyleConstants.caption.copyWith(color: Colors.white),
      ),
    ),
    appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(
        size: context.getValueByLayout(
          phonePortrait: 24,
          phoneLandscape: 24.w,
          tabletPortrait: 24.w,
          tabletLandscape: 24.w,
        ),
      ),
      centerTitle: false,
      backgroundColor: const Color(0xFF2F2F31),
      scrolledUnderElevation: 0,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.6),
      titleTextStyle: GoogleFonts.nunitoSans(
        fontWeight: FontWeight.w500,
        color: Colors.white,
        fontSize: 18.sp, //20
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF2F2F31),
        statusBarIconBrightness: Brightness.light,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    scrollbarTheme: ScrollbarThemeData(radius: Radius.circular(4.r)),

    extensions: const [FlashBarTheme(), FlashToastTheme(), AppColorScheme.dark],
  );
}
