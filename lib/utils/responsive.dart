import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double height(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static bool isSmallPhone(BuildContext context) {
    return width(context) < 360;
  }

  static bool isTablet(BuildContext context) {
    return width(context) >= 600;
  }

  static double horizontalPadding(BuildContext context) {
    final screenWidth = width(context);

    if (screenWidth >= 600) {
      return 48;
    }

    if (screenWidth < 360) {
      return 16;
    }

    return 20;
  }

  static double contentMaxWidth(BuildContext context) {
    if (isTablet(context)) {
      return 520;
    }

    return double.infinity;
  }
}
