import 'package:flutter/material.dart';

/// Boundaries follow the transparent gaps of the approved 1254px PNG.
/// These complementary masks reveal the source pixels without redrawing the F.
class SymbolPieceClipper extends CustomClipper<Path> {
  const SymbolPieceClipper(this.piece);

  final int piece;

  static const _upperGap = [
    Offset(0, .68),
    Offset(.25, .60),
    Offset(.32, .50),
    Offset(.42, .435),
    Offset(.56, .415),
    Offset(.72, .41),
    Offset(1, .38),
  ];
  static const _lowerGap = [
    Offset(0, .92),
    Offset(.25, .80),
    Offset(.35, .68),
    Offset(.50, .608),
    Offset(.72, .60),
    Offset(1, .60),
  ];

  @override
  Path getClip(Size size) {
    final top = piece == 2
        ? const [Offset.zero, Offset(1, 0)]
        : piece == 1
            ? _upperGap
            : _lowerGap;
    final bottom = piece == 0
        ? const [Offset(0, 1), Offset(1, 1)]
        : piece == 1
            ? _lowerGap
            : _upperGap;
    return Path()
      ..addPolygon([
        for (final p in top) Offset(p.dx * size.width, p.dy * size.height),
        for (final p in bottom.reversed)
          Offset(p.dx * size.width, p.dy * size.height),
      ], true);
  }

  @override
  bool shouldReclip(SymbolPieceClipper oldClipper) => piece != oldClipper.piece;
}
