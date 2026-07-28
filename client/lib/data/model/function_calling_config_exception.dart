import 'package:freezed_annotation/freezed_annotation.dart';

part 'function_calling_config_exception.freezed.dart';

/// Function Calling の設定を解釈できなかったことを表す例外
///
/// [FunctionCallingConfigExceptionUnsupportedSchemaVersion] は、アプリと
/// Remote Config の世代差でも発生し得るため、想定外のエラーとしては扱わない。
@freezed
sealed class FunctionCallingConfigException
    with _$FunctionCallingConfigException
    implements Exception {
  /// 設定の構造がアプリの解釈できる形式ではない
  const factory FunctionCallingConfigException.malformed({
    required String message,
  }) = FunctionCallingConfigExceptionMalformed;

  /// 設定の構造バージョンがアプリの対応上限を超えている
  const factory FunctionCallingConfigException.unsupportedSchemaVersion({
    required int schemaVersion,
  }) = FunctionCallingConfigExceptionUnsupportedSchemaVersion;
}
