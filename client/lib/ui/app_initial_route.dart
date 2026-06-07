import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_initial_route.freezed.dart';

@freezed
sealed class AppInitialRoute with _$AppInitialRoute {
  const factory AppInitialRoute.updateApp() = AppInitialRouteUpdateApp;
  const factory AppInitialRoute.login() = AppInitialRouteLogin;
  const factory AppInitialRoute.home({required String cavivaraId}) =
      AppInitialRouteHome;
}
