import 'package:flutter/material.dart';

/// Centralized 8pt-based spacing and dimension system for HABos.
class AppSpacing {
  AppSpacing._();

  // ── 8pt Scale Scalars ──────────────────────────────────────────────────────
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 80.0;

  // ── Standard EdgeInsets ────────────────────────────────────────────────────
  static const EdgeInsets paddingXxs = EdgeInsets.all(xxs);
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  // ── Screen & Container Standard Paddings ───────────────────────────────────
  /// Standard screen body padding with clearance for bottom navigation and FABs
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(md, sm, md, 80.0);

  /// Standard card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  /// Hero moment card padding (Life Score, Focus Timer, Net Balance)
  static const EdgeInsets heroCardPadding = EdgeInsets.all(lg);

  /// Compact item / badge padding
  static const EdgeInsets badgePadding =
      EdgeInsets.symmetric(horizontal: sm, vertical: xs);

  // ── SizedBox Spacer Helpers (Gaps) ─────────────────────────────────────────
  static const SizedBox gapXxs = SizedBox(width: xxs, height: xxs);
  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);

  // Vertical Gaps
  static const SizedBox verticalGapXxs = SizedBox(height: xxs);
  static const SizedBox verticalGapXs = SizedBox(height: xs);
  static const SizedBox verticalGapSm = SizedBox(height: sm);
  static const SizedBox verticalGapMd = SizedBox(height: md);
  static const SizedBox verticalGapLg = SizedBox(height: lg);
  static const SizedBox verticalGapXl = SizedBox(height: xl);
  static const SizedBox verticalGapXxl = SizedBox(height: xxl);

  // Horizontal Gaps
  static const SizedBox horizontalGapXxs = SizedBox(width: xxs);
  static const SizedBox horizontalGapXs = SizedBox(width: xs);
  static const SizedBox horizontalGapSm = SizedBox(width: sm);
  static const SizedBox horizontalGapMd = SizedBox(width: md);
  static const SizedBox horizontalGapLg = SizedBox(width: lg);
  static const SizedBox horizontalGapXl = SizedBox(width: xl);
}

/// Centralized corner radius scale for HABos.
class AppRadius {
  AppRadius._();

  // ── Corner Radii Scalars ───────────────────────────────────────────────────
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double pill = 999.0;

  // ── Radius Constants ───────────────────────────────────────────────────────
  static const Radius radiusXs = Radius.circular(xs);
  static const Radius radiusSm = Radius.circular(sm);
  static const Radius radiusMd = Radius.circular(md);
  static const Radius radiusLg = Radius.circular(lg);
  static const Radius radiusXl = Radius.circular(xl);

  // ── BorderRadius Constants ─────────────────────────────────────────────────
  static const BorderRadius borderRadiusXs =
      BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderRadiusXl =
      BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderRadiusPill =
      BorderRadius.all(Radius.circular(pill));

  /// Standard card radius (lg = 20.0)
  static const BorderRadius card = borderRadiusLg;
  static const BorderRadius cardRadius = borderRadiusLg;

  /// Hero card radius (xl = 28.0)
  static const BorderRadius heroCard = borderRadiusXl;
  static const BorderRadius heroCardRadius = borderRadiusXl;

  /// Input field and button radius (md = 16.0)
  static const BorderRadius input = borderRadiusMd;
  static const BorderRadius inputRadius = borderRadiusMd;
  static const BorderRadius button = borderRadiusMd;
  static const BorderRadius buttonRadius = borderRadiusMd;

  /// Chip and badge radius (sm = 8.0)
  static const BorderRadius chip = borderRadiusSm;
  static const BorderRadius chipRadius = borderRadiusSm;
  static const BorderRadius badge = borderRadiusSm;
  static const BorderRadius badgeRadius = borderRadiusSm;

  /// Pill radius (999.0)
  static const BorderRadius pillRadius = borderRadiusPill;

  /// Dialog radius (xl = 28.0)
  static const BorderRadius dialog = borderRadiusXl;
  static const BorderRadius dialogRadius = borderRadiusXl;

  /// Bottom sheet radius (top xl)
  static const BorderRadius sheetRadius =
      BorderRadius.vertical(top: Radius.circular(xl));
}
