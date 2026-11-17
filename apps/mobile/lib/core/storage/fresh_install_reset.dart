import 'dart:io';

/// File kept in the app's own support directory. The OS removes that
/// directory on uninstall; iOS does not remove Keychain items.
const freshInstallMarker = '.freeva-installed';

/// MOB-P6-001: a reinstalled app starts signed out, like a new install.
///
/// Every Freeva vault (session, PIN, settings, sync queue, cached config) is in
/// the Keychain / Keystore, and iOS keeps Keychain items after the app is
/// deleted. When the marker in [supportDir] is missing, this is the first
/// launch of this install: [clearVaults] runs, then the marker is written, so
/// a failed clear is tried again on the next launch. Returns whether the
/// vaults were cleared.
Future<bool> clearVaultsOnFreshInstall({
  required Future<Directory> Function() supportDir,
  required Future<void> Function() clearVaults,
}) async {
  final marker = File('${(await supportDir()).path}/$freshInstallMarker');
  if (await marker.exists()) return false;
  await clearVaults();
  await marker.create(recursive: true);
  return true;
}
