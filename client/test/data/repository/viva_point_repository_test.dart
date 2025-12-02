import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('VivaPointRepository', () {
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
      test('永続化データがない場合は0が返されること', () async {
        final vivaPoint = await container.read(
          vivaPointRepositoryProvider.future,
        );

        expect(vivaPoint, equals(0));
      });

      test('永続化データが存在する場合は永続化された値で初期化されること', () async {
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 10,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 10,
            });
        container = ProviderContainer();

        final vivaPoint = await container.read(
          vivaPointRepositoryProvider.future,
        );

        expect(vivaPoint, equals(10));
      });
    });

    group('VPの設定', () {
      test('VPを設定できること', () async {
        await container
            .read(vivaPointRepositoryProvider.notifier)
            .setPoint(100);

        final vivaPoint = await container.read(
          vivaPointRepositoryProvider.future,
        );
        expect(vivaPoint, equals(100));
      });

      test('VPを複数回設定した場合に最後の値が保存されること', () async {
        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );

        await notifier.setPoint(50);
        await notifier.setPoint(75);

        final vivaPoint = await container.read(
          vivaPointRepositoryProvider.future,
        );
        expect(vivaPoint, equals(75));
      });

      test('VPが設定されて永続化されること', () async {
        await container
            .read(vivaPointRepositoryProvider.notifier)
            .setPoint(200);

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final vivaPoint = await newContainer.read(
          vivaPointRepositoryProvider.future,
        );

        expect(vivaPoint, equals(200));
      });

      test('既存のVPを上書きできること', () async {
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 100,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 100,
            });
        container = ProviderContainer();

        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );
        await notifier.setPoint(300);

        final vivaPoint = await container.read(
          vivaPointRepositoryProvider.future,
        );
        expect(vivaPoint, equals(300));
      });
    });

    group('VPのリセット', () {
      test('リセット後に0になること', () async {
        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );

        await notifier.setPoint(100);
        await notifier.reset();

        final vivaPoint = await container.read(
          vivaPointRepositoryProvider.future,
        );
        expect(vivaPoint, equals(0));
      });

      test('リセットが永続化されること', () async {
        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );

        await notifier.setPoint(100);
        await notifier.reset();

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final vivaPoint = await newContainer.read(
          vivaPointRepositoryProvider.future,
        );

        expect(vivaPoint, equals(0));
      });
    });

    group('状態通知', () {
      test('VP設定でプロバイダーが通知されること', () async {
        // 初期化のために一度読み込む
        await container.read(vivaPointRepositoryProvider.future);

        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );
        var notificationCount = 0;

        container.listen<AsyncValue<int>>(
          vivaPointRepositoryProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        await notifier.setPoint(50);
        expect(notificationCount, equals(1));

        await notifier.setPoint(100);
        expect(notificationCount, equals(2));
      });

      test('リセットでプロバイダーが通知されること', () async {
        // 初期化のために一度読み込む
        await container.read(vivaPointRepositoryProvider.future);

        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );
        var notificationCount = 0;

        container.listen<AsyncValue<int>>(
          vivaPointRepositoryProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        await notifier.setPoint(100);
        await notifier.reset();
        expect(notificationCount, equals(2));
      });
    });
  });
}
