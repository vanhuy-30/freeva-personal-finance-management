import 'package:flutter/material.dart';

import 'tokens.g.dart';

/// Material theme built only from generated tokens (`tokens.g.dart`).
abstract final class AppTheme {
  static ThemeData get light => _build(FreevaColors.light, Brightness.light);
  static ThemeData get dark => _build(FreevaColors.dark, Brightness.dark);

  static ThemeData _build(FreevaColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.actionPrimary,
      onPrimary: c.textOnAction,
      secondary: c.actionInk,
      onSecondary: c.textOnInk,
      tertiary: c.data2,
      onTertiary: c.textOnAction,
      error: c.statusDanger,
      onError: c.textOnAction,
      errorContainer: c.statusDangerBg,
      onErrorContainer: c.statusDanger,
      surface: c.bgSurface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.bgSurface,
      surfaceContainerLow: c.bgCanvas,
      surfaceContainer: c.bgSubtle,
      surfaceContainerHigh: c.bgSubtle,
      surfaceContainerHighest: c.bgTrack,
      primaryContainer: c.tintBlue,
      onPrimaryContainer: c.tintBlueFg,
      secondaryContainer: c.tintBlue,
      onSecondaryContainer: c.tintBlueFg,
      outline: c.borderDefault,
      outlineVariant: c.borderDivider,
      scrim: c.bgScrim,
      shadow: FreevaPrimitive.ink900,
    );
    final text = _textTheme(c);
    const pill = StadiumBorder();
    const buttonText = FreevaTypography.titleM;
    const minButton = Size(FreevaSize.touch, FreevaSize.button);
    final inputRadius = BorderRadius.circular(FreevaComponent.inputRadius);
    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: FreevaTypography.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.bgCanvas,
      canvasColor: c.bgCanvas,
      dividerColor: c.borderDivider,
      splashFactory: NoSplash.splashFactory,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgCanvas,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: FreevaTypography.titleL.copyWith(color: c.textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.buttonPrimaryBg,
          foregroundColor: c.buttonPrimaryFg,
          disabledBackgroundColor: c.buttonDisabledBg,
          disabledForegroundColor: c.buttonDisabledFg,
          minimumSize: minButton,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.buttonSecondaryBg,
          foregroundColor: c.buttonSecondaryFg,
          side: BorderSide(color: c.buttonSecondaryBorder),
          minimumSize: minButton,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textLink,
          minimumSize: const Size(FreevaSize.touch, FreevaSize.touch),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size(FreevaSize.iconButton, FreevaSize.iconButton),
          iconSize: FreevaSize.iconInline,
        ),
      ),
      iconTheme: IconThemeData(color: c.textPrimary, size: FreevaSize.icon),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputBg,
        labelStyle: FreevaTypography.body.copyWith(color: c.textSecondary),
        floatingLabelStyle: FreevaTypography.label.copyWith(
          color: c.textSecondary,
        ),
        hintStyle: FreevaTypography.body.copyWith(color: c.textSecondary),
        helperStyle: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
        errorStyle: FreevaTypography.bodyS.copyWith(color: c.statusDanger),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FreevaSpace.s4,
          vertical: FreevaSpace.s3,
        ),
        border: inputBorder(c.inputBorder, FreevaBorder.defaultValue),
        enabledBorder: inputBorder(c.inputBorder, FreevaBorder.defaultValue),
        disabledBorder: inputBorder(c.borderDivider, FreevaBorder.defaultValue),
        focusedBorder: inputBorder(c.inputBorderFocus, FreevaBorder.selected),
        errorBorder: inputBorder(c.inputBorderError, FreevaBorder.defaultValue),
        focusedErrorBorder: inputBorder(
          c.inputBorderError,
          FreevaBorder.selected,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FreevaComponent.cardRadius),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textPrimary,
        textColor: c.textPrimary,
        titleTextStyle: FreevaTypography.body.copyWith(color: c.textPrimary),
        subtitleTextStyle: FreevaTypography.bodyS.copyWith(
          color: c.textSecondary,
        ),
        minTileHeight: FreevaSize.row,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.sheetBg,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.sheetScrim,
        showDragHandle: true,
        dragHandleColor: c.borderDefault,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(FreevaComponent.sheetRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.bgSurface,
        surfaceTintColor: Colors.transparent,
        barrierColor: c.bgScrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FreevaRadius.xl),
        ),
        titleTextStyle: FreevaTypography.titleL.copyWith(color: c.textPrimary),
        contentTextStyle: FreevaTypography.body.copyWith(
          color: c.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.toastBg,
        contentTextStyle: FreevaTypography.body.copyWith(color: c.toastFg),
        actionTextColor: c.toastFg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FreevaRadius.md),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c.bgSurface),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.actionPrimary
              : c.bgDisabled,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.bgSurface,
        selectedColor: c.chipFilterSelectedBg,
        side: BorderSide(color: c.chipBorder),
        shape: const StadiumBorder(),
        labelStyle: FreevaTypography.bodyS.copyWith(color: c.textPrimary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.actionPrimary,
        linearTrackColor: c.bgTrack,
      ),
      dividerTheme: DividerThemeData(
        color: c.borderDivider,
        thickness: FreevaBorder.defaultValue,
        space: FreevaBorder.defaultValue,
      ),
    );
  }

  static TextTheme _textTheme(FreevaColors c) {
    TextStyle p(TextStyle s) => s.copyWith(color: c.textPrimary);
    TextStyle s2(TextStyle s) => s.copyWith(color: c.textSecondary);
    return TextTheme(
      displayLarge: p(FreevaTypography.moneyDisplay),
      displayMedium: p(FreevaTypography.moneyL),
      headlineLarge: p(FreevaTypography.titleXl),
      headlineMedium: p(FreevaTypography.headline),
      headlineSmall: p(FreevaTypography.headline),
      titleLarge: p(FreevaTypography.titleL),
      titleMedium: p(FreevaTypography.titleM),
      titleSmall: p(FreevaTypography.titleM),
      bodyLarge: p(FreevaTypography.body),
      bodyMedium: p(FreevaTypography.body),
      bodySmall: s2(FreevaTypography.bodyS),
      labelLarge: p(FreevaTypography.titleM),
      labelMedium: p(FreevaTypography.label),
      labelSmall: s2(FreevaTypography.overline),
    );
  }
}
