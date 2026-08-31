import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Freeva';

  @override
  String get splashTagline => 'Personal finance';

  @override
  String get homePlaceholder => 'Core loop: wallet → transaction → balance. Features land in lib/features.';
}
