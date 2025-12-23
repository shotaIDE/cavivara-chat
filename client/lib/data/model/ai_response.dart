import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_response.freezed.dart';
part 'ai_response.g.dart';

/// AIからの返答全体を表すモデル
@freezed
abstract class AiResponse with _$AiResponse {
  const factory AiResponse({
    /// AIの返答テキスト
    required String content,

    /// 返答サジェストのリスト（3〜5個）
    @Default([]) List<String> suggestedReplies,
  }) = _AiResponse;

  factory AiResponse.fromJson(Map<String, dynamic> json) =>
      _$AiResponseFromJson(json);
}
