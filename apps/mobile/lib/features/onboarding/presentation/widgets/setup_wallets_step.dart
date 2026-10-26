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
import '../../../wallets/presentation/widgets/wallet_type_glyph.dart';
import '../../../../core/widgets/press_scale.dart';
import 'onboarding_frame.dart';
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
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => AuthScaffold(
        narrow: true,
        topGap: FreevaSpace.s5,
        trailing: OnboardingSkipLink(label: s.setupSkip, onPressed: onDone),
        footer: FreevaButton(
          label: s.authDone,
          size: FreevaButtonSize.l,
          expand: true,
          onPressed: onDone,
        ),
        children: [
          AuthTitle(
            s.setupWalletsTitle,
            subtitle: s.setupWalletsSub,
            start: true,
          ),
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
    final (bg, fg) = switch (type) {
      WalletType.bank => (c.tintBlue, c.tintBlueFg),
      WalletType.cash => (c.tintCyan, c.tintCyanFg),
      WalletType.ewallet => (c.tintViolet, c.tintVioletFg),
      WalletType.credit => (c.bgSubtle, c.textPrimary),
    };
    return FreevaCard(
      list: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(FreevaRadius.smd),
                ),
                child: WalletTypeGlyph(type: type, size: 21, color: fg),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: FreevaTypography.titleM.copyWith(
                  fontSize: 16,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (added == null)
              _AddButton(
                label: s.setupAdd,
                semantics: '${s.setupAdd} $label',
                onPressed: onAdd,
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: MoneyDisplay(
                  minor: added.balance,
                  currency: added.draft.currency,
                  minorDigits: minorDigits ?? 0,
                  style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
                  currencySize: 12,
                  currencyColor: c.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "+ Thêm": outlined pill, 38 high, 14/600.
class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.label,
    required this.semantics,
    required this.onPressed,
  });

  final String label;
  final String semantics;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: c.bgSurface,
          shape: StadiumBorder(side: BorderSide(color: c.borderDefault)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            splashFactory: NoSplash.splashFactory,
            onTap: onPressed,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.plus,
                    size: FreevaSize.iconXs,
                    color: c.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: FreevaTypography.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
