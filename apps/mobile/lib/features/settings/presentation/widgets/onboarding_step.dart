import 'package:flutter/material.dart';

class OnboardingStep extends StatelessWidget {
  const OnboardingStep({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text(body),
      ],
    );
  }
}
