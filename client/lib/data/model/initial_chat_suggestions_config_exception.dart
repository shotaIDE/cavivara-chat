import 'package:freezed_annotation/freezed_annotation.dart';

part 'initial_chat_suggestions_config_exception.freezed.dart';

/// 会話開始時のサジェストの設定を解釈できなかったことを表す例外
///
/// [InitialChatSuggestionsConfigExceptionUnsupportedSchemaVersion] は、アプリと
/// Remote Config の世代差でも発生し得るため、想定外のエラーとしては扱わない。
@freezed
sealed class InitialChatSuggestionsConfigException
    with _$InitialChatSuggestionsConfigException
    implements Exception {
  /// 設定の構造がアプリの解釈できる形式ではない
  const factory InitialChatSuggestionsConfigException.malformed({
    required String message,
  }) = InitialChatSuggestionsConfigExceptionMalformed;

  /// 設定の構造バージョンがアプリの対応上限を超えている
  const factory InitialChatSuggestionsConfigException.unsupportedSchemaVersion({
    required int schemaVersion,
  }) = InitialChatSuggestionsConfigExceptionUnsupportedSchemaVersion;
}
