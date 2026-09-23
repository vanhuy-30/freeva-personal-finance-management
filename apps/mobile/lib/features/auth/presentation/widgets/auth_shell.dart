import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class AuthShell extends StatelessWidget {
  const AuthShell(
      {required this.child, required this.canGoBack, this.onBack, super.key});
  final Widget child;
  final bool canGoBack;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final text = dark ? AppColors.darkText : AppColors.text;
    final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
            color: AppColors.muted
                .withAlpha(((dark ? 0.35 : 0.55) * 255).round())));
    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack?.call();
      },
      child: Theme(
          data: theme.copyWith(
            textTheme:
                theme.textTheme.apply(bodyColor: text, displayColor: text),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: border,
              enabledBorder: border,
              disabledBorder: border,
              focusedBorder: border.copyWith(
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 1.5)),
              hintStyle: TextStyle(
                  color: dark ? AppColors.darkText : AppColors.textMuted),
              helperMaxLines: 3,
              errorMaxLines: 3,
            ),
          ),
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: SafeArea(
              child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        child: Center(
                            child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 420),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Align(
                                          alignment: Alignment.centerLeft,
                                          child: SizedBox(
                                              height: 48,
                                              child: canGoBack
                                                  ? IconButton(
                                                      onPressed: onBack,
                                                      tooltip: S
                                                          .of(context)
                                                          .authBack,
                                                      icon: const Icon(
                                                          Icons
                                                              .arrow_back_ios_new_rounded,
                                                          size: 20))
                                                  : null)),
                                      SizedBox(
                                          height: constraints.maxHeight > 700
                                              ? 48
                                              : 16),
                                      child,
                                      const SizedBox(height: 32),
                                    ]))),
                      )),
            ),
          )),
    );
  }
}
