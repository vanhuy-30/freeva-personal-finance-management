import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/pill_search_field.dart';

/// Câu hỏi thường gặp: search, one answer open at a time, and a way to send
/// feedback when the answer is not there.
class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  String query = '';
  int? open = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final margin = context.screenMargin;
    final items = [
      (s.faqRecordQ, s.faqRecordA),
      (s.faqTransferQ, s.faqTransferA),
      (s.faqDeletedQ, s.faqDeletedA),
      (s.faqMonthQ, s.faqMonthA),
      (s.faqLockAppQ, s.faqLockAppA),
      (s.faqSafeQ, s.faqSafeA),
    ];
    final needle = query.trim().toLowerCase();
    final shown = [
      for (final (i, item) in items.indexed)
        if (needle.isEmpty ||
            item.$1.toLowerCase().contains(needle) ||
            item.$2.toLowerCase().contains(needle))
          (i, item),
    ];
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.faqTitle,
        onLeading: () => context.popOrGo('/me'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  FreevaSpace.s2,
                  margin,
                  FreevaSpace.s4,
                ),
                children: [
                  PillSearchField(
                    hint: s.faqSearch,
                    onChanged: (value) => setState(() {
                      query = value;
                      open = null;
                    }),
                  ),
                  const SizedBox(height: FreevaSpace.s4),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(FreevaSpace.s6),
                      child: Text(
                        s.faqNoMatch,
                        textAlign: TextAlign.center,
                        style: FreevaTypography.bodyS.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    )
                  else
                    FreevaCard(
                      list: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: FreevaSpace.s4,
                      ),
                      child: Column(
                        children: [
                          for (final (n, (i, item)) in shown.indexed) ...[
                            if (n > 0) Divider(height: 1, color: c.listDivider),
                            _Question(
                              question: item.$1,
                              answer: item.$2,
                              expanded: open == i,
                              onTap: () =>
                                  setState(() => open = open == i ? null : i),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(margin, 0, margin, 28),
              child: _AskCard(onTap: () => context.push('/help/feedback')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          child: InkWell(
            onTap: onTap,
            splashFactory: NoSplash.splashFactory,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: FreevaSize.row),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: expanded
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: FreevaSpace.s3),
                  Icon(
                    expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: FreevaSize.iconSm,
                    color: expanded ? c.textLink : c.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: FreevaSpace.s4),
            child: Text(
              answer,
              style: FreevaTypography.bodyM.copyWith(
                height: 21 / 14,
                color: c.textOnWash,
              ),
            ),
          ),
      ],
    );
  }
}

/// "Chưa thấy câu trả lời?" at the bottom: subtle card, opens Góp ý.
class _AskCard extends StatelessWidget {
  const _AskCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaRadius.lg);
    return Material(
      color: c.bgSubtle,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashFactory: NoSplash.splashFactory,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  borderRadius: BorderRadius.circular(FreevaRadius.sm),
                ),
                child: Icon(
                  LucideIcons.messageSquare,
                  size: FreevaSize.iconSm,
                  color: c.actionPrimary,
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.faqMissing,
                      style: FreevaTypography.titleM.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      s.faqSend,
                      style: FreevaTypography.bodyS.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Icon(
                LucideIcons.chevronRight,
                size: FreevaSize.iconChip,
                color: c.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
