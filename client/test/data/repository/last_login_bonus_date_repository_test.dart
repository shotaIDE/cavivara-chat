import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/repository/last_login_bonus_date_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('LastLoginBonusDateRepository', () {
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
      test('永続化データがない場合はnullが返されること', () async {
        final lastDate = await container.read(
          lastLoginBonusDateRepositoryProvider.future,
        );

        expect(lastDate, isNull);
      });

      test('永続化データが存在する場合は永続化された値で初期化されること', () async {
        container.dispose();
        final date = DateTime(2026, 6, 20);
        SharedPreferences.setMockInitialValues({
          PreferenceKey.lastLoginBonusDate.name: date.toIso8601String(),
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.lastLoginBonusDate.name: date.toIso8601String(),
            });
        container = ProviderContainer();

        final lastDate = await container.read(
          lastLoginBonusDateRepositoryProvider.future,
        );

        expect(lastDate, equals(date));
      });
    });

    group('付与日の保存', () {
      test('付与日を保存できること', () async {
        final date = DateTime(2026, 6, 20);

        await container
            .read(lastLoginBonusDateRepositoryProvider.notifier)
            .save(date);

        final lastDate = await container.read(
          lastLoginBonusDateRepositoryProvider.future,
        );
        expect(lastDate, equals(date));
      });

      test('付与日が永続化されること', () async {
        final date = DateTime(2026, 6, 20);

        await container
            .read(lastLoginBonusDateRepositoryProvider.notifier)
            .save(date);

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final lastDate = await newContainer.read(
          lastLoginBonusDateRepositoryProvider.future,
        );

        expect(lastDate, equals(date));
      });

      test('付与日を複数回保存した場合に最後の値が保存されること', () async {
        final notifier = container.read(
          lastLoginBonusDateRepositoryProvider.notifier,
        );

        await notifier.save(DateTime(2026, 6, 19));
        await notifier.save(DateTime(2026, 6, 20));

        final lastDate = await container.read(
          lastLoginBonusDateRepositoryProvider.future,
        );
        expect(lastDate, equals(DateTime(2026, 6, 20)));
      });
    });

    group('付与状態のリセット', () {
      test('リセット後にnullになること', () async {
        final notifier = container.read(
          lastLoginBonusDateRepositoryProvider.notifier,
        );

        await notifier.save(DateTime(2026, 6, 20));
        await notifier.resetForDebug();

        final lastDate = await container.read(
          lastLoginBonusDateRepositoryProvider.future,
        );
        expect(lastDate, isNull);
      });

      test('リセットが永続化されること', () async {
        final notifier = container.read(
          lastLoginBonusDateRepositoryProvider.notifier,
        );

        await notifier.save(DateTime(2026, 6, 20));
        await notifier.resetForDebug();

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final lastDate = await newContainer.read(
          lastLoginBonusDateRepositoryProvider.future,
        );

        expect(lastDate, isNull);
      });
    });
  });
}
