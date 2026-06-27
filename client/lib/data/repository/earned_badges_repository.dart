import 'dart:convert';

import 'package:house_worker/data/model/earned_badge.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'earned_badges_repository.g.dart';

/// 獲得済みバッジの一覧を永続化するリポジトリ
@riverpod
class EarnedBadgesRepository extends _$EarnedBadgesRepository {
  @override
  Future<List<EarnedBadge>> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final jsonString = await preferenceService.getString(
      PreferenceKey.earnedBadgeList,
    );

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => EarnedBadge.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// バッジを追加する（最新が先頭）
  Future<void> add(EarnedBadge badge) async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final current = await future;

    final updated = [badge, ...current];

    final jsonList = updated.map((b) => b.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    await preferenceService.setString(
      PreferenceKey.earnedBadgeList,
      value: jsonString,
    );

    if (!ref.mounted) {
      return;
    }

    state = AsyncValue.data(updated);
  }

  /// 獲得済みバッジの一覧をリセットする (デバッグ用)
  Future<void> resetForDebug() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.remove(PreferenceKey.earnedBadgeList);

    if (!ref.mounted) {
      return;
    }
    state = const AsyncValue.data(<EarnedBadge>[]);
  }
}
