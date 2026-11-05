import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../categories/presentation/widgets/category_icon_tile.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/wallet_type_icon.dart';
import '../viewmodels/import_view_model.dart';
import 'import_pick_sheet.dart';

/// Board `ImportMap`: names from the file matched to Freeva wallets and
/// categories. Names that are not matched yet are dashed.
class ImportMapView extends StatelessWidget {
  const ImportMapView({
    required this.model,
    required this.onPreview,
    super.key,
  });
  final ImportViewModel model;
  final VoidCallback onPreview;

  Future<void> _pickWallet(
    BuildContext context,
    String? selected,
    ValueChanged<String> onPick,
  ) async {
    final picked = await showImportPickSheet<String>(
      context,
      title: S.of(context).importPickWallet,
      selected: selected,
      options: [
        for (final w in model.wallets) ImportPickOption(w.id, w.draft.name),
      ],
    );
    if (picked?.value != null) onPick(picked!.value!);
  }

  Future<void> _pickCategory(
    BuildContext context,
    String? selected,
    ValueChanged<String> onPick,
  ) async {
    final names = {for (final c in model.categories) c.id: c.name};
    final picked = await showImportPickSheet<String>(
      context,
      title: S.of(context).importPickCategory,
      selected: selected,
      options: [
        for (final c in model.categories)
          ImportPickOption(
            c.id,
            c.parentId == null || names[c.parentId] == null
                ? c.name
                : '${names[c.parentId]} · ${c.name}',
          ),
      ],
    );
    if (picked?.value != null) onPick(picked!.value!);
  }

  Wallet? _wallet(String? id) =>
      model.wallets.where((w) => w.id == id).firstOrNull;
  FinanceCategory? _category(String? id) =>
      model.categories.where((c) => c.id == id).firstOrNull;

  Widget? _walletTile(String? id) {
    final wallet = _wallet(id);
    return wallet == null
        ? null
        : WalletTypeIcon(type: wallet.draft.type, size: 24, iconSize: 14);
  }

  Widget? _categoryTile(String? id) {
    final category = _category(id);
    return category == null
        ? null
        : CategoryIconTile(
            iconToken: category.iconToken,
            colorToken: category.colorToken,
            size: 24,
          );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final remaining = model.unmappedCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: FreevaSpace.s2),
            children: [
              if (remaining > 0) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.statusWarningBg,
                    borderRadius: BorderRadius.circular(FreevaRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: FreevaSize.iconInline,
                          color: c.statusWarning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.importMapRemaining(remaining),
                            style: FreevaTypography.bodyM.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (model.walletNames.isNotEmpty || model.needsDefaultWallet)
                SettingsGroup(
                  title: s.importMapWallets,
                  children: [
                    if (model.needsDefaultWallet)
                      _MapRow(
                        source: s.importMapAllRows,
                        target: _wallet(model.defaultWalletId)?.draft.name,
                        leading: _walletTile(model.defaultWalletId),
                        choose: s.importMapChoose,
                        onTap: () => _pickWallet(
                          context,
                          model.defaultWalletId,
                          model.selectDefaultWallet,
                        ),
                      ),
                    for (final name in model.walletNames)
                      _MapRow(
                        source: name,
                        target: _wallet(model.walletMap[name])?.draft.name,
                        leading: _walletTile(model.walletMap[name]),
                        choose: s.importMapChoose,
                        onTap: () => _pickWallet(
                          context,
                          model.walletMap[name],
                          (id) => model.mapWallet(name, id),
                        ),
                      ),
                  ],
                ),
              if (model.categoryNames.isNotEmpty)
                SettingsGroup(
                  title: s.importMapCategories,
                  children: [
                    for (final name in model.categoryNames)
                      _MapRow(
                        source: name,
                        target: _category(model.categoryMap[name])?.name,
                        leading: _categoryTile(model.categoryMap[name]),
                        choose: s.importMapChoose,
                        onTap: () => _pickCategory(
                          context,
                          model.categoryMap[name],
                          (id) => model.mapCategory(name, id),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        FreevaButton(
          label: s.importMapPreview,
          size: FreevaButtonSize.l,
          expand: true,
          loading: model.busy,
          onPressed: model.canPreview ? onPreview : null,
        ),
      ],
    );
  }
}

class _MapRow extends StatelessWidget {
  const _MapRow({
    required this.source,
    required this.target,
    required this.choose,
    required this.onTap,
    this.leading,
  });
  final String source;
  final String? target;
  final Widget? leading;
  final String choose;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  source,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  LucideIcons.arrowRight,
                  size: 16,
                  color: c.textMuted,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.6,
                ),
                child: ImportPill(
                  label: target ?? choose,
                  dashed: target == null,
                  leading: leading,
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
