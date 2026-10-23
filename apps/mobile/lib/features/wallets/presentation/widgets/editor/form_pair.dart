import 'package:flutter/material.dart';

import '../../../../../core/theme/tokens.g.dart';

/// Whether two form fields fit side by side: about 330 pt of content at the
/// current text size. Narrow phones and large text stack them instead.
bool fitsSideBySide(BuildContext context, double width) =>
    width / MediaQuery.textScalerOf(context).scale(1) >= 330;

/// Two fields on one row (debt + limit, statement + due day), stacked when
/// [fitsSideBySide] says they would be cut.
class FormPair extends StatelessWidget {
  const FormPair({required this.first, required this.second, super.key});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!fitsSideBySide(context, constraints.maxWidth)) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            first,
            const SizedBox(height: FreevaSpace.s4),
            second,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: FreevaSpace.s2),
          Expanded(child: second),
        ],
      );
    },
  );
}
