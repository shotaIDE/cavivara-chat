import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:house_worker/data/definition/app_definition.dart';
import 'package:house_worker/data/model/feedback_request.dart';
import 'package:house_worker/data/model/send_feedback_exception.dart';
import 'package:house_worker/data/service/dao/feedback_request_post.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_form_service.g.dart';

@riverpod
GoogleFormService googleFormService(Ref ref) {
  final dio = ref.watch<Dio>(_dioProvider);
  final errorReportService = ref.watch(errorReportServiceProvider);

  return GoogleFormService(dio: dio, errorReportService: errorReportService);
}

class GoogleFormService {
  GoogleFormService({
    required Dio dio,
    required ErrorReportService errorReportService,
  }) : _dio = dio,
       _errorReportService = errorReportService;

  final Dio _dio;
  final ErrorReportService _errorReportService;

  final _logger = Logger('GoogleFormService');

  /// フィードバック(ご意見・ご要望)をGoogle Formに送信する
  ///
  /// Throws:
  /// - [SendFeedbackException]: リクエストに失敗した場合
  Future<void> sendFeedback(FeedbackRequest request) async {
    final requestPost = FeedbackRequestPost.fromFeedbackRequest(request);
    final data = requestPost.toFormData();

    try {
      await _dio.post<void>(
        GoogleForm.postUrl,
        data: data,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
    } on DioException catch (e, stack) {
      _logger.severe('Failed to send feedback', e);

      if (e.type == DioExceptionType.unknown) {
        unawaited(_errorReportService.recordError(e, stack));

        throw const SendFeedbackException.uncategorized();
      }

      throw const SendFeedbackException.connection();
    } on SocketException {
      throw const SendFeedbackException.connection();
    }
  }
}

@riverpod
Dio _dio(Ref ref) {
  return Dio();
}
