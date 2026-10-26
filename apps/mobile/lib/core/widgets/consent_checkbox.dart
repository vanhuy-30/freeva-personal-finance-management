import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'check_mark.dart';

/// "Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật của Freeva."
/// Box 22 with radius 7 at x 4, 12 before the 14/20 text, top-aligned with
/// the first line; the two links (600, underlined) open the documents. The
/// whole row (at least 44 high) toggles, like an HTML label.
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
    final base = FreevaTypography.bodyM.copyWith(
      height: 20 / 14,
      color: c.textOnWash,
    );
    final link = base.copyWith(
      color: c.textPrimary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: c.textPrimary,
    );
    void toggle() => widget.onChanged(!widget.checked);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: toggle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: FreevaSize.touch),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                checked: widget.checked,
                label: s.consentLabel,
                onTap: toggle,
                child: AnimatedContainer(
                  duration: FreevaMotion.fast,
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    color: widget.checked
                        ? c.actionPrimary
                        : Colors.transparent,
                    border: widget.checked
                        ? null
                        : Border.all(color: c.borderStrong, width: 1.5),
                  ),
                  child: widget.checked
                      ? CheckMark(
                          size: 14,
                          strokeWidth: 3,
                          color: c.textOnAction,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
}
