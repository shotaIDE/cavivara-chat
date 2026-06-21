import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'heads_up_notification_presenter.freezed.dart';
part 'heads_up_notification_presenter.g.dart';

@freezed
sealed class HeadsUpNotificationState with _$HeadsUpNotificationState {
  const factory HeadsUpNotificationState.hidden() = _Hidden;

  /// 初回メッセージボーナスの通知
  const factory HeadsUpNotificationState.firstMessageBonus({
    required int earnedVP,
    required String newTitleName,
  }) = _FirstMessageBonus;

  /// ログインボーナスの通知
  const factory HeadsUpNotificationState.dailyLoginBonus({
    required int earnedVP,
  }) = _DailyLoginBonus;
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

  /// ログインボーナスの通知を表示
  void showDailyLoginBonus({required int earnedVP}) {
    _dismissTimer?.cancel();
    state = HeadsUpNotificationState.dailyLoginBonus(earnedVP: earnedVP);
    _dismissTimer = Timer(const Duration(seconds: 5), hide);
  }

  void hide() {
    _dismissTimer?.cancel();
    state = const HeadsUpNotificationState.hidden();
  }
}
