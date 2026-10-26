import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/feedback.dart';

@LazySingleton(as: FeedbackRepository)
class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl(this._api);

  final AuthorizedApi _api;

  @override
  Future<Either<AuthFailure, Unit>> send(
    FeedbackDraft draft,
    String version,
  ) async {
    final result = await _api.request(
      'POST',
      'feedback',
      body: {
        'kind': draft.kind.name,
        'topic': draft.topic.name,
        'message': draft.message,
        'allowReply': draft.allowReply,
        'appVersion': version,
      },
    );
    return result.map((_) => unit);
  }
}
