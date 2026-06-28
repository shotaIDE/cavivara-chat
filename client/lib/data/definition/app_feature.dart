import 'package:flutter/foundation.dart';
import 'package:house_worker/data/definition/flavor.dart';

/// 右上肩にバナーを表示するか否か
///
/// 一般公開アプリ以外は常に表示する
final bool showCustomAppBanner =
    (flavor == Flavor.prod && !kReleaseMode) || flavor != Flavor.prod;

final useFirebaseEmulator = flavor == Flavor.emulator;

/// エラーの詳細内容を UI に表示するか否か
///
/// 一般公開アプリのリリースビルドでは、内部的なエラー詳細をユーザーに見せないため表示しない。
/// `kReleaseMode` を先に評価することで、`FLUTTER_APP_FLAVOR` 未指定のテスト環境では
/// 例外を投げる `flavor` の参照を回避する。
final bool showErrorDetail = !(kReleaseMode && flavor == Flavor.prod);

const bool isAnalyticsEnabled =
    String.fromEnvironment('ENABLE_ANALYTICS') == 'true' || kReleaseMode;

const bool isCrashlyticsEnabled =
    String.fromEnvironment('ENABLE_CRASHLYTICS') == 'true' || kReleaseMode;

/// RevenueCat のテスト用ストアを使用するか否か
///
/// RevenueCat のテスト用ストアはリリースモードでの実行が禁止されているため、
/// それ以外で利用する。
final RevenueCatMode revenueCatMode = flavor == Flavor.prod
    ? RevenueCatMode.useProductionStore
    : (kReleaseMode ? RevenueCatMode.useMockData : RevenueCatMode.useTestStore);

enum RevenueCatMode {
  useMockData,
  useTestStore,
  useProductionStore,
}
