import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/goal.dart';

/// Icon and tones of a goal kind, as drawn on the I boards: emergency green,
/// home blue, car violet, travel cyan, education yellow, wedding red,
/// retirement and other neutral.
class GoalLook {
  const GoalLook(this.icon, this.fill, this.stroke);
  final IconData icon;
  final Color fill;
  final Color stroke;
}

GoalLook goalLook(BuildContext context, String kind) {
  final c = context.colors;
  return switch (kind) {
    'emergency' => GoalLook(LucideIcons.shield, c.tintGreen, c.tintGreenFg),
    'home' => GoalLook(LucideIcons.house, c.tintBlue, c.tintBlueFg),
    'car' => GoalLook(LucideIcons.carFront, c.tintViolet, c.tintVioletFg),
    'travel' => GoalLook(LucideIcons.send, c.tintCyan, c.tintCyanFg),
    'education' => GoalLook(
      LucideIcons.graduationCap,
      c.statusWarningBg,
      c.statusWarning,
    ),
    'wedding' => GoalLook(LucideIcons.heart, c.statusDangerBg, c.statusDanger),
    'retirement' => GoalLook(LucideIcons.armchair, c.bgSubtle, c.textOnWash),
    _ => GoalLook(LucideIcons.star, c.bgSubtle, c.textOnWash),
  };
}

String goalKindLabel(S s, String kind) => switch (kind) {
  'emergency' => s.goalKindEmergency,
  'home' => s.goalKindHome,
  'car' => s.goalKindCar,
  'travel' => s.goalKindTravel,
  'education' => s.goalKindEducation,
  'wedding' => s.goalKindWedding,
  'retirement' => s.goalKindRetirement,
  _ => s.goalKindCustom,
};

/// Rounded icon tile of a goal: 40 radius 12 in lists, 44 radius 14 on the
/// detail card, 32 radius 10 in the Overview block, 28 radius 9 in chips,
/// 24 radius 8 in the first-run chips.
class GoalIconTile extends StatelessWidget {
  const GoalIconTile({required this.kind, this.size = 40, super.key});

  final String kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final look = goalLook(context, kind);
    final radius = switch (size) {
      >= 44 => 14.0,
      >= 40 => 12.0,
      >= 32 => 10.0,
      >= 28 => 9.0,
      _ => 8.0,
    };
    final glyph = switch (size) {
      >= 44 => 20.0,
      >= 40 => 19.0,
      >= 32 => 16.0,
      >= 28 => 15.0,
      _ => 14.0,
    };
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: look.fill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Icon(look.icon, size: glyph, color: look.stroke),
      ),
    );
  }
}

/// Bar colour of a goal: its kind's stroke, green once reached.
Color goalBarColor(BuildContext context, Goal goal) =>
    goal.status == GoalStatus.reached
    ? context.colors.statusSuccess
    : goalLook(context, goal.kind).stroke;

String _day(DateTime date, String pattern, String locale) =>
    DateFormat(pattern, locale).format(date);

/// "Còn 10 tháng · cần 8.000.000 mỗi tháng", "Hạn 30/09 đã qua · còn thiếu …",
/// "Đã đủ từ 12/09" — the line under a goal's bar.
String goalLine(S s, Goal goal, int digits, String locale) {
  String money(BigInt value) => formatMoneyText(value, digits, locale);
  switch (goal.status) {
    case GoalStatus.reached:
      return s.goalLineReached(_day(goal.updatedAt.toLocal(), 'dd/MM', locale));
    case GoalStatus.overdue:
      return s.goalLineOverdue(
        _day(DateTime.parse(goal.targetDate!), 'dd/MM', locale),
        money(goal.remainingMinor),
      );
    case GoalStatus.active:
      final months = goal.monthsLeft;
      final need = goal.requiredPerMonthMinor;
      if (months == null || need == null) return s.goalLineNoDate;
      return s.goalLineActive(months, money(need));
  }
}

/// "08/2027" for a `YYYY-MM-DD` target date.
String goalMonthLabel(String day, String locale) =>
    _day(DateTime.parse(day), 'MM/yyyy', locale);
