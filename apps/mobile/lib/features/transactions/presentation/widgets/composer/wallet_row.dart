import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../wallets/domain/wallet.dart';

/// 60-high wallet row in the transfer card: icon, "Từ"/"Đến", name, code.
class WalletRow extends StatelessWidget {
  const WalletRow({
    required this.label,
    required this.wallet,
    required this.placeholder,
    required this.iconBg,
    required this.iconFg,
    required this.onTap,
    super.key,
  });

  final String label;
  final Wallet? wallet;
  final String placeholder;
  final Color iconBg;
  final Color iconFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final name = wallet?.draft.name ?? placeholder;
    return Semantics(
      button: true,
      label: '$label, $name',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(FreevaRadius.sm),
                ),
                child: Icon(LucideIcons.wallet, size: 18, color: iconFg),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
                    Text(
                      name,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: wallet == null ? c.textSecondary : c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (wallet != null)
                Padding(
                  padding: const EdgeInsets.only(right: 52),
                  child: Text(
                    wallet!.draft.currency,
                    style: FreevaTypography.bodyS.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
