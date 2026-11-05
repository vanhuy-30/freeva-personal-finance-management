import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../viewmodels/import_view_model.dart';
import '../widgets/import_columns_view.dart';
import '../widgets/import_done_view.dart';
import '../widgets/import_map_view.dart';
import '../widgets/import_preview_view.dart';
import '../widgets/import_source_view.dart';

/// `MOB-P3-011` — Nhập giao dịch (boards `ImportSource`, `ImportColumns`,
/// `ImportMap`, `ImportPreview`, `ImportDone`). One route; the view model
/// holds the step so back walks the flow instead of leaving it.
class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final ImportViewModel model = getIt<ImportViewModel>();

  @override
  void initState() {
    super.initState();
    model.addListener(_changed);
    Future.microtask(model.load);
  }

  @override
  void dispose() {
    model.removeListener(_changed);
    model.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  /// Runs one step and says so when it failed.
  Future<void> _run(Future<Object?> Function() step) async {
    final message = S.of(context).importError;
    await step();
    if (!mounted || model.failure == null) return;
    showFreevaToast(context, message: message);
  }

  void _back() {
    if (!model.back()) context.popOrGo('/profile');
  }

  Future<void> _pick() => _run(model.chooseFile);
  Future<void> _columnsNext() => _run(model.continueFromColumns);
  Future<void> _preview() => _run(model.showPreview);
  Future<void> _commit() => _run(model.commit);

  Future<void> _undo() async {
    final s = S.of(context);
    final undone = await model.undo();
    if (!mounted) return;
    if (undone == null) {
      showFreevaToast(context, message: s.importUndoError);
      return;
    }
    showFreevaToast(context, message: s.importUndone(undone), success: true);
    context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final done = model.step == ImportStep.done;
    final title = switch (model.step) {
      ImportStep.columns => s.importColumnsTitle,
      ImportStep.map => s.importMapTitle,
      ImportStep.preview => s.importPreviewTitle,
      _ => s.importTitle,
    };
    final body = switch (model.step) {
      ImportStep.source => ImportSourceView(model: model, onPick: _pick),
      ImportStep.columns => ImportColumnsView(
        model: model,
        onNext: _columnsNext,
      ),
      ImportStep.map => ImportMapView(model: model, onPreview: _preview),
      ImportStep.preview => ImportPreviewView(model: model, onCommit: _commit),
      ImportStep.done => ImportDoneView(
        model: model,
        onView: () => context.go('/transactions'),
        onUndo: _undo,
      ),
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: done ? null : FreevaTopBar(title: title, onLeading: _back),
        body: SafeArea(
          top: done,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.screenMargin,
              0,
              context.screenMargin,
              FreevaSpace.s5,
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}
