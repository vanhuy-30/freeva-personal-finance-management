import 'package:app_links/app_links.dart';
import 'package:injectable/injectable.dart';

import '../domain/deep_link_service.dart';

/// [LinkSource] backed by the `app_links` plugin.
@LazySingleton(as: LinkSource)
class AppLinksSource implements LinkSource {
  AppLinksSource() : _links = AppLinks();

  final AppLinks _links;

  @override
  Future<Uri?> initialLink() => _links.getInitialLink();

  @override
  Stream<Uri> get links => _links.uriLinkStream;
}
