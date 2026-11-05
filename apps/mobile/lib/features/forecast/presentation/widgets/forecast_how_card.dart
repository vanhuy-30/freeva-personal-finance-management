import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../viewmodels/forecast_view_model.dart';

/// "Cách tính": where the start balance comes from (tap to edit) and what the
/// forecast leaves out.
class ForecastHowCard extends StatelessWidget {
  const ForecastHowCard({
    required this.model,
    required this.hidden,
    required this.onEdit,
    super.key,
  });

  final ForecastViewModel model;
  final bool hidden;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final forecast = model.data!;
    final amount = hidden
        ? '••••••'
        : formatMoneyText(
            forecast.startingBalanceMinor.abs(),
            model.digits,
            locale,
          );
    final signed = forecast.startingBalanceMinor.isNegative && !hidden
        ? '−$amount'
        : amount;
    final value = forecast.assumptions.fromWallets
        ? s.forecastStartsFromWallets(signed, model.walletCount)
        : s.forecastStartsFromYou(signed);
    final body = FreevaTypography.bodyS.copyWith(
      height: 19 / 13,
      color: c.textOnWash,
    );
    Widget note(String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(LucideIcons.info, size: 16, color: c.textSecondary),
        ),
        const SizedBox(width: FreevaSpace.s2),
        Expanded(child: Text(text, style: body)),
      ],
    );
    return FreevaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.forecastHowTitle,
            style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  color: c.bgSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.forecastStartsFrom,
                            style: FreevaTypography.label.copyWith(
                              fontWeight: FontWeight.w400,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value,
                            style: FreevaTypography.titleM.copyWith(
                              color: c.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      s.forecastEdit,
                      style: FreevaTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.actionPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          note(s.forecastScope),
          if (model.otherCurrencyCount > 0) ...[
            const SizedBox(height: 8),
            note(s.forecastOtherCurrency(model.otherCurrencyCount)),
          ],
        ],
      ),
    );
  }
}
