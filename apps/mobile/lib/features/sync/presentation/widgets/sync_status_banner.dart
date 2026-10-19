import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../viewmodels/sync_view_model.dart';
import 'sync_status_body.dart';

class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  late final SyncViewModel model;

  @override
  void initState() {
    super.initState();
    model = getIt<SyncViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final visible =
            model.items.isNotEmpty ||
            model.schemaMismatch ||
            model.duplicateHint ||
            model.syncing;
        if (!visible) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SyncStatusBody(model: model),
        );
      },
    );
  }
}
