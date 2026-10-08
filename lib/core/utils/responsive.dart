import 'package:flutter/material.dart';

/// Phone vs tablet, in one place.
///
/// Tablets do not get a stretched interface: the content stays inside a
/// comfortable reading width and grids simply gain more columns.
abstract final class Responsive {
  /// Shortest side at or above this = tablet.
  static const double tabletBreakpoint = 600;

  /// Nothing on screen ever grows wider than this.
  static const double contentMaxWidth = 760;

  /// Column count for the album.
  static int albumColumns(BuildContext context) =>
      isTablet(context) ? 3 : 2;

  /// Column count for the character picker.
  static int characterColumns(BuildContext context) =>
      isTablet(context) ? 3 : 2;

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= tabletBreakpoint;
  }

  /// Slightly larger touch targets on a big screen (still ≥ 96 logical px).
  static double touchScale(BuildContext context) =>
      isTablet(context) ? 1.15 : 1.0;
}
