import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_config_service.g.dart';

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

/// Production-Release Suite でデバッグ機能を表示するか否か
///
/// デフォルト値は false。`getBool` は未設定時に false を返すため、
/// Remote Config に値が設定されていない場合はデバッグ機能を表示しない。
@riverpod
bool showDebugFeatureOnProdRelease(Ref ref) {
  return FirebaseRemoteConfig.instance.getBool('showDebugFeatureOnProdRelease');
}
