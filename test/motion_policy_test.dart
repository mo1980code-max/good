import 'package:flutter_test/flutter_test.dart';
import 'package:sparkle_nail_spa/core/animations/motion_policy.dart';
import 'package:sparkle_nail_spa/core/animations/motion_tokens.dart';

/// Pure-logic tests for the Phase 2.3 motion rules.
///
/// Nothing here needs a device, a widget tree or Flutter bindings — which is
/// exactly why the rules were kept out of the widgets in the first place.
void main() {
  group('MotionTokens stay inside the agreed ranges', () {
    test('screen transitions are 250-400 ms', () {
      expect(MotionTokens.screenTransition.inMilliseconds, inInclusiveRange(250, 400));
      expect(
        MotionTokens.screenTransitionReverse.inMilliseconds,
        inInclusiveRange(250, 400),
      );
    });

    test('element entrances are 300-600 ms', () {
      expect(MotionTokens.entrance.inMilliseconds, inInclusiveRange(300, 600));
      expect(MotionTokens.entranceSlow.inMilliseconds, inInclusiveRange(300, 600));
    });

    test('selection feedback is 150-250 ms', () {
      expect(MotionTokens.selection.inMilliseconds, inInclusiveRange(150, 250));
      expect(MotionTokens.press.inMilliseconds, inInclusiveRange(100, 250));
    });

    test('the reveal celebration lasts about 2-3 seconds', () {
      expect(MotionTokens.revealSequence.inMilliseconds, inInclusiveRange(2000, 3000));

      // stars start inside the celebration and finish before it ends
      final int starsEnd = MotionTokens.starsBegin.inMilliseconds +
          MotionTokens.starStep.inMilliseconds * (MotionTokens.starCount - 1);
      expect(starsEnd, lessThan(MotionTokens.revealSequence.inMilliseconds));
    });

    test('ambient loops are slow enough to save battery', () {
      expect(MotionTokens.breathe.inMilliseconds, greaterThanOrEqualTo(2000));
      expect(MotionTokens.sparkleCycle.inMilliseconds, greaterThanOrEqualTo(2500));
    });
  });

  group('MotionPolicy.resolve', () {
    test('full motion only when both switches are off', () {
      expect(
        MotionPolicy.resolve(appSetting: false, systemDisablesAnimations: false)
            .reduceMotion,
        isFalse,
      );
    });

    test('the in-game toggle alone calms everything', () {
      expect(
        MotionPolicy.resolve(appSetting: true, systemDisablesAnimations: false)
            .reduceMotion,
        isTrue,
      );
    });

    test('the system setting alone calms everything', () {
      expect(
        MotionPolicy.resolve(appSetting: false, systemDisablesAnimations: true)
            .reduceMotion,
        isTrue,
      );
    });

    test('both on is still just "calm"', () {
      expect(
        MotionPolicy.resolve(appSetting: true, systemDisablesAnimations: true)
            .reduceMotion,
        isTrue,
      );
    });
  });

  group('MotionPolicy effects', () {
    test('calmed motion collapses durations and distances', () {
      const MotionPolicy calm = MotionPolicy.calm;
      expect(calm.scaled(MotionTokens.entrance).inMilliseconds, lessThanOrEqualTo(1));
      expect(calm.distance(MotionTokens.slideDistance), 0.0);
      expect(calm.allowLoopingMotion, isFalse);
      expect(calm.staggerFor(4), Duration.zero);
    });

    test('full motion keeps the tokens untouched', () {
      const MotionPolicy full = MotionPolicy.full;
      expect(full.scaled(MotionTokens.entrance), MotionTokens.entrance);
      expect(full.distance(MotionTokens.slideDistance), MotionTokens.slideDistance);
      expect(full.allowLoopingMotion, isTrue);
    });

    test('stagger stops growing past the cap', () {
      const MotionPolicy full = MotionPolicy.full;
      final Duration capped =
          full.staggerFor(MotionTokens.maxStaggerSteps + 10);
      expect(
        capped,
        MotionTokens.stagger * MotionTokens.maxStaggerSteps,
      );
      // and it is monotonically increasing before the cap
      expect(full.staggerFor(1), greaterThan(full.staggerFor(0)));
      expect(full.staggerFor(3), greaterThan(full.staggerFor(2)));
    });
  });
}
