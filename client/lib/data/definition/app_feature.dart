import 'package:flutter/foundation.dart';
import 'package:house_worker/data/definition/flavor.dart';

/// 右上肩にバナーを表示するか否か
///
/// 一般公開アプリ以外は常に表示する
final bool showCustomAppBanner =
    (flavor == Flavor.prod && !kReleaseMode) || flavor != Flavor.prod;

final useFirebaseEmulator = flavor == Flavor.emulator;

const bool isAnalyticsEnabled =
    String.fromEnvironment('ENABLE_ANALYTICS') == 'true' || kReleaseMode;

const bool isCrashlyticsEnabled =
    String.fromEnvironment('ENABLE_CRASHLYTICS') == 'true' || kReleaseMode;

/// RevenueCat のテスト用ストアを使用するか否か
///
/// RevenueCat のテスト用ストアはリリースモードでの実行が禁止されているため、
/// それ以外で利用する。
final bool useRevenueCatTestStore = !kReleaseMode && flavor != Flavor.prod;
