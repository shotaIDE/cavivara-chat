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

    group('VPの加算', () {
      test('VPを加算できること (0 + 1 = 1)', () async {
        await container
            .read(vivaPointRepositoryProvider.notifier)
            .add(1);

        final vivaPoint = await container.read(
          vivaPointRepositoryProvider.future,
        );
        expect(vivaPoint, equals(1));
      });

      test('複数回加算した場合に累計が正しいこと (0 + 1 + 4 = 5)', () async {
        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );

        await notifier.add(1);
        await notifier.add(4);

        final vivaPoint = await container.read(
          vivaPointRepositoryProvider.future,
        );
        expect(vivaPoint, equals(5));
      });

      test('VPが加算されて永続化されること', () async {
        await container
            .read(vivaPointRepositoryProvider.notifier)
            .add(8);

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final vivaPoint = await newContainer.read(
          vivaPointRepositoryProvider.future,
        );

        expect(vivaPoint, equals(8));
      });

      test('既存のVPに加算されること (10 + 4 = 14)', () async {
        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );

        // まず10を加算
        await notifier.add(10);
        // さらに4を加算
        await notifier.add(4);

        final vivaPoint = await container.read(
          vivaPointRepositoryProvider.future,
        );
        expect(vivaPoint, equals(14));
      });
    });

    group('VPのリセット', () {
      test('リセット後に0になること', () async {
        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );

        await notifier.add(10);
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

        await notifier.add(10);
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
      test('VP加算でプロバイダーが通知されること', () async {
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

        await notifier.add(1);
        expect(notificationCount, equals(1));

        await notifier.add(4);
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

        await notifier.add(10);
        await notifier.reset();
        expect(notificationCount, equals(2));
      });
    });
  });
}
