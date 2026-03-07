import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/ui/feature/stats/cavivara_reward.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'heads_up_notification_presenter.freezed.dart';
part 'heads_up_notification_presenter.g.dart';

@freezed
sealed class HeadsUpNotificationState with _$HeadsUpNotificationState {
  const factory HeadsUpNotificationState.hidden() = _Hidden;

  const factory HeadsUpNotificationState.visible(
    CavivaraReward reward,
  ) = _Visible;

  /// 初回メッセージボーナスの通知
  const factory HeadsUpNotificationState.firstMessageBonus({
    required int earnedVP,
    required String newTitleName,
  }) = _FirstMessageBonus;
}

@riverpod
class HeadsUpNotification extends _$HeadsUpNotification {
  Timer? _dismissTimer;

  @override
  HeadsUpNotificationState build() {
    ref.onDispose(() {
      _dismissTimer?.cancel();
    });
    return const HeadsUpNotificationState.hidden();
  }

  void show(CavivaraReward reward) {
    _dismissTimer?.cancel();
    state = HeadsUpNotificationState.visible(reward);
    _dismissTimer = Timer(const Duration(seconds: 5), hide);
  }

  /// 初回メッセージボーナスの通知を表示
  void showFirstMessageBonus({
    required int earnedVP,
    required String newTitleName,
  }) {
    _dismissTimer?.cancel();
    state = HeadsUpNotificationState.firstMessageBonus(
      earnedVP: earnedVP,
      newTitleName: newTitleName,
    );
    _dismissTimer = Timer(const Duration(seconds: 5), hide);
  }

  void hide() {
    _dismissTimer?.cancel();
    state = const HeadsUpNotificationState.hidden();
  }
}
