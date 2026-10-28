import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../domain/app_preferences.dart';

/// Terms, privacy, or both ("Điều khoản và quyền riêng tư" from Cá nhân).
class LegalPage extends StatelessWidget {
  const LegalPage({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final title = switch (document) {
      LegalDocument.terms => s.tosTitle,
      LegalDocument.privacy => s.privacyTitle,
      LegalDocument.all => s.meLegal,
    };
    final sections = switch (document) {
      LegalDocument.terms => [(null, s.tosBody)],
      LegalDocument.privacy => [(null, s.privacyBody)],
      LegalDocument.all => [
        (s.tosTitle, s.tosBody),
        (s.privacyTitle, s.privacyBody),
      ],
    };
    final body = FreevaTypography.body.copyWith(color: c.textPrimary);
    return Scaffold(
      appBar: FreevaTopBar(
        title: title,
        onLeading: () => context.popOrGo('/me'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            context.screenMargin,
            FreevaSpace.s2,
            context.screenMargin,
            FreevaSpace.s8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.legalDraft,
                style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
              ),
              for (final (heading, text) in sections) ...[
                const SizedBox(height: FreevaSpace.s4),
                if (heading != null) ...[
                  Semantics(
                    header: true,
                    child: Text(
                      heading,
                      style: FreevaTypography.titleM.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: FreevaSpace.s2),
                ],
                Text(text, style: body),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
