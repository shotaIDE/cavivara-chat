import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'has_ever_sent_message_repository.g.dart';

@riverpod
class HasEverSentMessageRepository extends _$HasEverSentMessageRepository {
  @override
  Future<bool> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final value = await preferenceService.getBool(
      PreferenceKey.hasEverSentMessage,
    );
    return value ?? false;
  }

  Future<void> markAsSent() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setBool(
      PreferenceKey.hasEverSentMessage,
      value: true,
    );

    if (!ref.mounted) {
      return;
    }
    state = const AsyncValue.data(true);
  }
}
