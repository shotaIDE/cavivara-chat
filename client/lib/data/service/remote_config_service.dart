import 'package:firebase_remote_config/firebase_remote_config.dart';
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
    'minimumBuildNumber',
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
    return FirebaseRemoteConfig.instance.getString('functionCallingConfig');
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
      'initialChatSuggestionsConfig',
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
  return FirebaseRemoteConfig.instance.getBool('showDebugFeatureOnProdRelease');
}
