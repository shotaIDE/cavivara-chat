import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_config_snapshot.freezed.dart';

/// Remote Config のパラメーターキー
///
/// enum の名前がそのままパラメーターキーになる。値を取得するアクセサーと
/// デバッグ画面の一覧表示の両方がここを参照することで、パラメーターを追加した際に
/// デバッグ画面への反映漏れが起きないようにする。
enum RemoteConfigParameterKey {
  minimumBuildNumber,
  showDebugFeatureOnProdRelease,
  functionCallingConfig,
  initialChatSuggestionsConfig,
}

/// Remote Config の現在の状態
///
/// デバッグ画面で、アプリが実際に参照している値を確認するために使う。
@freezed
abstract class RemoteConfigSnapshot with _$RemoteConfigSnapshot {
  const factory RemoteConfigSnapshot({
    /// 最後にフェッチを試みた結果
    required RemoteConfigFetchState lastFetchState,

    /// 最後にフェッチを試みた日時
    ///
    /// 一度もフェッチしていない場合は `null`。
    required DateTime? lastFetchTime,

    /// 各パラメーターの現在値
    @Default([]) List<RemoteConfigParameter> parameters,
  }) = _RemoteConfigSnapshot;
}

/// Remote Config のパラメーター 1 件の現在値
@freezed
abstract class RemoteConfigParameter with _$RemoteConfigParameter {
  const factory RemoteConfigParameter({
    /// パラメーターキー
    required RemoteConfigParameterKey key,

    /// 現在値の文字列表現
    ///
    /// 型を問わず文字列として取得したもの。未設定の場合は空文字。
    required String value,

    /// 現在値がどこから来たか
    required RemoteConfigValueSource source,
  }) = _RemoteConfigParameter;
}

/// パラメーターの現在値の取得元
enum RemoteConfigValueSource {
  /// Remote Config から取得され、有効化された値
  remote,

  /// アプリが `setDefaults` で設定した既定値
  appDefault,

  /// 値がどこにも設定されておらず、型ごとの静的な既定値（空文字・0・false）が
  /// 返っている状態
  notSet,
}

/// 最後にフェッチを試みた結果
enum RemoteConfigFetchState {
  notFetchedYet,
  success,
  failure,
  throttled,
}
