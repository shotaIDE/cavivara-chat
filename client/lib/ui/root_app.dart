import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/definition/app_feature.dart';
import 'package:house_worker/data/definition/flavor.dart';
import 'package:house_worker/data/service/remote_config_service.dart';
import 'package:house_worker/ui/app_initial_route.dart';
import 'package:house_worker/ui/component/animated_cavivara.dart';
import 'package:house_worker/ui/component/app_theme.dart';
import 'package:house_worker/ui/component/cat_fur_bubble_painter.dart';
import 'package:house_worker/ui/component/heads_up_notification_overlay.dart';
import 'package:house_worker/ui/feature/auth/login_screen.dart';
import 'package:house_worker/ui/feature/home/home_screen.dart';
import 'package:house_worker/ui/feature/stats/cavivara_reward.dart';
import 'package:house_worker/ui/feature/stats/user_statistics_screen.dart';
import 'package:house_worker/ui/feature/update/update_app_screen.dart';
import 'package:house_worker/ui/root_presenter.dart';

class RootApp extends ConsumerStatefulWidget {
  const RootApp({super.key});

  @override
  ConsumerState<RootApp> createState() => _RootAppState();
}

class _RootAppState extends ConsumerState<RootApp> {
  /// スプラッシュ画面の最小表示時間。
  static const _minSplashDuration = Duration(seconds: 1);

  final _navigatorKey = GlobalKey<NavigatorState>();

  Timer? _splashTimer;

  /// スプラッシュ画面の最小表示時間が経過したかどうか。
  bool _minSplashElapsed = false;

  @override
  void initState() {
    super.initState();

    _splashTimer = Timer(_minSplashDuration, () {
      if (mounted) {
        setState(() => _minSplashElapsed = true);
      }
    });

    ref.listenManual(updatedRemoteConfigKeysProvider, (_, next) {
      next.maybeWhen(
        data: (keys) {
          // Remote Config の変更を監視し、次回 `RootApp` が生成された際に有効になるようにする。
          // リスナー側が何も行わなくても、ライブラリは変更された値を保持する。
          // https://firebase.google.com/docs/remote-config/loading#strategy_3_load_new_values_for_next_startup
          debugPrint('Updated remote config keys: $keys');
        },
        orElse: () {},
      );
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appInitialRouteAsync = ref.watch(appInitialRouteProvider);
    final appInitialRoute = appInitialRouteAsync.whenOrNull(
      data: (appInitialRoute) => appInitialRoute,
    );
    if (appInitialRoute == null || !_minSplashElapsed) {
      return MaterialApp(
        title: 'カヴィヴァラチャット',
        theme: getLightTheme(),
        darkTheme: getDarkTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ja', 'JP'),
        ],
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Builder(
                builder: (context) {
                  // onSurface より少し控えめな前景色。
                  // ダークモードは明色、ライトモードは暗色になる。
                  return AnimatedCavivara(
                    strokeColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    // 輪郭内側を吹き出し横のアイコンと同じ最内層グレーで塗る。
                    fillColor: CatFurBubblePainter.innerSilhouetteColor(
                      Theme.of(context).brightness,
                    ),
                    // スプラッシュ画面ではウインクさせる。
                    eyeAnimation: CavivaraEyeAnimation.wink,
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    final List<MaterialPageRoute<Widget>> initialRoutes;

    switch (appInitialRoute) {
      case AppInitialRouteUpdateApp():
        initialRoutes = [UpdateAppScreen.route()];
      case AppInitialRouteLogin():
        initialRoutes = [LoginScreen.route()];
      case AppInitialRouteHome():
        initialRoutes = [HomeScreen.route()];
    }

    final navigatorObservers = <NavigatorObserver>[
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ];

    return MaterialApp(
      navigatorKey: _navigatorKey,
      routes: {'/': (_) => const HomeScreen()},
      // `initialRoute` and `routes` are ineffective settings
      // that are set to avoid assertion errors.
      initialRoute: '/',
      onGenerateInitialRoutes: (_) => initialRoutes,
      navigatorObservers: navigatorObservers,
      title: 'カヴィヴァラチャット',
      builder: (_, child) {
        final childWithOverlay = HeadsUpNotificationOverlay(
          onTapNotification: _onTapNotification,
          child: child,
        );
        return _wrapByAppBanner(childWithOverlay);
      },
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      // `_wrapByAppBanner` でオリジナルのバナーを表示するため、
      // デフォルトのデバッグバナーは無効化する
      debugShowCheckedModeBanner: false,
    );
  }

  Future<void> _onTapNotification(CavivaraReward reward) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    await navigator.pushAndRemoveUntil(
      UserStatisticsScreen.route(
        highlightedReward: reward,
      ),
      (route) => false,
    );
  }

  Widget _wrapByAppBanner(Widget? child) {
    if (!showCustomAppBanner) {
      return child!;
    }

    final message = flavor.name.toUpperCase();

    final Color color;
    switch (flavor) {
      case Flavor.emulator:
        color = Colors.green;
      case Flavor.dev:
        color = Colors.blue;
      case Flavor.prod:
        color = Colors.red;
    }

    return Banner(
      message: message,
      location: BannerLocation.topEnd,
      color: color,
      child: child,
    );
  }
}
