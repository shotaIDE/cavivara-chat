import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/repository/feedback_email_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('FeedbackEmailRepository', () {
    const dummyEmail = 'your.name@example.com';

    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('初期状態', () {
      test('永続化データがない場合は空文字が返されること', () async {
        final email = await container.read(
          feedbackEmailRepositoryProvider.future,
        );

        expect(email, equals(''));
      });

      test('永続化データが存在する場合は永続化された値で初期化されること', () async {
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.feedbackEmail.name: dummyEmail,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.feedbackEmail.name: dummyEmail,
            });
        container = ProviderContainer();

        final email = await container.read(
          feedbackEmailRepositoryProvider.future,
        );

        expect(email, equals(dummyEmail));
      });
    });

    group('保存', () {
      test('保存した内容が状態に反映されること', () async {
        await container
            .read(feedbackEmailRepositoryProvider.notifier)
            .save(dummyEmail);

        final email = await container.read(
          feedbackEmailRepositoryProvider.future,
        );

        expect(email, equals(dummyEmail));
      });

      test('保存した内容が永続化されること', () async {
        await container
            .read(feedbackEmailRepositoryProvider.notifier)
            .save(dummyEmail);

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final email = await newContainer.read(
          feedbackEmailRepositoryProvider.future,
        );

        expect(email, equals(dummyEmail));
      });
    });

    group('削除', () {
      test('削除すると空文字が返されること', () async {
        await container
            .read(feedbackEmailRepositoryProvider.notifier)
            .save(dummyEmail);

        await container.read(feedbackEmailRepositoryProvider.notifier).clear();

        final email = await container.read(
          feedbackEmailRepositoryProvider.future,
        );

        expect(email, equals(''));
      });

      test('削除した内容が永続化されること', () async {
        await container
            .read(feedbackEmailRepositoryProvider.notifier)
            .save(dummyEmail);

        await container.read(feedbackEmailRepositoryProvider.notifier).clear();

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final email = await newContainer.read(
          feedbackEmailRepositoryProvider.future,
        );

        expect(email, equals(''));
      });
    });
  });
}
