import 'package:house_worker/data/model/feedback_request.dart';
import 'package:house_worker/data/model/send_feedback_exception.dart';
import 'package:house_worker/data/service/google_form_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'submit_feedback_presenter.g.dart';

@riverpod
class IsSubmissionAvailable extends _$IsSubmissionAvailable {
  @override
  bool build() => true;

  /// フィードバック(ご意見・ご要望)を送信する
  ///
  /// Throws:
  /// - [SendFeedbackException]: フィードバック送信に失敗した場合
  Future<void> submitFeedback(FeedbackRequest request) async {
    state = false;

    final googleFormService = ref.read(googleFormServiceProvider);

    try {
      await googleFormService.sendFeedback(request);
    } finally {
      state = true;
    }
  }
}
