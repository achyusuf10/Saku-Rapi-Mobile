import 'dart:math';

import 'package:app_saku_rapi/utils/services/screen_util_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeviceLayoutConfig {
  static double getKanbanWidth(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: min(260.w, 1.sw / 1.4),
      phoneLandscape: 1.sw / 3,
      tabletPortrait: min(260.w, 1.sw / 1.4),
      tabletLandscape: (1.sw / 5),
    );
  }

  static int getCrossAxisGridView(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: 2,
      phoneLandscape: 4,
      tabletPortrait: 4,
      tabletLandscape: 7,
    );
  }

  static int getLengthLoadingGridView(BuildContext context) {
    return getCrossAxisGridView(context) * 2;
  }

  static int getCrossAxisGridViewOverview(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: 2,
      phoneLandscape: 3,
      tabletPortrait: 3,
      tabletLandscape: 3,
    );
  }

  static EdgeInsets getPaddingGridViewOverView(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: const EdgeInsets.symmetric(horizontal: 16, vertical: 10).w,
      phoneLandscape: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ).w,
      tabletPortrait: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ).w,
      tabletLandscape: const EdgeInsets.symmetric(
        horizontal: 40,
        vertical: 10,
      ).w,
    );
  }

  static int getLengthLoadingBoardList(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: 3,
      phoneLandscape: 5,
      tabletPortrait: 5,
      tabletLandscape: 6,
    );
  }

  static double getMaxDrawerWidth(BuildContext context) {
    /// * Ini ukuran untuk drawer di phone biasa dan nggk landscape
    final double maxWidthPhoneLandscape = 1.sw / 1.6;
    final double maxWidthTabletPortrait = 1.sw / 1.3;
    final double maxWidthTabletLandscape = 1.sw / 1.5;

    return context.getValueByLayout(
      phonePortrait: double.infinity,
      phoneLandscape: maxWidthPhoneLandscape,
      tabletPortrait: maxWidthTabletPortrait,
      tabletLandscape: maxWidthTabletLandscape,
    );
  }

  static double getDialogMaxWidth(BuildContext context) {
    /// * Ini ukuran untuk drawer di phone biasa dan nggk landscape
    final double minWidth = 1.sw - 40.w;
    final double maxWidth = 450.w;
    final double maxWidthTabletPortrait = 500.w;
    final double maxWidthPhoneLandscape = 400.w;

    return context.getValueByLayout(
      phonePortrait: minWidth,
      phoneLandscape: minWidth > maxWidthPhoneLandscape
          ? maxWidthPhoneLandscape
          : minWidth,
      tabletPortrait: minWidth > maxWidthTabletPortrait
          ? maxWidthTabletPortrait
          : minWidth,
      tabletLandscape: minWidth > maxWidth ? maxWidth : minWidth,
    );
  }

  /// Untuk di komen, notes semua fitur
  static double getLinkPriviewWidth(BuildContext context) {
    final double maxWidthTablet = 400.w;
    final double maxWidthPhoneLandscape = 300.w;

    return context.getValueByLayout(
      phonePortrait: 1.sw / 1.2,
      phoneLandscape: 1.sw / 2 > maxWidthPhoneLandscape
          ? maxWidthPhoneLandscape
          : 1.sw / 2,
      tabletPortrait: 1.sw - 40.w,
      tabletLandscape: 1.sw / 2 > maxWidthTablet ? maxWidthTablet : 1.sw / 2,
    );
  }

  static double getSizeIconBottomNavigationBar(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: 24.w,
      phoneLandscape: min(18.w, 16.h),
      tabletPortrait: 24.w,
      tabletLandscape: 24.w,
    );
  }

  static double getSizeLabelBottomNavigationBar(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: min(12.sp, 13.w),
      phoneLandscape: min(10.w, 12.sp),
      tabletPortrait: 12.w,
      tabletLandscape: 14.w,
    );
  }

  static double getBorderWidthTaskFeature(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: 0.2,
      phoneLandscape: 0.2,
      tabletPortrait: 0.4,
      tabletLandscape: 0.4,
    );
  }

  static double getAppBarHeight(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: kToolbarHeight,
      phoneLandscape: min(50.w, 40.w),
      tabletPortrait: min(kToolbarHeight, 54.w),
      tabletLandscape: min(kToolbarHeight, 50.w),
    );
  }

  static EdgeInsets getHorizontalMargin(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: EdgeInsets.symmetric(horizontal: 12.w),
      phoneLandscape: EdgeInsets.symmetric(horizontal: 12.w),
      tabletPortrait: EdgeInsets.symmetric(horizontal: 36.w),
      tabletLandscape: EdgeInsets.symmetric(horizontal: 36.w),
    );
  }

  static EdgeInsets getPaddingCard(BuildContext context) {
    return context.getValueByLayout(
      phonePortrait: const EdgeInsets.symmetric(vertical: 16, horizontal: 12).w,
      phoneLandscape: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 12,
      ).w,
      tabletPortrait: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 12,
      ).w,
      tabletLandscape: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 12,
      ).w,
    );
  }
}
