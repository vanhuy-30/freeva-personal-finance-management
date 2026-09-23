import 'package:flutter/material.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton(
      {required this.label,
      required this.loading,
      required this.onPressed,
      super.key});
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (loading) ...[
            SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 12),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ]),
      );
}
