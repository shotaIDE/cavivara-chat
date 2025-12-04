import 'dart:convert';

import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/model/support_history.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'support_history_repository.g.dart';

@riverpod
class SupportHistoryRepository extends _$SupportHistoryRepository {
  @override
  Future<List<SupportHistory>> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final jsonString = await preferenceService.getString(
      PreferenceKey.supportHistoryList,
    );

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => SupportHistory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// 履歴を追加
  Future<void> addHistory(SupportHistory history) async {
    final preferenceService = ref.read(preferenceServiceProvider);

    // 現在の履歴を取得
    final currentHistories = await future;

    // 新しい履歴を先頭に追加（最新が先頭）
    final updatedHistories = [history, ...currentHistories];

    // JSON形式で保存
    final jsonList = updatedHistories.map((h) => h.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    await preferenceService.setString(
      PreferenceKey.supportHistoryList,
      value: jsonString,
    );

    if (!ref.mounted) {
      return;
    }

    state = AsyncValue.data(updatedHistories);
  }

  /// 履歴をクリア（デバッグ用）
  Future<void> clear() async {
    final preferenceService = ref.read(preferenceServiceProvider);

    await preferenceService.setString(
      PreferenceKey.supportHistoryList,
      value: '',
    );

    if (!ref.mounted) {
      return;
    }

    state = const AsyncValue.data([]);
  }
}
