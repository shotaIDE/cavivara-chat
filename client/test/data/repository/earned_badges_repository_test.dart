import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/app_badge.dart';
import 'package:house_worker/data/model/earned_badge.dart';
import 'package:house_worker/data/repository/earned_badges_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('EarnedBadgesRepository', () {
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
      test('初回起動時は空リストを返すこと', () async {
        final badges = await container.read(
          earnedBadgesRepositoryProvider.future,
        );

        expect(badges, isEmpty);
      });
    });

    group('バッジの追加', () {
      test('バッジを追加できること', () async {
        final notifier = container.read(
          earnedBadgesRepositoryProvider.notifier,
        );

        final badge = EarnedBadge(
          badge: AppBadge.firstLaunch,
          earnedAt: DateTime(2026, 6, 27, 12),
        );

        await notifier.add(badge);

        final badges = await container.read(
          earnedBadgesRepositoryProvider.future,
        );

        expect(badges.length, 1);
        expect(badges.first.badge, AppBadge.firstLaunch);
      });

      test('追加したバッジが永続化されること', () async {
        final notifier = container.read(
          earnedBadgesRepositoryProvider.notifier,
        );

        final badge = EarnedBadge(
          badge: AppBadge.firstLaunch,
          earnedAt: DateTime(2026, 6, 27, 12),
        );

        await notifier.add(badge);

        // 新しいコンテナで再読み込みして永続化を確認
        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);

        final reloadedBadges = await newContainer.read(
          earnedBadgesRepositoryProvider.future,
        );

        expect(reloadedBadges.length, 1);
        expect(reloadedBadges.first.badge, AppBadge.firstLaunch);
      });

      test('新しいバッジが先頭に追加されること', () async {
        final notifier = container.read(
          earnedBadgesRepositoryProvider.notifier,
        );

        final badge1 = EarnedBadge(
          badge: AppBadge.firstLaunch,
          earnedAt: DateTime(2026, 6, 27, 10),
        );

        final badge2 = EarnedBadge(
          badge: AppBadge.firstLaunch,
          earnedAt: DateTime(2026, 6, 27, 12),
        );

        await notifier.add(badge1);
        await notifier.add(badge2);

        final badges = await container.read(
          earnedBadgesRepositoryProvider.future,
        );

        expect(badges.length, 2);
        // 最新が先頭
        expect(badges.first.earnedAt, DateTime(2026, 6, 27, 12));
        expect(badges.last.earnedAt, DateTime(2026, 6, 27, 10));
      });
    });
  });
}
