import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// On/off switch: 48×28 track (padding 3), 22 white knob. Off is the grey
/// track, on is the primary blue. The touch area stays 44 high.
class FreevaSwitch extends StatelessWidget {
  const FreevaSwitch({
    required this.value,
    required this.onChanged,
    this.label,
    super.key,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Screen-reader label when no row around the switch already says it.
  final String? label;

  static const _width = 48.0;
  static const _height = 28.0;
  static const _pad = 3.0;
  static const _knob = 22.0;
  static const _knobShadow = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x4022283A)),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onChanged != null;
    final track = !enabled
        ? c.bgDisabled
        : value
        ? c.actionPrimary
        : c.bgSwitchOff;
    final duration = context.reduceMotion ? Duration.zero : FreevaMotion.fast;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox(
          width: _width,
          height: FreevaSize.touch,
          child: Center(
            child: AnimatedContainer(
              duration: duration,
              curve: FreevaMotion.standard,
              width: _width,
              height: _height,
              padding: const EdgeInsets.all(_pad),
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: track,
              ),
              child: AnimatedAlign(
                duration: duration,
                curve: FreevaMotion.standard,
                alignment: value
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                  width: _knob,
                  height: _knob,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.bgSurface,
                    boxShadow: _knobShadow,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
