import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'last_login_bonus_date_repository.g.dart';

/// ログインボーナスを最後に付与した日付を永続化するリポジトリ。
///
/// 1日1回のログインボーナス付与判定に使用する。付与日が存在しない場合は `null` を返す。
@riverpod
class LastLoginBonusDateRepository extends _$LastLoginBonusDateRepository {
  @override
  Future<DateTime?> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final value = await preferenceService.getString(
      PreferenceKey.lastLoginBonusDate,
    );
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  /// ログインボーナスを付与した日付を保存する。
  Future<void> save(DateTime date) async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setString(
      PreferenceKey.lastLoginBonusDate,
      value: date.toIso8601String(),
    );

    if (!ref.mounted) {
      return;
    }
    state = AsyncValue.data(date);
  }

  /// 付与日をリセット (デバッグ用)
  Future<void> resetForDebug() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.remove(PreferenceKey.lastLoginBonusDate);

    if (!ref.mounted) {
      return;
    }
    state = const AsyncValue.data(null);
  }
}
