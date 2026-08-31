import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class SVi extends S {
  SVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Freeva';

  @override
  String get splashTagline => 'Quản lý tài chính cá nhân';

  @override
  String get homePlaceholder => 'Vòng lặp cốt lõi: ví → giao dịch → số dư. Feature nghiệp vụ nằm ở lib/features.';
}
