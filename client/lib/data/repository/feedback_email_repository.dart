import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feedback_email_repository.g.dart';

@riverpod
class FeedbackEmailRepository extends _$FeedbackEmailRepository {
  @override
  Future<String> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final storedValue = await preferenceService.getString(
      PreferenceKey.feedbackEmail,
    );
    return storedValue ?? '';
  }

  /// 返信用メールアドレスを保存する
  Future<void> save(String email) async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setString(
      PreferenceKey.feedbackEmail,
      value: email,
    );

    if (!ref.mounted) {
      return;
    }

    state = AsyncValue.data(email);
  }

  /// 保存した返信用メールアドレスを削除する
  Future<void> clear() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.remove(PreferenceKey.feedbackEmail);

    if (!ref.mounted) {
      return;
    }

    state = const AsyncValue.data('');
  }
}
