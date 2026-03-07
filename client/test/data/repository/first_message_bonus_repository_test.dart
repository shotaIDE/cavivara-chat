import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/repository/first_message_bonus_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('FirstMessageBonusRepository', () {
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
      test('永続化データがない場合はfalseが返されること', () async {
        final hasReceived = await container.read(
          firstMessageBonusRepositoryProvider.future,
        );

        expect(hasReceived, isFalse);
      });

      test('永続化データがtrueの場合はtrueが返されること', () async {
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.hasReceivedFirstMessageBonus.name: true,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
          PreferenceKey.hasReceivedFirstMessageBonus.name: true,
        });
        container = ProviderContainer();

        final hasReceived = await container.read(
          firstMessageBonusRepositoryProvider.future,
        );

        expect(hasReceived, isTrue);
      });
    });

    group('markAsReceived', () {
      test('ボーナス受け取り済みとしてマークできること', () async {
        await container
            .read(firstMessageBonusRepositoryProvider.notifier)
            .markAsReceived();

        final hasReceived = await container.read(
          firstMessageBonusRepositoryProvider.future,
        );
        expect(hasReceived, isTrue);
      });

      test('マークが永続化されること', () async {
        await container
            .read(firstMessageBonusRepositoryProvider.notifier)
            .markAsReceived();

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final hasReceived = await newContainer.read(
          firstMessageBonusRepositoryProvider.future,
        );

        expect(hasReceived, isTrue);
      });
    });

    group('resetForDebug', () {
      test('リセット後にfalseになること', () async {
        final notifier = container.read(
          firstMessageBonusRepositoryProvider.notifier,
        );

        await notifier.markAsReceived();
        await notifier.resetForDebug();

        final hasReceived = await container.read(
          firstMessageBonusRepositoryProvider.future,
        );
        expect(hasReceived, isFalse);
      });

      test('リセットが永続化されること', () async {
        final notifier = container.read(
          firstMessageBonusRepositoryProvider.notifier,
        );

        await notifier.markAsReceived();
        await notifier.resetForDebug();

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final hasReceived = await newContainer.read(
          firstMessageBonusRepositoryProvider.future,
        );

        expect(hasReceived, isFalse);
      });
    });

    group('状態通知', () {
      test('マーク時にプロバイダーが通知されること', () async {
        // 初期化のために一度読み込む
        await container.read(firstMessageBonusRepositoryProvider.future);

        final notifier = container.read(
          firstMessageBonusRepositoryProvider.notifier,
        );
        var notificationCount = 0;

        container.listen<AsyncValue<bool>>(
          firstMessageBonusRepositoryProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        await notifier.markAsReceived();
        expect(notificationCount, equals(1));
      });
    });
  });
}
