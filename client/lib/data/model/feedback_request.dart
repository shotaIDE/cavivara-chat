import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_request.freezed.dart';

@freezed
abstract class FeedbackRequest with _$FeedbackRequest {
  factory FeedbackRequest({
    required String body,
    String? email,
    String? userId,
  }) = _FeedbackRequest;
}
