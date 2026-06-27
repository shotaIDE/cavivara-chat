import 'package:flutter/material.dart';
import 'package:house_worker/data/model/app_badge.dart';

extension AppBadgeExtension on AppBadge {
  String get displayName => switch (this) {
    AppBadge.firstLaunch => 'カヴィヴァラの世界に足を踏み入れる',
  };

  IconData get icon => switch (this) {
    // 「足を踏み入れる」をモチーフにした歩くアイコン
    AppBadge.firstLaunch => Icons.directions_walk,
  };

  /// バッジの背景に使うグラデーション色（左上→右下）
  List<Color> get gradientColors => switch (this) {
    AppBadge.firstLaunch => const [
      Color(0xFFFFE082),
      Color(0xFFFFB300),
      Color(0xFFEF6C00),
    ],
  };

  String get description => switch (this) {
    AppBadge.firstLaunch => 'アプリを始めて起動しました。',
  };
}
