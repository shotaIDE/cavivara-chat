import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_feedback_exception.freezed.dart';

@freezed
sealed class SendFeedbackException
    with _$SendFeedbackException
    implements Exception {
  const factory SendFeedbackException.connection() =
      SendFeedbackExceptionConnection;

  const factory SendFeedbackException.uncategorized() =
      SendFeedbackExceptionUncategorized;
}
