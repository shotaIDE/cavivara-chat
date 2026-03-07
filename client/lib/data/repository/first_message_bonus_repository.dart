import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'first_message_bonus_repository.g.dart';

/// 初回メッセージ送信時のVPボーナスを付与したかどうかを管理するリポジトリ
@riverpod
class FirstMessageBonusRepository extends _$FirstMessageBonusRepository {
  @override
  Future<bool> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final value = await preferenceService.getBool(
      PreferenceKey.hasReceivedFirstMessageBonus,
    );
    return value ?? false;
  }

  /// ボーナスを付与済みとしてマーク
  Future<void> markAsReceived() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setBool(
      PreferenceKey.hasReceivedFirstMessageBonus,
      value: true,
    );

    if (!ref.mounted) {
      return;
    }
    state = const AsyncValue.data(true);
  }

  /// デバッグ用リセット
  Future<void> resetForDebug() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setBool(
      PreferenceKey.hasReceivedFirstMessageBonus,
      value: false,
    );

    if (!ref.mounted) {
      return;
    }
    state = const AsyncValue.data(false);
  }
}
