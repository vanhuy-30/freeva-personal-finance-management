import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/dashed_outline_button.dart';
import '../../../../../core/widgets/freeva_chip.dart';
import '../../../../categories/presentation/widgets/category_badge.dart';
import '../../../../wallets/domain/wallet.dart';
import '../../../../wallets/presentation/widgets/wallet_type_glyph.dart';
import '../../viewmodels/transaction_composer.dart';
import '../transaction_day_header.dart';
import 'composer_pickers.dart';
import 'field_tile.dart';

/// C2.1 under the amount: 3 frequent categories + "Tất cả", the Ví and Ngày
/// tiles, and the dashed "Ghi chú, cửa hàng, nhãn" button.
class QuickFields extends StatelessWidget {
  const QuickFields({required this.composer, required this.onMore, super.key});

  final TransactionComposer composer;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final pick = ComposerPickers(context, composer);
    final locale = Localizations.localeOf(context).toString();
    final today = composer.model.today() ?? '';
    final source = composer.source;
    // Wallet type two-tone, as on the wallet list (cash cyan on the board).
    final (bg, fg) = switch (source?.draft.type) {
      WalletType.bank => (c.tintBlue, c.tintBlueFg),
      WalletType.ewallet => (c.tintViolet, c.tintVioletFg),
      WalletType.credit => (c.bgSubtle, c.textPrimary),
      _ => (c.tintCyan, c.tintCyanFg),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in composer.quick)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FreevaChip(
                    label: cat.name,
                    icon: cat.id == composer.categoryId
                        ? categoryIcon(cat.iconToken)
                        : null,
                    selected: cat.id == composer.categoryId,
                    onTap: () => composer.pickCategory(cat.id),
                  ),
                ),
              FreevaChip(
                label: s.transactionAll,
                icon: LucideIcons.layoutGrid,
                selected: false,
                onTap: pick.category,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FieldTile(
                icon: LucideIcons.wallet,
                glyph: source == null
                    ? null
                    : WalletTypeGlyph(
                        type: source.draft.type,
                        size: FreevaSize.iconChip,
                        color: fg,
                      ),
                iconBg: bg,
                iconFg: fg,
                label: s.txDetailWallet,
                value: source?.draft.name ?? s.txPickWallet,
                onTap: pick.wallet,
              ),
            ),
            const SizedBox(width: FreevaSpace.s2),
            Expanded(
              child: FieldTile(
                icon: LucideIcons.calendar,
                label: s.txDateLabel,
                value: composer.occurredOn.isEmpty
                    ? ''
                    : TransactionDayHeader.label(
                        s,
                        composer.occurredOn,
                        today,
                        locale,
                      ).split(' · ').first,
                onTap: pick.date,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        DashedOutlineButton(
          label: s.txMoreButton,
          icon: LucideIcons.plus,
          onTap: onMore,
        ),
      ],
    );
  }
}
