import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'skip_clear_chat_confirmation_repository.g.dart';

@riverpod
class SkipClearChatConfirmation extends _$SkipClearChatConfirmation {
  @override
  Future<bool> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final value = await preferenceService.getBool(
      PreferenceKey.skipClearChatConfirmation,
    );
    return _generateCurrentValue(value);
  }

  Future<void> setShouldSkip() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setBool(
      PreferenceKey.skipClearChatConfirmation,
      value: true,
    );

    if (!ref.mounted) {
      return;
    }

    state = const AsyncValue.data(true);
  }

  Future<void> resetForDebug() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.remove(
      PreferenceKey.skipClearChatConfirmation,
    );

    if (!ref.mounted) {
      return;
    }

    state = AsyncValue.data(
      _generateCurrentValue(null),
    );
  }

  bool _generateCurrentValue(bool? storedValue) {
    return storedValue ?? false;
  }
}
