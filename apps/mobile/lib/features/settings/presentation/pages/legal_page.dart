import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/router/nav_back.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/app_preferences.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final title = document == LegalDocument.terms ? s.tosTitle : s.privacyTitle;
    final body = document == LegalDocument.terms ? s.tosBody : s.privacyBody;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          tooltip: s.settingsBack,
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.popOrGo('/me'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.legalDraft),
              const SizedBox(height: 16),
              Text(body),
            ],
          ),
        ),
      ),
    );
  }
}
