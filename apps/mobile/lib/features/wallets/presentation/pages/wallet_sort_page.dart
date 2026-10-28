import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../domain/wallet.dart';
import '../viewmodels/wallet_view_model.dart';
import '../widgets/sort/wallet_sort_row.dart';

/// Sắp xếp ví (D, màn 2): drag by the grip (or long-press the row), or use the
/// arrows. "Xong" saves the whole order at once.
class WalletSortPage extends StatefulWidget {
  const WalletSortPage({super.key});

  @override
  State<WalletSortPage> createState() => _WalletSortPageState();
}

class _WalletSortPageState extends State<WalletSortPage> {
  late final WalletViewModel model = getIt<WalletViewModel>();
  late List<Wallet> order = model.active;
  bool saving = false;

  void _move(int from, int to) => setState(() {
    final next = [...order];
    next.insert(to, next.removeAt(from));
    order = next;
  });

  Future<void> _done() async {
    setState(() => saving = true);
    final saved = await model.reorder(order);
    if (!mounted) return;
    setState(() => saving = false);
    if (saved) {
      context.popOrGo('/wallets');
      return;
    }
    showFreevaToast(
      context,
      message: S.of(context).walletSortFailed,
      aboveNav: false,
    );
    if (model.needsReload) {
      await model.load();
      if (mounted) setState(() => order = model.active);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final margin = context.screenMargin;
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.walletSortTitle,
        showLeading: false,
        action: TextButton(
          onPressed: saving ? null : _done,
          style: TextButton.styleFrom(
            foregroundColor: c.actionPrimary,
            minimumSize: const Size(FreevaSize.touch, FreevaSize.touch),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerRight,
            textStyle: FreevaTypography.titleM,
          ),
          child: Text(s.walletSortDone),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              margin + 4,
              FreevaSpace.s2,
              margin,
              FreevaSpace.s4,
            ),
            child: Text(
              s.walletSortHint,
              style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.fromLTRB(margin, 0, margin, FreevaSpace.s8),
              buildDefaultDragHandles: false,
              itemCount: order.length,
              onReorderItem: _move,
              proxyDecorator: (child, index, animation) => AnimatedBuilder(
                animation: animation,
                builder: (context, _) => Transform.rotate(
                  angle: -math.pi / 180 * animation.value,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: FreevaSpace.s2),
                      child: _row(index, lifted: true),
                    ),
                  ),
                ),
              ),
              itemBuilder: (context, index) => Padding(
                key: ValueKey(order[index].id),
                padding: const EdgeInsets.only(bottom: FreevaSpace.s2),
                child: ReorderableDelayedDragStartListener(
                  index: index,
                  child: _row(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(int index, {bool lifted = false}) => WalletSortRow(
    wallet: order[index],
    index: index,
    lifted: lifted,
    onUp: index == 0 || saving ? null : () => _move(index, index - 1),
    onDown: index == order.length - 1 || saving
        ? null
        : () => _move(index, index + 1),
  );
}
