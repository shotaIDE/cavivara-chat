import 'package:flutter/material.dart';
import 'package:house_worker/data/model/app_badge.dart';

extension AppBadgeExtension on AppBadge {
  String get displayName => switch (this) {
    AppBadge.firstLaunch => 'カヴィヴァラの世界に足を踏み入れる',
    AppBadge.plectrumConcertVol11 => '結社公演Vol.11の出席者',
  };

  IconData get icon => switch (this) {
    // 「足を踏み入れる」をモチーフにした歩くアイコン
    AppBadge.firstLaunch => Icons.directions_walk,
    // 来場をモチーフにしたお祝いアイコン（画像が無い場合のフォールバック）
    AppBadge.plectrumConcertVol11 => Icons.celebration,
  };

  /// バッジの背景に使うグラデーション色（左上→右下）
  List<Color> get gradientColors => switch (this) {
    AppBadge.firstLaunch => const [
      Color(0xFFFFE082),
      Color(0xFFFFB300),
      Color(0xFFEF6C00),
    ],
    AppBadge.plectrumConcertVol11 => const [
      Color(0xFF424242),
      Color(0xFF212121),
      Color(0xFF000000),
    ],
  };

  /// バッジに使う画像のアセットパス。
  ///
  /// 画像を持つバッジの場合のみパスを返し、アイコンで表現するバッジでは null を返す。
  String? get imagePath => switch (this) {
    AppBadge.firstLaunch => null,
    AppBadge.plectrumConcertVol11 =>
      'assets/image/plectrum-rc-eye-catch_11.png',
  };

  String get description => switch (this) {
    AppBadge.firstLaunch => 'アプリを初めて起動しました。',
    AppBadge.plectrumConcertVol11 => 'プレクトラム結社公演Vol.11に来場しました。',
  };
}
