import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_dialog_input.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/pill_search_field.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../transactions/domain/transaction_filter.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../domain/tag.dart';
import '../../domain/tag_use_cases.dart';
import '../viewmodels/tag_manage_view_model.dart';
import '../widgets/tag_row.dart';

/// Nhãn: search, create, rename, delete. A pushed screen from Cá nhân.
class TagPage extends StatefulWidget {
  const TagPage({super.key});

  @override
  State<TagPage> createState() => _TagPageState();
}

class _TagPageState extends State<TagPage> {
  late final TagManageViewModel model = TagManageViewModel(
    getIt<TagUseCases>(),
    getIt<AuthViewModel>(),
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(model.load);
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  void _failed() {
    final s = S.of(context);
    final conflict = model.failure?.code == AuthError.conflict;
    showFreevaToast(context, message: conflict ? s.meConflict : s.meSaveError);
    if (conflict) model.load();
  }

  Future<void> _create() async {
    final s = S.of(context);
    final name = await showFreevaInputDialog(
      context: context,
      title: s.tagsAdd,
      label: s.tagsName,
    );
    if (name == null || name.trim().isEmpty) return;
    if (!await model.create(name) && mounted) _failed();
  }

  Future<void> _more(Tag tag) async {
    final s = S.of(context);
    final action = await showFreevaSheet<String>(
      context: context,
      title: tag.name,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.list),
            title: Text(s.tagsViewTransactions),
            onTap: () => Navigator.of(context).pop('view'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.pencil),
            title: Text(s.tagsRename),
            onTap: () => Navigator.of(context).pop('rename'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              LucideIcons.trash2,
              color: context.colors.statusDanger,
            ),
            title: Text(
              s.tagsDelete,
              style: TextStyle(color: context.colors.statusDanger),
            ),
            onTap: () => Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'view') {
      _open(tag);
    } else if (action == 'rename') {
      final name = await showFreevaInputDialog(
        context: context,
        title: s.tagsRenameTitle,
        label: s.tagsName,
        initial: tag.name,
      );
      if (name == null || name.trim().isEmpty || name.trim() == tag.name) {
        return;
      }
      if (!await model.rename(tag, name) && mounted) _failed();
    } else {
      final ok = await showFreevaConfirm(
        context: context,
        title: s.tagsDeleteTitle(tag.name),
        message: s.tagsDeleteBody,
        cancelLabel: s.commonCancel,
        confirmLabel: s.tagsDelete,
        destructive: true,
      );
      if (ok && !await model.delete(tag) && mounted) _failed();
    }
  }

  void _open(Tag tag) {
    final transactions = getIt<TransactionViewModel>();
    transactions.setFilter(
      TransactionFilter(period: PeriodPreset.allTime, tagIds: {tag.id}),
    );
    context.go('/transactions');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      final margin = context.screenMargin;
      final shown = model.shown;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.meTags,
          onLeading: () => context.popOrGo('/me'),
          action: FreevaIconButton(
            icon: LucideIcons.plus,
            label: s.tagsAdd,
            onPressed: model.loaded ? _create : null,
          ),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            margin,
            FreevaSpace.s2,
            margin,
            FreevaSpace.s8,
          ),
          children: [
            if (model.tags.isNotEmpty) ...[
              PillSearchField(hint: s.tagsSearch, onChanged: model.search),
              const SizedBox(height: FreevaSpace.s4),
            ],
            if (!model.loaded && model.failure != null)
              ErrorRetry(
                title: s.tagsLoadError,
                message: s.homeErrorBody,
                onRetry: model.load,
              )
            else if (!model.loaded)
              const SkeletonRows(count: 4)
            else if (model.tags.isEmpty)
              EmptyState(
                title: s.tagsEmptyTitle,
                message: s.tagsEmptyBody,
                actionLabel: s.tagsAdd,
                onAction: _create,
              )
            else if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.all(FreevaSpace.s6),
                child: Text(
                  s.tagsNoMatch,
                  textAlign: TextAlign.center,
                  style: FreevaTypography.bodyS.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              )
            else
              FreevaCard(
                list: true,
                padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
                child: Column(
                  children: [
                    for (final (i, tag) in shown.indexed) ...[
                      if (i > 0)
                        Divider(height: 1, color: context.colors.listDivider),
                      TagRow(tag: tag, onTap: () => _more(tag)),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}
