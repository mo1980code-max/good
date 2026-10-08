import 'package:flutter/services.dart';

/// Gentle haptics only — never a sharp buzz, never scary
/// (GDD law: "no startling effects for little hands").
abstract final class FeedbackHelper {
  static bool enabled = true;

  static Future<void> tap() => _run(HapticFeedback.selectionClick);

  static Future<void> success() => _run(HapticFeedback.lightImpact);

  static Future<void> celebrate() => _run(HapticFeedback.mediumImpact);

  static Future<void> _run(Future<void> Function() action) async {
    if (!enabled) return;
    try {
      await action();
    } catch (_) {
      // Some devices / platforms simply have no haptics.
    }
  }
}
