import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// "Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật của Freeva."
/// Box 22 with radius 7; the two links are underlined and open the documents.
class ConsentCheckbox extends StatefulWidget {
  const ConsentCheckbox({
    required this.checked,
    required this.onChanged,
    required this.onTerms,
    required this.onPrivacy,
    super.key,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  State<ConsentCheckbox> createState() => _ConsentCheckboxState();
}

class _ConsentCheckboxState extends State<ConsentCheckbox> {
  late final _terms = TapGestureRecognizer()..onTap = () => widget.onTerms();
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => widget.onPrivacy();

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    final base = FreevaTypography.bodyS.copyWith(
      fontSize: 13,
      height: 18 / 13,
      color: c.textSecondary,
    );
    final link = base.copyWith(
      color: c.textPrimary,
      decoration: TextDecoration.underline,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          checked: widget.checked,
          label: s.consentLabel,
          child: InkWell(
            onTap: () => widget.onChanged(!widget.checked),
            borderRadius: BorderRadius.circular(FreevaRadius.sm),
            child: SizedBox.square(
              dimension: FreevaSize.touch,
              child: Center(
                child: AnimatedContainer(
                  duration: FreevaMotion.fast,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: widget.checked
                        ? c.actionPrimary
                        : Colors.transparent,
                    border: widget.checked
                        ? null
                        : Border.all(color: c.borderDefault, width: 1.5),
                  ),
                  child: widget.checked
                      ? Icon(LucideIcons.check, size: 15, color: c.textOnAction)
                      : null,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Text.rich(
              TextSpan(
                style: base,
                children: [
                  TextSpan(text: s.consentPrefix),
                  TextSpan(
                    text: s.consentTerms,
                    style: link,
                    recognizer: _terms,
                  ),
                  TextSpan(text: s.consentAnd),
                  TextSpan(
                    text: s.consentPrivacy,
                    style: link,
                    recognizer: _privacy,
                  ),
                  TextSpan(text: s.consentSuffix),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
