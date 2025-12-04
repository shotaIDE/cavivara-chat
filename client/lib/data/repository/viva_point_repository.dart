import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';
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

  /// 累計VPから現在の称号を算出
  SupporterTitle getCurrentTitle(int totalVP) {
    // 降順でチェックし、最初に条件を満たす称号を返す
    for (final title in SupporterTitle.values.reversed) {
      if (totalVP >= title.requiredVP) {
        return title;
      }
    }
    // ここには到達しないはずだが、万が一の場合は最低ランクを返す
    return SupporterTitle.newbie;
  }

  /// 次の称号を取得（最上位の場合はnull）
  SupporterTitle? getNextTitle(int totalVP) {
    final currentTitle = getCurrentTitle(totalVP);
    final currentIndex = SupporterTitle.values.indexOf(currentTitle);

    // 最上位称号の場合はnullを返す
    if (currentIndex == SupporterTitle.values.length - 1) {
      return null;
    }

    return SupporterTitle.values[currentIndex + 1];
  }

  /// 次の称号までに必要なVP数を取得（最上位の場合は0）
  int getVPToNextTitle(int totalVP) {
    final nextTitle = getNextTitle(totalVP);

    // 最上位称号の場合は0を返す
    if (nextTitle == null) {
      return 0;
    }

    return nextTitle.requiredVP - totalVP;
  }
}
