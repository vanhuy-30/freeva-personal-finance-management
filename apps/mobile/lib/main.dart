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
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  await configureDependencies();
  getIt<AppConfig>().validate();
  await getIt<SettingsViewModel>().load();
  getIt<SyncViewModel>();
  createAppRouter();
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
