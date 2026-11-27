import 'features/auth/domain/deep_link_service.dart';
import 'features/auth/presentation/widgets/auth_link_host.dart';
import 'features/profile/presentation/viewmodels/profile_view_model.dart';
import 'features/settings/presentation/theme_mode.dart';
import 'features/settings/presentation/viewmodels/settings_view_model.dart';
import 'features/notifications/presentation/viewmodels/notification_view_model.dart';
import 'features/notifications/presentation/widgets/notification_resume_listener.dart';
import 'features/notifications/presentation/widgets/push_registration_listener.dart';
import 'features/recurring/presentation/viewmodels/recurring_view_model.dart';
import 'features/recurring/presentation/widgets/recurring_resume_listener.dart';
import 'features/sync/presentation/viewmodels/sync_view_model.dart';
import 'features/sync/presentation/widgets/sync_resume_listener.dart';
import 'features/server_config/presentation/viewmodels/server_config_view_model.dart';
import 'features/server_config/presentation/widgets/server_config_boundary.dart';
import 'features/server_config/presentation/widgets/server_config_listener.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'core/di/injection.dart';
import 'core/config/app_config.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/sentry/sentry_bootstrap.dart';
import 'core/storage/fresh_install_reset.dart';
import 'core/storage/secure_storage_factory.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.g.dart';
import 'core/app_version/app_version.dart';
import 'features/investments/presentation/widgets/matured_deposit_listener.dart';

Future<void> main() async {
  await runFreeva(_boot);
}

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  // Before any vault is read: a reinstalled app must not reuse the old
  // session kept in the iOS Keychain (MOB-P6-001).
  Object? resetError;
  StackTrace? resetStack;
  var reset = false;
  try {
    reset = await clearVaultsOnFreshInstall(
      supportDir: getApplicationSupportDirectory,
      clearVaults: () => createFreevaSecureStorage().deleteAll(),
    );
  } catch (error, stackTrace) {
    // Keep booting; the marker was not written, so the next launch retries.
    resetError = error;
    resetStack = stackTrace;
  }
  await configureDependencies();
  final config = getIt<AppConfig>();
  final logger = getIt<AppLogger>();
  if (resetError != null) {
    logger.error('fresh install reset failed', resetError, resetStack);
  } else if (reset) {
    logger.op('fresh install: vaults cleared');
  }
  config.validate();
  logger.op('boot env=${config.environment.name} api=${config.apiBaseUrl}');
  await getIt<SettingsViewModel>().load();
  await getIt<ServerConfigViewModel>().loadCached();
  await getIt<AppVersion>().load();
  getIt<SyncViewModel>();
  getIt<RecurringViewModel>();
  getIt<NotificationViewModel>();
  // Email links wait in the service until auth is ready; start() never throws.
  unawaited(getIt<DeepLinkService>().start());
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
        child: RecurringResumeListener(
          child: NotificationResumeListener(
            child: PushRegistrationListener(
              child: MaturedDepositListener(
                child: ServerConfigListener(
                  child: AuthLinkHost(
                    navigatorKey: appRouter.routerDelegate.navigatorKey,
                    child: MaterialApp.router(
                      debugShowCheckedModeBanner: false,
                      onGenerateTitle: (BuildContext context) =>
                          S.of(context).appTitle,
                      theme: AppTheme.light,
                      darkTheme: AppTheme.dark,
                      themeMode: themeModeFor(settings.theme),
                      routerConfig: appRouter,
                      builder: (context, child) =>
                          MediaQuery.withClampedTextScaling(
                            maxScaleFactor: FreevaTypography.maxTextScale,
                            child: ServerConfigBoundary(child: child!),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
