import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';

const int feedbackMaxLength = 2000;

enum FeedbackKind { bug, idea, praise }

enum FeedbackTopic { record, reports, wallets, categories, appearance, other }

class FeedbackDraft {
  const FeedbackDraft({
    required this.kind,
    required this.topic,
    required this.message,
    required this.allowReply,
  });

  final FeedbackKind kind;
  final FeedbackTopic topic;
  final String message;

  /// The user agreed to be answered by email.
  final bool allowReply;
}

abstract class FeedbackRepository {
  Future<Either<AuthFailure, Unit>> send(FeedbackDraft draft, String version);
}

abstract class FeedbackUseCases {
  Future<Either<AuthFailure, Unit>> send(FeedbackDraft draft, String version);
}

@LazySingleton(as: FeedbackUseCases)
class DefaultFeedbackUseCases implements FeedbackUseCases {
  DefaultFeedbackUseCases(this._repository);

  final FeedbackRepository _repository;

  @override
  Future<Either<AuthFailure, Unit>> send(FeedbackDraft draft, String version) {
    final text = draft.message.trim();
    if (text.isEmpty || text.length > feedbackMaxLength) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.send(
      FeedbackDraft(
        kind: draft.kind,
        topic: draft.topic,
        message: text,
        allowReply: draft.allowReply,
      ),
      version,
    );
  }
}
