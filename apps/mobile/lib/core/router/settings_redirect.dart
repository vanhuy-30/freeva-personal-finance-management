import '../../features/auth/domain/auth_repository.dart';

String? settingsRedirect({
  required AuthStage stage,
  required bool onboardingCompleted,
  required String path,
}) {
  if (path == '/splash') return null;
  final pending = stage == AuthStage.unlocked && !onboardingCompleted;
  if (pending && path != '/onboarding') return '/onboarding';
  if (path == '/onboarding' && !pending) return '/home';
  return null;
}
