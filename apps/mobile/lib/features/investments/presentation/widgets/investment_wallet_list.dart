import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/wallet_type_icon.dart';

/// Radio list of wallets for "Lấy từ ví" (and later "Tiền về ví"). With
/// [allowExisting] a last row "Đã có từ trước · Không trừ ví" stands for a
/// buy that moves no wallet money; it is selected when [selected] is null.
class InvestmentWalletList extends StatelessWidget {
  const InvestmentWalletList({
    required this.wallets,
    required this.selected,
    required this.onChanged,
    required this.digitsOf,
    required this.hidden,
    this.allowExisting = true,
    super.key,
  });

  final List<Wallet> wallets;

  /// Wallet id, or null for "đã có từ trước".
  final String? selected;
  final ValueChanged<String?> onChanged;
  final int Function(String currency) digitsOf;
  final bool hidden;
  final bool allowExisting;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    Widget row({
      required Widget icon,
      required String title,
      required String subtitle,
      required bool on,
      required VoidCallback onTap,
    }) {
      return Semantics(
        button: true,
        selected: on,
        label: '$title, $subtitle',
        child: ExcludeSemantics(
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.bodyM.copyWith(
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.label.copyWith(
                              fontWeight: FontWeight.w400,
                              color: c.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Radio(on: on),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final rows = <Widget>[
      for (final w in wallets)
        row(
          icon: WalletTypeIcon(type: w.draft.type, size: 32),
          title: w.draft.name,
          subtitle: hidden
              ? '••••••'
              : s.investmentWalletLeft(
                  formatMoneyText(
                    w.balance,
                    digitsOf(w.draft.currency),
                    locale,
                  ),
                ),
          on: selected == w.id,
          onTap: () => onChanged(w.id),
        ),
      if (allowExisting)
        row(
          icon: DecoratedBox(
            decoration: BoxDecoration(
              color: c.bgSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox.square(
              dimension: 32,
              child: Icon(LucideIcons.history, size: 16, color: c.textOnWash),
            ),
          ),
          title: s.investmentExisting,
          subtitle: s.investmentExistingHint,
          on: selected == null,
          onTap: () => onChanged(null),
        ),
    ];
    return FreevaCard(
      list: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.borderDivider),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? c.actionPrimary : c.borderStrong,
          width: on ? 6 : 1.5,
        ),
      ),
    );
  }
}
