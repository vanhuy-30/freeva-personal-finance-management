import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../settings/presentation/widgets/danger_text_button.dart';
import '../viewmodels/import_view_model.dart';

/// Board `ImportDone`: how many came in, and a way to undo the whole batch.
class ImportDoneView extends StatelessWidget {
  const ImportDoneView({
    required this.model,
    required this.onView,
    required this.onUndo,
    super.key,
  });
  final ImportViewModel model;
  final VoidCallback onView;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final batch = model.result?.batch;
    final created = batch?.createdCount ?? 0;
    final duplicates = batch?.duplicateCount ?? 0;
    final invalid = batch?.invalidCount ?? 0;
    final skipped = duplicates > 0 && invalid > 0
        ? s.importDoneSkipBoth(duplicates, invalid)
        : duplicates > 0
        ? s.importDoneSkipDuplicates(duplicates)
        : invalid > 0
        ? s.importDoneSkipInvalid(invalid)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.statusSuccessBg,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 72,
                      child: Icon(
                        LucideIcons.check,
                        size: 32,
                        color: c.statusSuccess,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      s.importDoneTitle(created),
                      textAlign: TextAlign.center,
                      style: FreevaTypography.headline.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  if (skipped != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      skipped,
                      textAlign: TextAlign.center,
                      style: FreevaTypography.body.copyWith(
                        height: 22 / 15,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        FreevaButton(
          label: s.importDoneView,
          size: FreevaButtonSize.l,
          expand: true,
          onPressed: model.busy ? null : onView,
        ),
        const SizedBox(height: 10),
        DangerTextButton(
          icon: LucideIcons.undo2,
          label: s.importUndo,
          onPressed: model.busy || created == 0 ? null : onUndo,
        ),
        Text(
          s.importDoneKept,
          textAlign: TextAlign.center,
          style: FreevaTypography.bodyS.copyWith(
            height: 18 / 13,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
