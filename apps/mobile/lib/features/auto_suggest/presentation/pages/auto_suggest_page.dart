import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../domain/merchant_mapping.dart';
import '../viewmodels/auto_suggest_view_model.dart';
import '../widgets/auto_suggest_switch_card.dart';
import '../widgets/merchant_group.dart';
import '../widgets/privacy_hint.dart';

/// U.1 Gợi ý tự động (MOB-P5-002): the switch, a privacy line and the
/// remembered merchants with "Xoá dữ liệu đã học". With nothing remembered
/// only the switch and the line show.
class AutoSuggestPage extends StatefulWidget {
  const AutoSuggestPage({super.key});

  @override
  State<AutoSuggestPage> createState() => _AutoSuggestPageState();
}

class _AutoSuggestPageState extends State<AutoSuggestPage> {
  late final AutoSuggestViewModel _model = getIt<AutoSuggestViewModel>();
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _model.load());
  }

  void _toastIfFailed(bool ok) {
    if (ok || !mounted) return;
    showFreevaToast(
      context,
      message: S.of(context).autoSuggestError,
      aboveNav: false,
    );
  }

  Future<void> _toggle(bool value) async =>
      _toastIfFailed(await _model.setEnabled(value));

  Future<void> _forget(MerchantMapping mapping) async =>
      _toastIfFailed(await _model.forget(mapping));

  Future<void> _clear() async {
    final s = S.of(context);
    final ok = await showFreevaConfirm(
      context: context,
      title: s.autoSuggestClearTitle,
      message: s.autoSuggestClearBody(_model.mappings.length),
      icon: LucideIcons.trash,
      cancelLabel: s.commonCancel,
      confirmLabel: s.autoSuggestDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    _toastIfFailed(await _model.clearAll());
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _model,
    builder: (context, _) {
      final s = S.of(context);
      final margin = context.screenMargin;
      final mappings = _model.mappings;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.autoSuggestTitle,
          onLeading: () => context.popOrGo('/me'),
        ),
        body: ListView(
          // Board: 14 between the header row and the first card.
          padding: EdgeInsets.fromLTRB(margin, 6, margin, FreevaSpace.s8),
          children: [
            AutoSuggestSwitchCard(on: _model.enabled, onChanged: _toggle),
            const SizedBox(height: 10),
            const PrivacyHint(),
            if (mappings.isNotEmpty) ...[
              const SizedBox(height: 22),
              MerchantGroup(
                mappings: mappings,
                expanded: _expanded,
                onExpand: () => setState(() => _expanded = true),
                onForget: _forget,
              ),
              const SizedBox(height: 22),
              FreevaButton(
                label: s.autoSuggestClear,
                icon: LucideIcons.trash,
                variant: FreevaButtonVariant.dangerOutline,
                size: FreevaButtonSize.dialog,
                expand: true,
                onPressed: _clear,
              ),
            ],
          ],
        ),
      );
    },
  );
}
