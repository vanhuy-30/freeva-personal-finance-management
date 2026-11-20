import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../server_config/domain/app_limits.dart';
import '../../domain/overview.dart';
import 'glance_tile.dart';

/// "Thẻ tín dụng": the card that needs attention most (highest use), its
/// share of the limit with the level colour, its name and due date.
class CardTile extends StatelessWidget {
  const CardTile({required this.cards, super.key});

  /// Not empty.
  final List<CreditCardStatus> cards;

  /// The card shown: highest use of its limit, then nearest due date.
  static CreditCardStatus pick(List<CreditCardStatus> cards) {
    final sorted = [...cards]
      ..sort((a, b) {
        final byRatio = b.ratio.compareTo(a.ratio);
        if (byRatio != 0) return byRatio;
        final ad = a.nextDue, bd = b.nextDue;
        if (ad == null || bd == null) return ad == null ? 1 : -1;
        return ad.compareTo(bd);
      });
    return sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final card = pick(cards);
    final limits = getIt<AppLimitsSource>().requireLimits;
    final color = switch (card.levelWith(limits)) {
      CreditLevel.normal => c.data1,
      CreditLevel.high => FreevaPrimitive.amber500,
      CreditLevel.critical => FreevaPrimitive.red500,
    };
    final percent = (card.ratio * 100).round();
    final due = card.nextDue;
    final name = card.wallet.draft.name;
    final line = due == null
        ? name
        : s.homeCardDue(name, DateFormat('dd/MM', locale).format(due));
    return GlanceTile(
      semanticsLabel: '${s.homeCreditTitle} $percent% ${s.homeCardUsed}, $line',
      onTap: () => context.push('/wallets/${card.wallet.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlanceHeader(
            icon: LucideIcons.creditCard,
            label: s.homeCreditTitle,
            bg: c.bgSubtle,
            fg: c.textPrimary,
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '$percent% '),
                    TextSpan(
                      text: s.homeCardUsed,
                      style: FreevaTypography.bodyS.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
                style: glanceBig(context),
              ),
              const SizedBox(height: FreevaSpace.s2),
              FreevaProgressBar(value: card.ratio, color: color, height: 6),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            line,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: glanceNote(context),
          ),
        ],
      ),
    );
  }
}
