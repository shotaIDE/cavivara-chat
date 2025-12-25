import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sent_chat_string_count_repository.g.dart';

@riverpod
class SentChatStringCountRepository extends _$SentChatStringCountRepository {
  @override
  Future<int> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    return await preferenceService.getInt(
          PreferenceKey.totalSentChatStringCount,
        ) ??
        0;
  }

  Future<void> add(int stringCount) async {
    final preferenceService = ref.read(preferenceServiceProvider);

    if (stringCount <= 0) {
      return;
    }

    final current = await future;
    final updated = current + stringCount;
    await preferenceService.setInt(
      PreferenceKey.totalSentChatStringCount,
      value: updated,
    );

    if (!ref.mounted) {
      return;
    }
    state = AsyncValue.data(updated);
  }
}
