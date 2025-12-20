import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_worker/data/definition/app_definition.dart';
import 'package:house_worker/data/definition/app_feature.dart';
import 'package:house_worker/data/definition/flavor.dart';
import 'package:house_worker/data/service/in_app_purchase_service.dart';
import 'package:house_worker/data/service/in_app_purchase_service_mock.dart';
import 'package:house_worker/ui/root_app.dart';
import 'package:logging/logging.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// TODO(ide): 本番環境を構築した後、_prod ファイルをインポートするように修正する
import 'firebase_options_dev.dart' as prod;
// import 'firebase_options_prod.dart' as prod;
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_emulator.dart' as emulator;

final _logger = Logger('CavivaraTalk');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _setupLogging();

  try {
    await Firebase.initializeApp(options: _getFirebaseOptions());

    if (useFirebaseEmulator) {
      await _setupFirebaseEmulators();
      _logger.info('Firebase Emulator: true');
    } else {
      _logger.info('Firebase Emulator: false');
    }
  } on Exception catch (e) {
    _logger.severe('Failed to initialize Firebase', e);
    // Firebase が初期化できなくても、アプリを続行する
  }

  // アプリのライフサイクル全体で一度だけの初期化する
  await GoogleSignIn.instance.initialize();

  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
    isAnalyticsEnabled,
  );
  _logger.info('Firebase Analytics: $isAnalyticsEnabled');

  if (isCrashlyticsEnabled) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    _logger.info('Firebase Crashlytics: true');
  } else {
    _logger.info('Firebase Crashlytics: false');
  }

  await _setupRevenueCat();

  runApp(
    ProviderScope(
      overrides: _getOverrides(),
      child: const RootApp(),
    ),
  );
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // 開発環境では詳細なログを出力
    final message =
        '${record.level.name}: ${record.time}: '
        '${record.loggerName}: ${record.message}';

    // エラーと警告はスタックトレースも出力
    if (record.level >= Level.WARNING && record.error != null) {
      debugPrint('$message\nError: ${record.error}\n${record.stackTrace}');
    } else {
      debugPrint(message);
    }
  });
}

FirebaseOptions? _getFirebaseOptions() {
  switch (flavor) {
    case Flavor.emulator:
      return emulator.DefaultFirebaseOptions.currentPlatform;
    case Flavor.dev:
      return dev.DefaultFirebaseOptions.currentPlatform;
    case Flavor.prod:
      return prod.DefaultFirebaseOptions.currentPlatform;
  }
}

Future<void> _setupFirebaseEmulators() async {
  final host = _getEmulatorHost();
  _logger.info('Emulator host: $host');

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
}

String _getEmulatorHost() {
  try {
    const emulatorHost = String.fromEnvironment(
      'EMULATOR_HOST',
      defaultValue: '127.0.0.1',
    );
    return emulatorHost;
  } on Exception catch (e) {
    _logger.warning('Failed to get emulator host: ', e);

    return '127.0.0.1';
  }
}

Future<void> _setupRevenueCat() async {
  final PurchasesConfiguration configuration;

  if (useRevenueCatTestStore) {
    configuration = PurchasesConfiguration(revenueCatProjectTestApiKey);
  } else {
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(revenueCatProjectGoogleApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(revenueCatProjectAppleApiKey);
    } else {
      throw Exception('Unsupported platform: ${Platform.operatingSystem}');
    }
  }

  await Purchases.configure(configuration);
}

List<Override> _getOverrides() {
  final overrides = <Override>[];

  if (useRevenueCatTestStore) {
    overrides.addAll([
      currentPackagesProvider.overrideWith(currentPackagesMock),
      inAppPurchaseServiceProvider.overrideWith(inAppPurchaseServiceMock),
    ]);
  }

  return overrides;
}
