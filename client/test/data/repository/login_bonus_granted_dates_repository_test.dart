import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/repository/login_bonus_granted_dates_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('LoginBonusGrantedDatesRepository', () {
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
      test('永続化データがない場合は空のリストが返されること', () async {
        final dates = await container.read(
          loginBonusGrantedDatesRepositoryProvider.future,
        );

        expect(dates, isEmpty);
      });

      test('永続化データが存在する場合は永続化された値で初期化されること', () async {
        container.dispose();
        final stored = [
          DateTime(2026, 6, 19).toIso8601String(),
          DateTime(2026, 6, 20).toIso8601String(),
        ];
        SharedPreferences.setMockInitialValues({
          PreferenceKey.loginBonusGrantedDates.name: stored,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.loginBonusGrantedDates.name: stored,
            });
        container = ProviderContainer();

        final dates = await container.read(
          loginBonusGrantedDatesRepositoryProvider.future,
        );

        expect(dates, equals([DateTime(2026, 6, 19), DateTime(2026, 6, 20)]));
      });
    });

    group('付与日の追加', () {
      test('付与日を追加できること', () async {
        await container
            .read(loginBonusGrantedDatesRepositoryProvider.notifier)
            .add(DateTime(2026, 6, 20));

        final dates = await container.read(
          loginBonusGrantedDatesRepositoryProvider.future,
        );
        expect(dates, equals([DateTime(2026, 6, 20)]));
      });

      test('複数の付与日を追加した場合に全て保持されること', () async {
        final notifier = container.read(
          loginBonusGrantedDatesRepositoryProvider.notifier,
        );

        await notifier.add(DateTime(2026, 6, 19));
        await notifier.add(DateTime(2026, 6, 20));

        final dates = await container.read(
          loginBonusGrantedDatesRepositoryProvider.future,
        );
        expect(dates, equals([DateTime(2026, 6, 19), DateTime(2026, 6, 20)]));
      });

      test('付与日が永続化されること', () async {
        await container
            .read(loginBonusGrantedDatesRepositoryProvider.notifier)
            .add(DateTime(2026, 6, 20));

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final dates = await newContainer.read(
          loginBonusGrantedDatesRepositoryProvider.future,
        );

        expect(dates, equals([DateTime(2026, 6, 20)]));
      });
    });

    group('付与日のリセット', () {
      test('リセット後に空のリストになること', () async {
        final notifier = container.read(
          loginBonusGrantedDatesRepositoryProvider.notifier,
        );

        await notifier.add(DateTime(2026, 6, 20));
        await notifier.resetForDebug();

        final dates = await container.read(
          loginBonusGrantedDatesRepositoryProvider.future,
        );
        expect(dates, isEmpty);
      });

      test('リセットが永続化されること', () async {
        final notifier = container.read(
          loginBonusGrantedDatesRepositoryProvider.notifier,
        );

        await notifier.add(DateTime(2026, 6, 20));
        await notifier.resetForDebug();

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final dates = await newContainer.read(
          loginBonusGrantedDatesRepositoryProvider.future,
        );

        expect(dates, isEmpty);
      });
    });
  });
}
