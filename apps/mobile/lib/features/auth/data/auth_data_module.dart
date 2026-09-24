import 'package:injectable/injectable.dart';

import '../domain/auth_repository.dart';
import 'authorized_api.dart';

@module
abstract class AuthDataModule {
  @lazySingleton
  AuthorizedApi authorizedApi(AuthRepository repository) =>
      repository as AuthorizedApi;
}
