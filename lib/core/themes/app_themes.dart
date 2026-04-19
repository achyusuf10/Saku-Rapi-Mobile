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
    scaffoldBackgroundColor: AppColorScheme.light.background,
    iconTheme: IconThemeData(
      color: AppColorScheme.light.textPrimary,
      size: context.getValueByLayout(
        phonePortrait: 24,
        phoneLandscape: 24.w,
        tabletPortrait: 24.w,
        tabletLandscape: 24.w,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>(
        (states) => AppColorScheme.light.primary,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.light.primary.withValues(alpha: 0.25);
        }
        return AppColorScheme.dark.background.withValues(alpha: 0.2);
      }),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColorScheme.light.primary,
      onPrimary: AppColorScheme.light.onPrimary,
      error: AppColorScheme.light.error,
      onError: AppColorScheme.light.onPrimary,
      tertiary: AppColorScheme.light.accent,
      primaryContainer: AppColorScheme.light.surface,
      secondaryContainer: AppColorScheme.light.surfaceVariant,
      tertiaryContainer: AppColorScheme.light.surfaceVariant,
      surface: AppColorScheme.light.surface,
      onSurface: AppColorScheme.light.textPrimary,
      outline: AppColorScheme.light.border,
    ),
    textTheme: GoogleFonts.nunitoSansTextTheme(
      TextTheme(
        bodyLarge: TextStyleConstants.b1.copyWith(
          color: AppColorScheme.light.textPrimary,
        ),
        bodyMedium: TextStyleConstants.b2.copyWith(
          color: AppColorScheme.light.textPrimary,
        ),
        bodySmall: TextStyleConstants.caption.copyWith(
          color: AppColorScheme.light.textSecondary,
        ),
        titleMedium: TextStyleConstants.h7.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColorScheme.light.textPrimary,
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
      backgroundColor: AppColorScheme.light.surface,
      scrolledUnderElevation: 0,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: AppColorScheme.light.border)),
      titleTextStyle: TextStyleConstants.h7.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColorScheme.light.textPrimary,
      ),
      iconTheme: IconThemeData(color: AppColorScheme.light.textPrimary),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
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
      backgroundColor: AppColorScheme.light.surface,
      selectedItemColor: AppColorScheme.light.primary,
      unselectedItemColor: AppColorScheme.light.textSecondary,
      elevation: 0,
      showUnselectedLabels: true,
      selectedIconTheme: IconThemeData(color: AppColorScheme.light.primary),
      unselectedIconTheme: IconThemeData(
        color: AppColorScheme.light.textSecondary,
      ),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyleConstants.caption.copyWith(
        fontWeight: FontWeight.w600,
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
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: AppColorScheme.light.border,
    ),
    buttonTheme: ButtonThemeData(
      textTheme: ButtonTextTheme.normal,
      buttonColor: AppColorScheme.light.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: AppColorScheme.light.border,
        disabledForegroundColor: AppColorScheme.light.textSecondary,
        textStyle: TextStyleConstants.b2.copyWith(
          color: AppColorScheme.light.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColorScheme.light.primary,
        foregroundColor: AppColorScheme.light.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColorScheme.light.surfaceVariant,
      filled: true,
      hintStyle: TextStyleConstants.caption.copyWith(
        color: AppColorScheme.light.textSecondary,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColorScheme.light.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColorScheme.light.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColorScheme.light.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColorScheme.light.error),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>(
        (states) => AppColorScheme.light.primary,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColorScheme.light.background,
      rangePickerBackgroundColor: AppColorScheme.light.background,
      headerBackgroundColor: AppColorScheme.light.primary,
      headerForegroundColor: AppColorScheme.light.onPrimary,
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
      todayForegroundColor: WidgetStateProperty.all(
        AppColorScheme.light.primary,
      ),
      todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
      todayBorder: BorderSide(color: AppColorScheme.light.primary, width: 1.5),
      rangeSelectionBackgroundColor: AppColorScheme.light.primary.withValues(
        alpha: 0.12,
      ),
      rangeSelectionOverlayColor: WidgetStateProperty.all(
        AppColorScheme.light.primary.withValues(alpha: 0.08),
      ),
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
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColorScheme.light.primary,
      ),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColorScheme.light.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      rangePickerHeaderBackgroundColor: AppColorScheme.light.primary,
      rangePickerHeaderForegroundColor: AppColorScheme.light.onPrimary,
      rangePickerShape: const RoundedRectangleBorder(),
      rangePickerSurfaceTintColor: Colors.transparent,
    ),
    toggleButtonsTheme: ToggleButtonsThemeData(
      fillColor: AppColorScheme.light.primary.withValues(alpha: 0.12),
      selectedColor: AppColorScheme.light.primary,
      color: AppColorScheme.light.textPrimary,
      borderRadius: BorderRadius.circular(8.r),
      borderColor: AppColorScheme.light.border,
      selectedBorderColor: AppColorScheme.light.primary,
      disabledBorderColor: AppColorScheme.light.border.withValues(alpha: 0.5),
      disabledColor: AppColorScheme.light.textSecondary.withValues(alpha: 0.5),
    ),
  );

  // dark theme
  static ThemeData darkTheme(BuildContext context) => ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    primaryColor: AppColorScheme.dark.primary,
    scaffoldBackgroundColor: AppColorScheme.dark.background,
    iconTheme: IconThemeData(
      color: AppColorScheme.dark.textPrimary,
      size: context.getValueByLayout(
        phonePortrait: 24,
        phoneLandscape: 24.w,
        tabletPortrait: 24.w,
        tabletLandscape: 24.w,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>(
        (states) => AppColorScheme.dark.primary,
      ),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.dark.primary.withValues(alpha: 0.25);
        }
        return AppColorScheme.light.background.withValues(alpha: 0.2);
      }),
    ),
    colorScheme: ColorScheme.dark(
      primary: AppColorScheme.dark.primary,
      onPrimary: AppColorScheme.dark.onPrimary,
      error: AppColorScheme.dark.error,
      onError: AppColorScheme.dark.onPrimary,
      tertiary: AppColorScheme.dark.accent,
      primaryContainer: AppColorScheme.dark.surface,
      secondaryContainer: AppColorScheme.dark.surfaceVariant,
      tertiaryContainer: AppColorScheme.dark.surfaceVariant,
      surface: AppColorScheme.dark.surface,
      onSurface: AppColorScheme.dark.textPrimary,
      outline: AppColorScheme.dark.border,
    ),
    textTheme: GoogleFonts.nunitoSansTextTheme(
      TextTheme(
        bodyLarge: TextStyleConstants.b1.copyWith(
          color: AppColorScheme.dark.textPrimary,
        ),
        bodyMedium: TextStyleConstants.b2.copyWith(
          color: AppColorScheme.dark.textPrimary,
        ),
        bodySmall: TextStyleConstants.caption.copyWith(
          color: AppColorScheme.dark.textSecondary,
        ),
        titleMedium: TextStyleConstants.h7.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColorScheme.dark.textPrimary,
        ),
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
      backgroundColor: AppColorScheme.dark.surface,
      scrolledUnderElevation: 0,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: AppColorScheme.dark.border)),
      titleTextStyle: TextStyleConstants.h7.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColorScheme.dark.textPrimary,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(color: AppColorScheme.dark.textPrimary),
    ),
    scrollbarTheme: ScrollbarThemeData(
      radius: Radius.circular(4.r),
      thickness: WidgetStatePropertyAll(4.w),
      thumbColor: WidgetStatePropertyAll(
        AppColorScheme.dark.border.withValues(alpha: 0.9),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColorScheme.dark.primary,
      strokeCap: StrokeCap.round,
      circularTrackColor: AppColorScheme.dark.surfaceVariant,
    ),
    sliderTheme: SliderThemeData(
      padding: EdgeInsets.symmetric(vertical: 8.w),
      activeTrackColor: AppColorScheme.dark.primary,
      thumbColor: AppColorScheme.dark.primary,
      overlayColor: AppColorScheme.dark.primary.withValues(alpha: 0.12),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColorScheme.dark.surface,
      selectedItemColor: AppColorScheme.dark.primary,
      unselectedItemColor: AppColorScheme.dark.textSecondary,
      elevation: 0,
      showUnselectedLabels: true,
      selectedIconTheme: IconThemeData(color: AppColorScheme.dark.primary),
      unselectedIconTheme: IconThemeData(
        color: AppColorScheme.dark.textSecondary,
      ),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyleConstants.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColorScheme.dark.primary,
      ),
      unselectedLabelStyle: TextStyleConstants.caption.copyWith(
        fontWeight: FontWeight.w400,
        color: AppColorScheme.dark.textSecondary,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColorScheme.dark.primary,
      foregroundColor: AppColorScheme.dark.onPrimary,
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      color: AppColorScheme.dark.border,
    ),
    buttonTheme: ButtonThemeData(
      textTheme: ButtonTextTheme.normal,
      buttonColor: AppColorScheme.dark.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: AppColorScheme.dark.border,
        disabledForegroundColor: AppColorScheme.dark.textSecondary,
        textStyle: TextStyleConstants.b2.copyWith(
          color: AppColorScheme.dark.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: AppColorScheme.dark.primary,
        foregroundColor: AppColorScheme.dark.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColorScheme.dark.surfaceVariant,
      filled: true,
      hintStyle: TextStyleConstants.caption.copyWith(
        color: AppColorScheme.dark.textSecondary,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColorScheme.dark.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColorScheme.dark.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColorScheme.dark.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColorScheme.dark.error),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>(
        (states) => AppColorScheme.dark.primary,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColorScheme.dark.background,
      rangePickerBackgroundColor: AppColorScheme.dark.background,
      headerBackgroundColor: AppColorScheme.dark.primary,
      headerForegroundColor: AppColorScheme.dark.onPrimary,
      dayForegroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.dark.onPrimary;
        }
        if (states.contains(WidgetState.disabled)) {
          return AppColorScheme.dark.textSecondary.withValues(alpha: 0.35);
        }
        return AppColorScheme.dark.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.dark.primary;
        }
        return Colors.transparent;
      }),
      todayForegroundColor: WidgetStateProperty.all(
        AppColorScheme.dark.primary,
      ),
      todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
      todayBorder: BorderSide(color: AppColorScheme.dark.primary, width: 1.5),
      rangeSelectionBackgroundColor: AppColorScheme.dark.primary.withValues(
        alpha: 0.16,
      ),
      rangeSelectionOverlayColor: WidgetStateProperty.all(
        AppColorScheme.dark.primary.withValues(alpha: 0.08),
      ),
      yearForegroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.dark.onPrimary;
        }
        return AppColorScheme.dark.textPrimary;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColorScheme.dark.primary;
        }
        return Colors.transparent;
      }),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColorScheme.dark.primary,
      ),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColorScheme.dark.textSecondary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      rangePickerHeaderBackgroundColor: AppColorScheme.dark.primary,
      rangePickerHeaderForegroundColor: AppColorScheme.dark.onPrimary,
      rangePickerShape: const RoundedRectangleBorder(),
      rangePickerSurfaceTintColor: Colors.transparent,
    ),
    toggleButtonsTheme: ToggleButtonsThemeData(
      fillColor: AppColorScheme.dark.primary.withValues(alpha: 0.12),
      selectedColor: AppColorScheme.dark.primary,
      color: AppColorScheme.dark.textPrimary,
      borderRadius: BorderRadius.circular(8.r),
      borderColor: AppColorScheme.dark.border,
      selectedBorderColor: AppColorScheme.dark.primary,
      disabledBorderColor: AppColorScheme.dark.border.withValues(alpha: 0.5),
      disabledColor: AppColorScheme.dark.textSecondary.withValues(alpha: 0.5),
    ),
    extensions: const [FlashBarTheme(), FlashToastTheme(), AppColorScheme.dark],
  );
}
