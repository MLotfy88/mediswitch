import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A utility class that provides animation presets similar to framer-motion
/// This allows for consistent animations across the app
class AnimationUtils {
  // Duration presets
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 800);

  // Easing presets
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve linear = Curves.linear;
  static const Curve decelerate = Curves.decelerate;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve bounceInOut = Curves.bounceInOut;

  // Animation presets

  /// Fade in animation
  static Effect fadeIn({
    Duration? duration,
    Curve? curve,
    double from = 0.0,
    double to = 1.0,
  }) {
    return FadeEffect(
      duration: duration ?? durationNormal,
      curve: curve ?? easeOut,
      begin: from,
      end: to,
    );
  }

  /// Fade out animation
  static Effect fadeOut({Duration? duration, Curve? curve}) {
    return FadeEffect(
      duration: duration ?? durationNormal,
      curve: curve ?? easeOut,
      begin: 1.0,
      end: 0.0,
    );
  }

  /// Scale animation
  static Effect scale({
    Duration? duration,
    Curve? curve,
    double from = 0.8,
    double to = 1.0,
  }) {
    return ScaleEffect(
      duration: duration ?? durationNormal,
      curve: curve ?? easeOut,
      begin: Offset(from, from),
      end: Offset(to, to),
    );
  }

  /// Slide animation
  static Effect slideX({
    Duration? duration,
    Curve? curve,
    double from = -50,
    double to = 0,
  }) {
    return SlideEffect(
      duration: duration ?? durationNormal,
      curve: curve ?? easeOut,
      begin: Offset(from, 0),
      end: Offset(to, 0),
    );
  }

  /// Slide animation (vertical)
  static Effect slideY({
    Duration? duration,
    Curve? curve,
    double from = -50,
    double to = 0,
  }) {
    return SlideEffect(
      duration: duration ?? durationNormal,
      curve: curve ?? easeOut,
      begin: Offset(0, from),
      end: Offset(0, to),
    );
  }

  /// Blur animation
  static Effect blur({
    Duration? duration,
    Curve? curve,
    double from = 5.0,
    double to = 0.0,
  }) {
    return BlurEffect(
      duration: duration ?? durationNormal,
      curve: curve ?? easeOut,
      begin: Offset(from, from),
      end: Offset(to, to),
    );
  }

  /// Shake animation
  static Effect shake({
    Duration? duration,
    double amount = 10.0,
    int count = 3,
  }) {
    return ShakeEffect(
      duration: duration ?? durationNormal,
      hz: count.toDouble(),
      offset: Offset(amount, 0),
    );
  }

  /// Bounce animation
  static Effect bounce({
    Duration? duration,
    double amount = 0.2,
    int count = 2,
  }) {
    return ShakeEffect(
      duration: duration ?? durationNormal,
      hz: count.toDouble(),
      offset: Offset(0, amount),
      curve: Curves.bounceOut,
    );
  }

  /// Flip animation
  static Effect flip({
    Duration? duration,
    Curve? curve,
    double from = 0.0,
    double to = 1.0,
  }) {
    return FlipEffect(
      duration: duration ?? durationSlow,
      curve: curve ?? easeInOut,
      begin: from,
      end: to,
    );
  }

  /// Common animation combinations

  /// Fade in and slide from bottom
  static List<Effect> fadeInUp({Duration? duration, Curve? curve}) {
    return [
      fadeIn(duration: duration, curve: curve),
      slideY(from: 50, to: 0, duration: duration, curve: curve),
    ];
  }

  /// Fade in and slide from top
  static List<Effect> fadeInDown({Duration? duration, Curve? curve}) {
    return [
      fadeIn(duration: duration, curve: curve),
      slideY(from: -50, to: 0, duration: duration, curve: curve),
    ];
  }

  /// Fade in and slide from left
  static List<Effect> fadeInLeft({Duration? duration, Curve? curve}) {
    return [
      fadeIn(duration: duration, curve: curve),
      slideX(from: -50, to: 0, duration: duration, curve: curve),
    ];
  }

  /// Fade in and slide from right
  static List<Effect> fadeInRight({Duration? duration, Curve? curve}) {
    return [
      fadeIn(duration: duration, curve: curve),
      slideX(from: 50, to: 0, duration: duration, curve: curve),
    ];
  }

  /// Fade in and scale up
  static List<Effect> fadeInScale({Duration? duration, Curve? curve}) {
    return [
      fadeIn(duration: duration, curve: curve),
      scale(from: 0.8, to: 1.0, duration: duration, curve: curve),
    ];
  }
}
