import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/model/supporter_title.dart';
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

    group('称号算出ロジック', () {
      test('VP=0で駆け出しヴィヴァサポーターになること', () {
        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );
        final title = notifier.getCurrentTitle(0);
        expect(title, equals(SupporterTitle.newbie));
      });

      test('VP=10で初心ヴィヴァサポーターになること', () {
        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );
        final title = notifier.getCurrentTitle(10);
        expect(title, equals(SupporterTitle.beginner));
      });

      test('VP=500以上で伝説のヴィヴァサポーターになること', () {
        final notifier = container.read(
          vivaPointRepositoryProvider.notifier,
        );
        final title = notifier.getCurrentTitle(500);
        expect(title, equals(SupporterTitle.legend));

        final title1000 = notifier.getCurrentTitle(1000);
        expect(title1000, equals(SupporterTitle.legend));
      });

      group('境界値テスト', () {
        test('VP=9で駆け出しヴィヴァサポーターになること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final title = notifier.getCurrentTitle(9);
          expect(title, equals(SupporterTitle.newbie));
        });

        test('VP=29で初心ヴィヴァサポーターになること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final title = notifier.getCurrentTitle(29);
          expect(title, equals(SupporterTitle.beginner));
        });

        test('VP=30で一人前ヴィヴァサポーターになること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final title = notifier.getCurrentTitle(30);
          expect(title, equals(SupporterTitle.intermediate));
        });

        test('VP=69で一人前ヴィヴァサポーターになること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final title = notifier.getCurrentTitle(69);
          expect(title, equals(SupporterTitle.intermediate));
        });

        test('VP=70でベテランヴィヴァサポーターになること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final title = notifier.getCurrentTitle(70);
          expect(title, equals(SupporterTitle.advanced));
        });

        test('VP=149でベテランヴィヴァサポーターになること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final title = notifier.getCurrentTitle(149);
          expect(title, equals(SupporterTitle.advanced));
        });

        test('VP=150で熟練ヴィヴァサポーターになること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final title = notifier.getCurrentTitle(150);
          expect(title, equals(SupporterTitle.expert));
        });

        test('VP=299で熟練ヴィヴァサポーターになること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final title = notifier.getCurrentTitle(299);
          expect(title, equals(SupporterTitle.expert));
        });

        test('VP=300で達人ヴィヴァサポーターになること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final title = notifier.getCurrentTitle(300);
          expect(title, equals(SupporterTitle.master));
        });

        test('VP=499で達人ヴィヴァサポーターになること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final title = notifier.getCurrentTitle(499);
          expect(title, equals(SupporterTitle.master));
        });
      });

      group('次の称号の取得', () {
        test('駆け出しヴィヴァサポーターの次は初心ヴィヴァサポーターであること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final nextTitle = notifier.getNextTitle(0);
          expect(nextTitle, equals(SupporterTitle.beginner));
        });

        test('達人ヴィヴァサポーターの次は伝説のヴィヴァサポーターであること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final nextTitle = notifier.getNextTitle(300);
          expect(nextTitle, equals(SupporterTitle.legend));
        });

        test('伝説のヴィヴァサポーターの次はnullであること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final nextTitle = notifier.getNextTitle(500);
          expect(nextTitle, isNull);
        });
      });

      group('次の称号までに必要なVP数の取得', () {
        test('VP=0の場合、次の称号まであと10VPであること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final vpToNext = notifier.getVPToNextTitle(0);
          expect(vpToNext, equals(10));
        });

        test('VP=5の場合、次の称号まであと5VPであること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final vpToNext = notifier.getVPToNextTitle(5);
          expect(vpToNext, equals(5));
        });

        test('VP=25の場合、次の称号まであと5VPであること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final vpToNext = notifier.getVPToNextTitle(25);
          expect(vpToNext, equals(5));
        });

        test('VP=499の場合、次の称号まであと1VPであること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final vpToNext = notifier.getVPToNextTitle(499);
          expect(vpToNext, equals(1));
        });

        test('VP=500の場合（最上位称号）、次の称号まで0VPであること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final vpToNext = notifier.getVPToNextTitle(500);
          expect(vpToNext, equals(0));
        });

        test('VP=1000の場合（最上位称号）、次の称号まで0VPであること', () {
          final notifier = container.read(
            vivaPointRepositoryProvider.notifier,
          );
          final vpToNext = notifier.getVPToNextTitle(1000);
          expect(vpToNext, equals(0));
        });
      });
    });
  });
}
