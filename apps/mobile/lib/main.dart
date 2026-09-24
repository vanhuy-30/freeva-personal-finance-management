import 'features/profile/presentation/viewmodels/profile_view_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection.dart';
import 'core/config/app_config.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  getIt<AppConfig>().validate();
  runApp(const FreevaApp());
}

class FreevaApp extends StatelessWidget {
  const FreevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = getIt<ProfileViewModel>();
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) => MaterialApp.router(
        onGenerateTitle: (BuildContext context) => S.of(context).appTitle,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        routerConfig: appRouter,
        locale: Locale(profile.locale),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
