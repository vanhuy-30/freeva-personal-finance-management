import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'card_installment.dart';
import 'card_installment_repository.dart';
import '../../server_config/domain/app_limits.dart';

abstract class CardInstallmentUseCases {
  Future<Either<AuthFailure, List<CardInstallment>>> list({
    String? accountId,
    bool? active,
  });
  Future<Either<AuthFailure, CardInstallment>> find(String id);
  Future<Either<AuthFailure, InstallmentPreview>> preview(
    InstallmentDraft draft,
  );
  Future<Either<AuthFailure, CardInstallment>> create(
    InstallmentDraft draft, {
    required String clientId,
  });
  Future<Either<AuthFailure, CardInstallment>> close(CardInstallment plan);
  Future<Either<AuthFailure, List<InstallmentDue>>> due({
    required String from,
    required String to,
    String? accountId,
  });
}

@LazySingleton(as: CardInstallmentUseCases)
class DefaultCardInstallmentUseCases implements CardInstallmentUseCases {
  DefaultCardInstallmentUseCases(this._repository, this._limits);
  final CardInstallmentRepository _repository;
  final AppLimitsSource _limits;

  static final _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static const _invalid = AuthFailure(AuthError.invalidInput);

  /// Same bounds as the API (server `limit.installmentMinTerm` / `MaxTerm`);
  /// the API still checks that the periods add up.
  bool valid(InstallmentDraft draft) =>
      draft.installmentCount >= _limits.requireLimits.installmentMinTerm &&
      draft.installmentCount <= _limits.requireLimits.installmentMaxTerm &&
      (draft.installmentMinor == null ||
          draft.installmentMinor! > BigInt.zero) &&
      _day.hasMatch(draft.firstDueOn);

  @override
  Future<Either<AuthFailure, List<CardInstallment>>> list({
    String? accountId,
    bool? active,
  }) => _repository.list(accountId: accountId, active: active);

  @override
  Future<Either<AuthFailure, CardInstallment>> find(String id) =>
      _repository.find(id);

  @override
  Future<Either<AuthFailure, InstallmentPreview>> preview(
    InstallmentDraft draft,
  ) async => valid(draft) ? _repository.preview(draft) : left(_invalid);

  @override
  Future<Either<AuthFailure, CardInstallment>> create(
    InstallmentDraft draft, {
    required String clientId,
  }) async => valid(draft)
      ? _repository.create(draft, clientId: clientId)
      : left(_invalid);

  @override
  Future<Either<AuthFailure, CardInstallment>> close(CardInstallment plan) =>
      _repository.close(plan);

  @override
  Future<Either<AuthFailure, List<InstallmentDue>>> due({
    required String from,
    required String to,
    String? accountId,
  }) async =>
      _day.hasMatch(from) && _day.hasMatch(to) && from.compareTo(to) <= 0
      ? _repository.due(from: from, to: to, accountId: accountId)
      : left(_invalid);
}
