import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/data/definition/app_definition.dart';
import 'package:house_worker/data/model/feedback_request.dart';

part 'feedback_request_post.freezed.dart';

@freezed
abstract class FeedbackRequestPost with _$FeedbackRequestPost {
  factory FeedbackRequestPost({
    required String body,
    String? email,
    String? userId,
  }) = _FeedbackRequestPost;

  const FeedbackRequestPost._();

  factory FeedbackRequestPost.fromFeedbackRequest(FeedbackRequest request) {
    return FeedbackRequestPost(
      body: request.body,
      email: request.email,
      userId: request.userId,
    );
  }

  /// Google Formに送信するためのフォームデータに変換する
  Map<String, String> toFormData() {
    return {
      GoogleForm.bodyKey: body,
      if (email != null && email!.isNotEmpty) GoogleForm.emailKey: email!,
      if (userId != null && userId!.isNotEmpty) GoogleForm.userIdKey: userId!,
    };
  }
}
