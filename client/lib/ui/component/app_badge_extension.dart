import 'package:flutter/material.dart';
import 'package:house_worker/data/model/app_badge.dart';

extension AppBadgeExtension on AppBadge {
  String get displayName => switch (this) {
    AppBadge.firstLaunch => 'カヴィヴァラの世界に足を踏み入れる',
  };

  IconData get icon => switch (this) {
    AppBadge.firstLaunch => Icons.emoji_events,
  };
}
