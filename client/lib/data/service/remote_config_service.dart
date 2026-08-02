import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:house_worker/data/model/remote_config_snapshot.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_service.g.dart';

final _logger = Logger('RemoteConfigService');

@riverpod
class UpdatedRemoteConfigKeys extends _$UpdatedRemoteConfigKeys {
  @override
  Stream<Set<String>> build() {
    return FirebaseRemoteConfig.instance.onConfigUpdated.map(
      (event) => event.updatedKeys,
    );
  }

  Future<void> ensureActivateFetchedRemoteConfigs() async {
    await FirebaseRemoteConfig.instance.activate();
  }
}

@riverpod
int? minimumBuildNumber(Ref ref) {
  final minimumBuildNumber = FirebaseRemoteConfig.instance.getInt(
    RemoteConfigParameterKey.minimumBuildNumber.name,
  );
  if (minimumBuildNumber == 0) {
    return null;
  }

  return minimumBuildNumber;
}

/// Function Calling の設定 JSON
///
/// `getString` は未設定時に空文字を返すため、空文字の場合はアプリに埋め込んだ
/// 組み込みデフォルト設定を使用する。
///
/// Firebase が初期化されていない場合（初期化に失敗した場合や、単体テストの実行時）は
/// `FirebaseRemoteConfig.instance` が例外を投げる。この設定はチャットの応答経路から
/// 参照されるため、例外を送出するとチャット自体が利用できなくなる。Firebase の
/// 初期化に失敗してもアプリを続行する方針に合わせ、空文字を返して組み込みデフォルト
/// 設定にフォールバックする。
@riverpod
String functionCallingConfigJson(Ref ref) {
  try {
    return FirebaseRemoteConfig.instance.getString(
      RemoteConfigParameterKey.functionCallingConfig.name,
    );
  } on Exception catch (e) {
    _logger.warning('Remote Config から Function Calling の設定を取得できませんでした', e);

    return '';
  }
}

/// 会話開始時に表示するサジェストの設定 JSON
///
/// `getString` は未設定時に空文字を返すため、空文字の場合はアプリに埋め込んだ
/// 組み込みデフォルト設定を使用する。
///
/// Firebase が初期化されていない場合（初期化に失敗した場合や、ウィジェットテストの
/// 実行時）は `FirebaseRemoteConfig.instance` が例外を投げる。サジェストが表示できない
/// だけでチャット画面自体が開けなくなることを避けるため、例外を捕捉して空文字を返し、
/// 組み込みデフォルト設定にフォールバックする。
@riverpod
String initialChatSuggestionsConfigJson(Ref ref) {
  try {
    return FirebaseRemoteConfig.instance.getString(
      RemoteConfigParameterKey.initialChatSuggestionsConfig.name,
    );
  } on Exception catch (e) {
    _logger.warning('Remote Config から会話開始時のサジェストの設定を取得できませんでした', e);

    return '';
  }
}

/// Production-Release Suite でデバッグ機能を表示するか否か
///
/// デフォルト値は false。`getBool` は未設定時に false を返すため、
/// Remote Config に値が設定されていない場合はデバッグ機能を表示しない。
@riverpod
bool showDebugFeatureOnProdRelease(Ref ref) {
  return FirebaseRemoteConfig.instance.getBool(
    RemoteConfigParameterKey.showDebugFeatureOnProdRelease.name,
  );
}

/// Remote Config の現在の状態
///
/// デバッグ画面で、アプリが実際に参照している値とその取得元を確認するために使う。
/// 値は起動時に有効化されたものであるため、公開直後の値を確認する場合はアプリの
/// 再起動が必要になる。
///
/// Firebase が初期化されていない場合は `null` を返す。デバッグ画面の他の項目まで
/// 巻き添えで表示できなくなることを避けるため、例外は送出しない。
@riverpod
RemoteConfigSnapshot? remoteConfigSnapshot(Ref ref) {
  final FirebaseRemoteConfig remoteConfig;
  try {
    remoteConfig = FirebaseRemoteConfig.instance;
  } on Exception catch (e) {
    _logger.warning('Remote Config の状態を取得できませんでした', e);

    return null;
  }

  final lastFetchState = _toFetchState(remoteConfig.lastFetchStatus);

  return RemoteConfigSnapshot(
    lastFetchState: lastFetchState,
    // 一度もフェッチしていない場合、ライブラリは日時としてエポックを返すため、
    // 日時として扱わずに「なし」を表せるよう null に読み替える
    lastFetchTime: lastFetchState == RemoteConfigFetchState.notFetchedYet
        ? null
        : remoteConfig.lastFetchTime,
    parameters: RemoteConfigParameterKey.values
        .map(
          (key) => RemoteConfigParameter(
            key: key,
            value: remoteConfig.getValue(key.name).asString(),
          ),
        )
        .toList(),
  );
}

RemoteConfigFetchState _toFetchState(RemoteConfigFetchStatus status) {
  return switch (status) {
    RemoteConfigFetchStatus.noFetchYet => RemoteConfigFetchState.notFetchedYet,
    RemoteConfigFetchStatus.success => RemoteConfigFetchState.success,
    RemoteConfigFetchStatus.failure => RemoteConfigFetchState.failure,
    RemoteConfigFetchStatus.throttle => RemoteConfigFetchState.throttled,
  };
}
