import 'package:house_worker/data/model/app_session.dart';
import 'package:house_worker/data/repository/last_talked_cavivara_id_repository.dart';
import 'package:house_worker/data/service/app_info_service.dart';
import 'package:house_worker/data/service/auth_service.dart';
import 'package:house_worker/data/service/remote_config_service.dart';
import 'package:house_worker/ui/app_initial_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'root_presenter.g.dart';

/// アプリの初期ルート
///
/// アプリの起動時に表示される画面を決定するものであるため、
/// 依存関係の変更に伴った再計算はしない。
/// そのため、`watch` ではなく `read` を使用している。
@riverpod
Future<AppInitialRoute> appInitialRoute(Ref ref) async {
  // Remote Config ですでにフェッチされた値を有効化する
  await ref
      .read(updatedRemoteConfigKeysProvider.notifier)
      .ensureActivateFetchedRemoteConfigs();

  final minimumBuildNumber = ref.read(minimumBuildNumberProvider);
  if (minimumBuildNumber != null) {
    final currentAppVersion = await ref.read(currentAppVersionProvider.future);
    final currentBuildNumber = currentAppVersion.buildNumber;
    if (currentBuildNumber < minimumBuildNumber) {
      return const AppInitialRoute.updateApp();
    }
  }

  final isSignedIn = ref.read(isSignedInProvider);
  if (!isSignedIn) {
    return const AppInitialRoute.login();
  }

  final lastTalkedCavivaraId = await ref.read(
    lastTalkedCavivaraIdProvider.future,
  );
  if (lastTalkedCavivaraId != null) {
    return AppInitialRoute.home(cavivaraId: lastTalkedCavivaraId);
  }

  return const AppInitialRoute.jobMarket();
}

@riverpod
class CurrentAppSession extends _$CurrentAppSession {
  @override
  Future<AppSession> build() async {
    final isSignedIn = ref.watch(isSignedInProvider);
    if (!isSignedIn) {
      return AppSession.notSignedIn();
    }

    // TODO(ide): RevenueCatから取得する開発用。本番リリース時には削除する
    const isPro = false;

    return AppSession.signedIn(isPro: isPro);
  }

  Future<void> signIn({required String userId}) async {
    // TODO(ide): RevenueCatから取得する開発用。本番リリース時には削除する
    const isPro = false;

    state = AsyncValue.data(
      AppSession.signedIn(isPro: isPro),
    );
  }

  Future<void> signOut() async {
    state = AsyncValue.data(AppSession.notSignedIn());
  }

  Future<void> upgradeToPro() async {
    final currentAppSession = state.value;

    if (currentAppSession case AppSessionSignedIn()) {
      final newState = currentAppSession.copyWith(isPro: true);
      state = AsyncValue.data(newState);
    }
  }
}
