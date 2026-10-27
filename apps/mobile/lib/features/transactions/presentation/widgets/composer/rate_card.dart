import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/money/money_text.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_card.dart';
import '../../viewmodels/transaction_composer.dart';

/// "Tỷ giá lúc 09:30, 21/10 · 1 VND = … USD" (tap to edit) and
/// "Nhận được". The rate and its time are saved with the transfer.
class RateCard extends StatelessWidget {
  const RateCard({required this.composer, required this.onEdit, super.key});

  final TransactionComposer composer;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final from = composer.source!.draft.currency;
    final to = composer.destination!.draft.currency;
    final quoted = composer.quotedAt == null
        ? null
        : DateTime.tryParse(composer.quotedAt!)?.toLocal();
    final received = composer.received;
    const tabular = [FontFeature.tabularFigures()];
    return FreevaCard(
      list: true,
      padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
      child: Column(
        children: [
          InkWell(
            onTap: onEdit,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quoted == null
                              ? s.txRateTitle
                              : s.txRateLabel(
                                  DateFormat(
                                    'HH:mm, dd/MM',
                                    locale,
                                  ).format(quoted),
                                ),
                          style: FreevaTypography.label.copyWith(
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                          ),
                        ),
                        Text(
                          composer.rate.isEmpty
                              ? s.txRateEmpty
                              : s.txRateValue(from, composer.rate, to),
                          style: FreevaTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: composer.rate.isEmpty
                                ? c.textLink
                                : c.textPrimary,
                            fontFeatures: tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.penLine,
                    size: FreevaSize.iconSm,
                    color: c.actionPrimary,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: c.listDivider),
          SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.txReceived,
                    style: FreevaTypography.body.copyWith(
                      fontSize: 14,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                if (received == null)
                  Text(
                    '—',
                    style: FreevaTypography.titleL.copyWith(
                      color: c.textPrimary,
                    ),
                  )
                else
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatMoneyText(
                            received,
                            composer.digitsOf(to),
                            locale,
                          ),
                        ),
                        TextSpan(
                          text: ' $to',
                          style: FreevaTypography.bodyS.copyWith(
                            fontWeight: FontWeight.w500,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    style: FreevaTypography.titleL.copyWith(
                      color: c.textPrimary,
                      fontFeatures: tabular,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
