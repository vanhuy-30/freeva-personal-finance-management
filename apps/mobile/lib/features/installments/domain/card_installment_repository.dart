import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'card_installment.dart';

abstract class CardInstallmentRepository {
  /// Plans of one card (or all), oldest first, without schedules.
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

  /// Installments due in [from]–[to] (inclusive, `yyyy-MM-dd`) per card.
  Future<Either<AuthFailure, List<InstallmentDue>>> due({
    required String from,
    required String to,
    String? accountId,
  });
}
