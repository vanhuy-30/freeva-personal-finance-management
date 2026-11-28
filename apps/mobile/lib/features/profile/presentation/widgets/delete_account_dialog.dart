import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../auth/domain/auth_repository.dart';
import 'account_step_up.dart';

/// How the delete popup ended.
enum DeleteAccountResult {
  /// The account is gone; the app has already left the signed-in screens.
  deleted,

  /// The person chose "Xuất dữ liệu trước": open the export screen.
  export,

  /// Closed without deleting.
  cancelled,
}

/// "Xóa tài khoản?" (G · 12): the warning, a way to export first, and the
/// password in one popup. [onDelete] runs the delete with the typed password
/// and returns why it failed, or null when it went through. A failure shows
/// under the field and the popup stays open with the data untouched.
Future<DeleteAccountResult> showDeleteAccountDialog(
  BuildContext context, {
  required Future<AuthFailure?> Function(String password) onDelete,
}) async {
  final result = await showDialog<DeleteAccountResult>(
    context: context,
    builder: (_) => _DeleteAccountDialog(onDelete: onDelete),
  );
  return result ?? DeleteAccountResult.cancelled;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.onDelete});

  final Future<AuthFailure?> Function(String password) onDelete;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_busy && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final s = S.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await widget.onDelete(_password.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(DeleteAccountResult.deleted);
      return;
    }
    setState(() {
      _busy = false;
      _error = accountStepUpError(s, failure, s.meDeleteError);
    });
  }

  /// Cancel and delete side by side; on a narrow screen or at large text they
  /// stack (delete first) so neither label is cut.
  Widget _buttons(BuildContext context, S s) {
    final cancel = FreevaButton(
      label: s.commonCancel,
      variant: FreevaButtonVariant.secondary,
      size: FreevaButtonSize.dialog,
      expand: true,
      onPressed: _busy
          ? null
          : () => Navigator.of(context).pop(DeleteAccountResult.cancelled),
    );
    final delete = FreevaButton(
      label: s.meDeleteConfirm,
      variant: FreevaButtonVariant.destructive,
      size: FreevaButtonSize.dialog,
      expand: true,
      loading: _busy,
      onPressed: _canSubmit ? _submit : null,
    );
    final stacked =
        context.isCompactScreen ||
        MediaQuery.textScalerOf(context).scale(1) > 1.15;
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          delete,
          const SizedBox(height: FreevaSpace.s2),
          cancel,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: cancel),
        const SizedBox(width: FreevaSpace.s2),
        Expanded(child: delete),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    // Nothing closes the popup while the delete is running: the answer decides.
    return PopScope(
      canPop: !_busy,
      child: FreevaDialog(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: FreevaDialogIcon(icon: LucideIcons.trash)),
              const SizedBox(height: 10),
              Semantics(
                header: true,
                child: Text(
                  s.meDeleteTitle,
                  textAlign: TextAlign.center,
                  style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.meDeleteBody,
                textAlign: TextAlign.center,
                style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
              ),
              Center(
                child: FreevaButton(
                  label: s.meDeleteExportFirst,
                  variant: FreevaButtonVariant.link,
                  icon: LucideIcons.download,
                  onPressed: _busy
                      ? null
                      : () =>
                            Navigator.of(context)
                                .pop(DeleteAccountResult.export),
                ),
              ),
              const SizedBox(height: FreevaSpace.s2),
              FreevaTextField(
                label: s.authPassword,
                controller: _password,
                obscureText: true,
                revealable: true,
                textInputAction: TextInputAction.done,
                error: _error,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: FreevaSpace.s4),
              _buttons(context, s),
            ],
          ),
        ),
      ),
    );
  }
}
