import 'dart:math';

import 'package:flutter/material.dart';

// Design sizes for different device types
const Size _phonePortraitSize = Size(412, 917);
const Size _phoneLandscapeSize = Size(917, 412);
const Size _tabletPortraitSize = Size(824, 1100); // iPad Air/Pro 11"
const Size _tabletLandscapeSize = Size(1180, 820);
const Size _largeTabletPortraitSize = Size(1030, 1375); // iPad Pro 12.9"
const Size _largeTabletLandscapeSize = Size(1375, 1030);

// Minimum text scaling factors
const double _minTabletTextScale = 1.15;
const double _minLargeTabletTextScale = 1.25;

double getScaleTextValue(BuildContext context, Size designSize, num fontSize) {
  final mediaQuery = MediaQuery.of(context);
  final DeviceLayoutType deviceType = getDeviceType(mediaQuery);
  final bool isLargeTablet =
      deviceType == DeviceLayoutType.tablet && isLargeTabletCheck(mediaQuery);

  // Get screen dimensions
  final width = mediaQuery.size.width;
  final height = mediaQuery.size.height;

  // Calculate base scaling factor - use min to prevent oversized text
  final baseScale = min(width / designSize.width, height / designSize.height);

  // Apply device-specific scaling adjustments
  double scaleFactor;
  switch (deviceType) {
    case DeviceLayoutType.phone:
      // For phones, use a modest scale increase
      scaleFactor = baseScale * 1.05;
      break;

    case DeviceLayoutType.tablet:
      // For tablets, ensure text is never too small
      final minScale = isLargeTablet
          ? _minLargeTabletTextScale
          : _minTabletTextScale;

      // Use the larger of the calculated scale or minimum tablet scale
      scaleFactor = max(baseScale, minScale);

      // If it's a very large tablet, add a bit more scaling
      // if (isLargeTablet && width > 1100) {
      //   scaleFactor *= 1.1;
      // }
      break;
  }

  final userAdjustedSize = fontSize * scaleFactor * 1.04;

  return userAdjustedSize.toDouble();
}

Size getDesignSize(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  // final width = mediaQuery.size.width;
  // final height = mediaQuery.size.height;
  final bool isLandscape = mediaQuery.orientation == Orientation.landscape;

  // Detect device type and size class
  final DeviceLayoutType deviceType = getDeviceType(mediaQuery);

  // Return appropriate design size based on device type and orientation
  switch (deviceType) {
    case DeviceLayoutType.phone:
      return isLandscape ? _phoneLandscapeSize : _phonePortraitSize;

    case DeviceLayoutType.tablet:
      // Check if it's a larger tablet
      final bool isLargeTablet = isLargeTabletCheck(mediaQuery);

      if (isLargeTablet) {
        return isLandscape
            ? _largeTabletLandscapeSize
            : _largeTabletPortraitSize;
      }
      return isLandscape ? _tabletLandscapeSize : _tabletPortraitSize;
  }
}

enum DeviceLayoutType { phone, tablet }

DeviceLayoutType getDeviceType(MediaQueryData mediaQuery) {
  final screenWidth = mediaQuery.size.width;
  final screenHeight = mediaQuery.size.height;
  final orientation = mediaQuery.orientation;

  final bool isTablet =
      (orientation == Orientation.portrait && screenWidth >= 600) ||
      (orientation == Orientation.landscape && screenHeight >= 600);

  // More sophisticated device type detection
  if (isTablet) {
    return DeviceLayoutType.tablet;
  }
  return DeviceLayoutType.phone;
}

bool isTablet(MediaQueryData query) {
  return getDeviceType(query) == DeviceLayoutType.tablet;
}

bool isLargeTabletCheck(MediaQueryData query) {
  final size = query.size;
  final diagonal = sqrt(
    (size.width * size.width) + (size.height * size.height),
  );
  // Consider iPad Pro 12.9" and larger devices as large tablets
  return diagonal > 1300.0;
}

extension DeviceLayoutX on BuildContext {
  T getValueByLayout<T>({
    required T phonePortrait,
    required T phoneLandscape,
    required T tabletPortrait,
    required T tabletLandscape,
  }) {
    final mediaQuery = MediaQuery.of(this);
    final deviceType = getDeviceType(mediaQuery);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    switch (deviceType) {
      case DeviceLayoutType.phone:
        return isLandscape ? phoneLandscape : phonePortrait;

      case DeviceLayoutType.tablet:
        return isLandscape ? tabletLandscape : tabletPortrait;
    }
  }
}
