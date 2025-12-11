import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'viva_point_repository.g.dart';

@riverpod
class VivaPointRepository extends _$VivaPointRepository {
  @override
  Future<int> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final vivaPoint = await preferenceService.getInt(
      PreferenceKey.totalVivaPoint,
    );
    return vivaPoint ?? 0;
  }

  /// VPを設定
  Future<void> setPoint(int point) async {
    final preferenceService = ref.read(preferenceServiceProvider);

    await preferenceService.setInt(
      PreferenceKey.totalVivaPoint,
      value: point,
    );

    if (!ref.mounted) {
      return;
    }

    state = AsyncValue.data(point);
  }

  /// VPをリセット (デバッグ用)
  Future<void> reset() async {
    final preferenceService = ref.read(preferenceServiceProvider);

    await preferenceService.setInt(
      PreferenceKey.totalVivaPoint,
      value: 0,
    );

    if (!ref.mounted) {
      return;
    }

    state = const AsyncValue.data(0);
  }
}
