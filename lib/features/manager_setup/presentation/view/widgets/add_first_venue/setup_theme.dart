import 'package:flutter/material.dart';

/// Shared colours for the venue-setup screen.
///
/// These were repeated as raw hex literals across every card on the screen,
/// which made a tweak to, say, the card border a search-and-replace across
/// hundreds of lines. Naming them once keeps the cards consistent.
// ignore: avoid_classes_with_only_static_members
abstract class SetupColors {
  /// Neutral card border.
  static const cardBorder = Color(0xffE8ECEF);

  /// Card border once that stage is finished.
  static const doneBorder = Color(0xffD7E8D3);

  /// Tinted surface for informational cards (wallet, ready, logo picker).
  static const tintedSurface = Color(0xffF7FBF6);

  /// Fill and border for inputs and tappable rows.
  static const fieldFill = Color(0xffFAFBFC);
  static const fieldBorder = Color(0xffD7DDE3);

  /// Muted text: hints, helper lines, unfilled values.
  static const muted = Color(0xff8A93A0);

  /// Body copy that is secondary to a heading.
  static const secondaryText = Color(0xff6D7580);

  /// Darkest tone of the hero gradient, reused for card shadows.
  static const heroDark = Color(0xff0B2417);
  static const heroLight = Color(0xff1E4B31);

  /// Soft lift used on every card so they read as separate surfaces.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: heroDark.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}
