import 'package:flutter/widgets.dart';

/// Investment screens always show their numbers: the "ẩn số dư" setting only
/// covers the overview, so this builder never reports hidden.
class ShownBalances extends StatelessWidget {
  const ShownBalances({required this.builder, super.key});

  final Widget Function(BuildContext context, bool hidden) builder;

  @override
  Widget build(BuildContext context) => builder(context, false);
}
