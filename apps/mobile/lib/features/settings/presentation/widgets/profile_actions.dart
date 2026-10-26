import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../profile/domain/profile.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';

/// Changes one profile setting and saves it at once (no Lưu button). A failed
/// save puts the old value back and says so.
Future<bool> applyProfile(
  BuildContext context,
  ProfileViewModel model,
  Profile Function(Profile current) change,
) async {
  final current = model.saved;
  if (current == null || model.loading) return false;
  final s = S.of(context);
  model.edit(change(current));
  await model.save();
  final failure = model.failure;
  if (failure == null) return true;
  model.cancel();
  if (context.mounted) {
    showFreevaToast(
      context,
      message: failure.code == AuthError.conflict
          ? s.meConflict
          : s.meSaveError,
    );
  }
  return false;
}
