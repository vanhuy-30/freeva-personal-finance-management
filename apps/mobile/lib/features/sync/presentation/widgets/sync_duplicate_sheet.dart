import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/widgets/transaction_naming.dart';
import 'sync_labels.dart';

/// What the person chose on "Có thể bạn đã ghi rồi".
enum DuplicateChoice { keepBoth, deleteNew }

/// Sheet for a transaction that synced and looks like an earlier one: the new
/// one (soft blue) above the one that was already there. Closing it by
/// swiping counts as keeping both.
Future<DuplicateChoice> showSyncDuplicateSheet(
  BuildContext context, {
  required TransactionBundle recorded,
  required TransactionBundle existing,
  required TransactionNaming naming,
  required int Function(String) digitsOf,
}) async {
  final s = S.of(context);
  final choice = await showFreevaSheet<DuplicateChoice>(
    context: context,
    title: s.syncDupTitle,
    subtitle: s.syncDupSub,
    builder: (context) => SyncDuplicateBody(
      recorded: recorded,
      existing: existing,
      naming: naming,
      digitsOf: digitsOf,
    ),
  );
  return choice ?? DuplicateChoice.keepBoth;
}

class SyncDuplicateBody extends StatelessWidget {
  const SyncDuplicateBody({
    required this.recorded,
    required this.existing,
    required this.naming,
    required this.digitsOf,
    super.key,
  });

  final TransactionBundle recorded;
  final TransactionBundle existing;
  final TransactionNaming naming;
  final int Function(String) digitsOf;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final caption = FreevaTypography.overline.copyWith(
      letterSpacing: 1,
      color: c.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: Text(s.syncDupJust, style: caption)),
        const SizedBox(height: FreevaSpace.s2),
        _Card(
          caption: s.syncDupJust,
          bundle: recorded,
          naming: naming,
          digits: digitsOf(recorded.legs.first.currencyCode),
          fresh: true,
        ),
        const SizedBox(height: FreevaSpace.s3),
        ExcludeSemantics(child: Text(s.syncDupExisting, style: caption)),
        const SizedBox(height: FreevaSpace.s2),
        _Card(
          caption: s.syncDupExisting,
          bundle: existing,
          naming: naming,
          digits: digitsOf(existing.legs.first.currencyCode),
          fresh: false,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FreevaButton(
                label: s.syncDupKeepBoth,
                variant: FreevaButtonVariant.secondary,
                expand: true,
                onPressed: () =>
                    Navigator.of(context).pop(DuplicateChoice.keepBoth),
              ),
            ),
            const SizedBox(width: FreevaSpace.s2),
            Expanded(
              child: FreevaButton(
                label: s.syncDupDeleteNew,
                variant: FreevaButtonVariant.ink,
                expand: true,
                onPressed: () =>
                    Navigator.of(context).pop(DuplicateChoice.deleteNew),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.caption,
    required this.bundle,
    required this.naming,
    required this.digits,
    required this.fresh,
  });

  final String caption;
  final TransactionBundle bundle;
  final TransactionNaming naming;
  final int digits;
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    final label = naming.label(bundle);
    final locale = Localizations.localeOf(context).toString();
    final when = syncWhen(
      s,
      bundle.legs.first.createdAt,
      DateTime.now(),
      locale,
    );
    return Semantics(
      container: true,
      label: '$caption, ${label.title}, ${label.detail}, $when',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: fresh ? c.tintBlue : c.bgSurface,
            borderRadius: BorderRadius.circular(FreevaRadius.md),
            border: Border.all(
              color: fresh ? c.actionPrimary : c.borderDefault,
              width: fresh ? FreevaBorder.selected : FreevaBorder.defaultValue,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: fresh ? c.bgSurface : c.bgSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  label.icon,
                  size: FreevaSize.iconSm,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.title,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${label.detail} · $when',
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FreevaSpace.s2),
              MoneyDisplay(
                minor: label.minor,
                currency: label.currency,
                minorDigits: digits,
                tone: label.tone,
                style: FreevaTypography.titleM,
                showCurrency: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
