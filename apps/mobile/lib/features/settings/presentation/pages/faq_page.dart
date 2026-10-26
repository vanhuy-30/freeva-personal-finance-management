import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  int? open;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final margin = context.screenMargin;
    final items = [
      (s.faqWalletQ, s.faqWalletA),
      (s.faqTransactionQ, s.faqTransactionA),
      (s.faqProfileQ, s.faqProfileA),
      (s.faqLockQ, s.faqLockA),
      (s.faqThemeQ, s.faqThemeA),
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          margin,
          FreevaSpace.s2,
          margin,
          FreevaSpace.s8,
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
                style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
              ),
            )
          else
            FreevaCard(
              list: true,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (n, (i, item)) in shown.indexed) ...[
                    if (n > 0) Divider(height: 1, color: c.listDivider),
                    _Question(
                      question: item.$1,
                      answer: item.$2,
                      expanded: open == i,
                      onTap: () => setState(() => open = open == i ? null : i),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: FreevaSpace.s4),
          FreevaCard(
            list: true,
            onTap: () => context.push('/help/feedback'),
            padding: const EdgeInsets.all(FreevaSpace.s4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: c.tintBlue,
                    borderRadius: BorderRadius.circular(FreevaRadius.sm),
                  ),
                  child: Icon(
                    LucideIcons.messageSquare,
                    size: FreevaSize.iconInline,
                    color: c.tintBlueFg,
                  ),
                ),
                const SizedBox(width: FreevaSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.faqMissing,
                        style: FreevaTypography.bodyS.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      Text(
                        s.faqSend,
                        style: FreevaTypography.titleM.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
        ],
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FreevaSpace.s4,
                vertical: FreevaSpace.s3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: FreevaTypography.titleM.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: FreevaSpace.s2),
                  Icon(
                    expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: c.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FreevaSpace.s4,
              0,
              FreevaSpace.s4,
              FreevaSpace.s4,
            ),
            child: Text(
              answer,
              style: FreevaTypography.body.copyWith(
                fontSize: 14,
                color: c.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
