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

  /// VPを加算
  Future<void> add(int point) async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final currentVp = state.value ?? 0;
    final newVp = currentVp + point;

    await preferenceService.setInt(
      PreferenceKey.totalVivaPoint,
      value: newVp,
    );

    if (ref.mounted) {
      state = AsyncValue.data(newVp);
    }
  }

  /// VPをリセット (デバッグ用)
  Future<void> reset() async {
    final preferenceService = ref.read(preferenceServiceProvider);

    await preferenceService.setInt(
      PreferenceKey.totalVivaPoint,
      value: 0,
    );

    if (ref.mounted) {
      state = const AsyncValue.data(0);
    }
  }
}
