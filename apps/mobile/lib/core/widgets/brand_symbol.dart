import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Approved artwork, including its original transparent clear space.
class BrandSymbol extends StatelessWidget {
  const BrandSymbol({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/freeva-brand-symbol.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: S.of(context).appTitle,
    );
  }
}
