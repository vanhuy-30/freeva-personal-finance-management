import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/wallet_labels.dart';
import '../../../wallets/presentation/widgets/wallet_type_icon.dart';
import '../viewmodels/setup_wallets_view_model.dart';
import 'setup_wallet_form_page.dart';

/// Thiết lập tài chính: where the money is. One row per wallet type with
/// "+ Thêm", or the balance once added. "Bỏ qua" and "Xong" both go on.
class SetupWalletsStep extends StatelessWidget {
  const SetupWalletsStep({
    required this.model,
    required this.onDone,
    super.key,
  });

  final SetupWalletsViewModel model;
  final VoidCallback onDone;

  static const order = [
    WalletType.cash,
    WalletType.bank,
    WalletType.ewallet,
    WalletType.credit,
  ];

  Future<void> _add(BuildContext context, WalletType type) async {
    final failed = S.of(context).walletError;
    if (!await model.ensureCurrencies()) {
      if (context.mounted) showFreevaToast(context, message: failed);
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => SetupWalletFormPage(model: model, type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => AuthScaffold(
        trailing: TextButton(
          onPressed: onDone,
          child: Text(
            s.setupSkip,
            style: FreevaTypography.titleM.copyWith(
              fontSize: 15,
              color: c.textSecondary,
            ),
          ),
        ),
        footer: FreevaButton(
          label: s.authDone,
          size: FreevaButtonSize.l,
          expand: true,
          onPressed: onDone,
        ),
        children: [
          AuthTitle(s.setupWalletsTitle, subtitle: s.setupWalletsSub),
          const SizedBox(height: FreevaSpace.s6),
          for (final type in order) ...[
            _TypeRow(
              type: type,
              wallet: model.added[type],
              minorDigits: model.currencies
                  .where((x) => x.code == model.added[type]?.draft.currency)
                  .firstOrNull
                  ?.minorDigits,
              onAdd: () => _add(context, type),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.wallet,
    required this.minorDigits,
    required this.onAdd,
  });

  final WalletType type;
  final Wallet? wallet;
  final int? minorDigits;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final label = walletTypeLabel(s, type);
    final added = wallet;
    return FreevaCard(
      list: true,
      semanticsLabel: added == null ? '${s.setupAdd} $label' : null,
      onTap: added == null ? onAdd : null,
      child: Row(
        children: [
          WalletTypeIcon(type: type, size: 36),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Text(
              added?.draft.name ?? label,
              style: FreevaTypography.body.copyWith(color: c.textPrimary),
            ),
          ),
          if (added == null)
            ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.plus, size: 16, color: c.textLink),
                  const SizedBox(width: FreevaSpace.s1),
                  Text(
                    s.setupAdd,
                    style: FreevaTypography.label.copyWith(color: c.textLink),
                  ),
                ],
              ),
            )
          else
            MoneyDisplay(
              minor: added.balance,
              currency: added.draft.currency,
              minorDigits: minorDigits ?? 0,
              style: FreevaTypography.moneyL.copyWith(fontSize: 16),
            ),
        ],
      ),
    );
  }
}
