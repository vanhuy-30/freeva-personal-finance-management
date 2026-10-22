import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_button.dart';
import 'freeva_text_field.dart';

/// Small dialog with one labelled field; returns the text or null.
Future<String?> showFreevaInputDialog({
  required BuildContext context,
  required String title,
  required String label,
  String initial = '',
  TextInputType? keyboardType,
  List<TextInputFormatter>? formatters,
}) => showDialog<String>(
  context: context,
  builder: (_) => _InputDialog(
    title: title,
    label: label,
    initial: initial,
    keyboardType: keyboardType,
    formatters: formatters,
  ),
);

class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.title,
    required this.label,
    required this.initial,
    this.keyboardType,
    this.formatters,
  });

  final String title;
  final String label;
  final String initial;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: context.screenMargin),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: FreevaTypography.titleL.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: FreevaSpace.s3),
            FreevaTextField(
              label: widget.label,
              controller: controller,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.formatters,
              tabular: true,
            ),
            const SizedBox(height: FreevaSpace.s4),
            Row(
              children: [
                Expanded(
                  child: FreevaButton(
                    label: s.commonCancel,
                    variant: FreevaButtonVariant.secondary,
                    size: FreevaButtonSize.s,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: FreevaSpace.s2),
                Expanded(
                  child: FreevaButton(
                    label: s.txFilterDone,
                    size: FreevaButtonSize.s,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(controller.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
