import 'features/profile/presentation/viewmodels/profile_view_model.dart';
import 'features/settings/presentation/theme_mode.dart';
import 'features/settings/presentation/viewmodels/settings_view_model.dart';
import 'features/sync/presentation/viewmodels/sync_view_model.dart';
import 'features/sync/presentation/widgets/sync_resume_listener.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'core/di/injection.dart';
import 'core/config/app_config.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/sentry/sentry_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.g.dart';

Future<void> main() async {
  await runFreeva(_boot);
}

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await configureDependencies();
  final config = getIt<AppConfig>();
  final logger = getIt<AppLogger>();
  config.validate();
  logger.op('boot env=${config.environment.name} api=${config.apiBaseUrl}');
  await getIt<SettingsViewModel>().load();
  getIt<SyncViewModel>();
  createAppRouter();
  logger.op('boot ready');
  runApp(const FreevaApp());
}

class FreevaApp extends StatelessWidget {
  const FreevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = getIt<ProfileViewModel>();
    final settings = getIt<SettingsViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([profile, settings]),
      builder: (context, _) => SyncResumeListener(
        child: MaterialApp.router(
          onGenerateTitle: (BuildContext context) => S.of(context).appTitle,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeModeFor(settings.theme),
          routerConfig: appRouter,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: FreevaTypography.maxTextScale,
            child: child!,
          ),
          locale: Locale(profile.locale),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}
