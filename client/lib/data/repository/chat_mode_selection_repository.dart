import 'package:house_worker/data/model/chat_mode.dart';
import 'package:house_worker/data/model/chat_mode_selection.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_mode_selection_repository.g.dart';

@riverpod
class ChatModeSelectionRepository extends _$ChatModeSelectionRepository {
  @override
  Future<ChatModeSelection> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final storedValue = await preferenceService.getString(
      PreferenceKey.chatModeSelection,
    );
    return _decode(storedValue);
  }

  /// 回答モードの選択を保存する
  Future<void> save(ChatModeSelection selection) async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setString(
      PreferenceKey.chatModeSelection,
      value: _encode(selection),
    );

    if (!ref.mounted) {
      return;
    }

    state = AsyncValue.data(selection);
  }

  static ChatModeSelection _decode(String? storedValue) {
    for (final mode in ChatMode.values) {
      if (storedValue == mode.name) {
        return ChatModeSelection.fixed(mode);
      }
    }

    return const ChatModeSelection.auto();
  }

  static String _encode(ChatModeSelection selection) {
    return switch (selection) {
      ChatModeSelectionAuto() => 'auto',
      ChatModeSelectionFixed(:final mode) => mode.name,
    };
  }
}
