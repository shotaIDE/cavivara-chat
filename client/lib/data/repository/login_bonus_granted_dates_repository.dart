import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_bonus_granted_dates_repository.g.dart';

/// ログインボーナスを付与した日付の一覧を永続化するリポジトリ。
///
/// 1日1回のログインボーナス付与判定に使用する。各日付は時刻を切り捨てた
/// 日付単位で保持し、同一日付に対する重複付与を防ぐ。
@riverpod
class LoginBonusGrantedDatesRepository
    extends _$LoginBonusGrantedDatesRepository {
  @override
  Future<List<DateTime>> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final values = await preferenceService.getStringList(
      PreferenceKey.loginBonusGrantedDates,
    );
    if (values == null) {
      return [];
    }
    return values
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .toList(growable: false);
  }

  /// 付与した日付を追加する。
  Future<void> add(DateTime date) async {
    final currentDates = await future;
    final newDates = [...currentDates, date];

    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setStringList(
      PreferenceKey.loginBonusGrantedDates,
      value: newDates.map((date) => date.toIso8601String()).toList(),
    );

    if (!ref.mounted) {
      return;
    }
    state = AsyncValue.data(newDates);
  }

  /// 付与日の一覧をリセット (デバッグ用)
  Future<void> resetForDebug() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.remove(PreferenceKey.loginBonusGrantedDates);

    if (!ref.mounted) {
      return;
    }
    state = const AsyncValue.data(<DateTime>[]);
  }
}
