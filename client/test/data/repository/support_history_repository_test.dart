import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/support_history.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/data/repository/support_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('SupportHistoryRepository', () {
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
        final histories = await container.read(
          supportHistoryRepositoryProvider.future,
        );

        expect(histories, isEmpty);
      });
    });

    group('履歴の追加', () {
      test('履歴を追加できること', () async {
        final notifier = container.read(
          supportHistoryRepositoryProvider.notifier,
        );

        final history = SupportHistory(
          timestamp: DateTime(2024, 1, 1, 12),
          plan: SupportPlan.small,
          earnedVP: 1,
          totalVPAfter: 1,
        );

        await notifier.addHistory(history);

        final histories = await container.read(
          supportHistoryRepositoryProvider.future,
        );

        expect(histories.length, 1);
        expect(histories.first.plan, SupportPlan.small);
        expect(histories.first.earnedVP, 1);
        expect(histories.first.totalVPAfter, 1);
      });

      test('複数の履歴を追加できること', () async {
        final notifier = container.read(
          supportHistoryRepositoryProvider.notifier,
        );

        final history1 = SupportHistory(
          timestamp: DateTime(2024, 1, 1, 12),
          plan: SupportPlan.small,
          earnedVP: 1,
          totalVPAfter: 1,
        );

        final history2 = SupportHistory(
          timestamp: DateTime(2024, 1, 2, 12),
          plan: SupportPlan.medium,
          earnedVP: 4,
          totalVPAfter: 5,
        );

        await notifier.addHistory(history1);
        await notifier.addHistory(history2);

        final histories = await container.read(
          supportHistoryRepositoryProvider.future,
        );

        expect(histories.length, 2);
      });

      test('履歴は時系列順（最新が先頭）に保存されること', () async {
        final notifier = container.read(
          supportHistoryRepositoryProvider.notifier,
        );

        final history1 = SupportHistory(
          timestamp: DateTime(2024, 1, 1, 12),
          plan: SupportPlan.small,
          earnedVP: 1,
          totalVPAfter: 1,
        );

        final history2 = SupportHistory(
          timestamp: DateTime(2024, 1, 2, 12),
          plan: SupportPlan.medium,
          earnedVP: 4,
          totalVPAfter: 5,
        );

        await notifier.addHistory(history1);
        await notifier.addHistory(history2);

        final histories = await container.read(
          supportHistoryRepositoryProvider.future,
        );

        // 最新が先頭
        expect(histories.first.timestamp, DateTime(2024, 1, 2, 12));
        expect(histories.last.timestamp, DateTime(2024, 1, 1, 12));
      });

      test('履歴が永続化されること', () async {
        final notifier = container.read(
          supportHistoryRepositoryProvider.notifier,
        );

        final history = SupportHistory(
          timestamp: DateTime(2024, 1, 1, 12),
          plan: SupportPlan.large,
          earnedVP: 8,
          totalVPAfter: 8,
        );

        await notifier.addHistory(history);

        // 新しいコンテナで読み込み
        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);

        final histories = await newContainer.read(
          supportHistoryRepositoryProvider.future,
        );

        expect(histories.length, 1);
        expect(histories.first.plan, SupportPlan.large);
      });
    });

    group('履歴のクリア', () {
      test('クリア処理が正しく動作すること', () async {
        final notifier = container.read(
          supportHistoryRepositoryProvider.notifier,
        );

        final history = SupportHistory(
          timestamp: DateTime(2024, 1, 1, 12),
          plan: SupportPlan.small,
          earnedVP: 1,
          totalVPAfter: 1,
        );

        await notifier.addHistory(history);
        await notifier.clear();

        final histories = await container.read(
          supportHistoryRepositoryProvider.future,
        );

        expect(histories, isEmpty);
      });

      test('クリアが永続化されること', () async {
        final notifier = container.read(
          supportHistoryRepositoryProvider.notifier,
        );

        final history = SupportHistory(
          timestamp: DateTime(2024, 1, 1, 12),
          plan: SupportPlan.small,
          earnedVP: 1,
          totalVPAfter: 1,
        );

        await notifier.addHistory(history);
        await notifier.clear();

        // 新しいコンテナで読み込み
        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);

        final histories = await newContainer.read(
          supportHistoryRepositoryProvider.future,
        );

        expect(histories, isEmpty);
      });
    });

    group('状態通知', () {
      test('履歴追加でプロバイダーが通知されること', () async {
        // 初期化のために一度読み込む
        await container.read(supportHistoryRepositoryProvider.future);

        final notifier = container.read(
          supportHistoryRepositoryProvider.notifier,
        );
        var notificationCount = 0;

        container.listen<AsyncValue<List<SupportHistory>>>(
          supportHistoryRepositoryProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        final history = SupportHistory(
          timestamp: DateTime(2024, 1, 1, 12),
          plan: SupportPlan.small,
          earnedVP: 1,
          totalVPAfter: 1,
        );

        await notifier.addHistory(history);
        expect(notificationCount, equals(1));
      });

      test('クリアでプロバイダーが通知されること', () async {
        // 初期化のために一度読み込む
        await container.read(supportHistoryRepositoryProvider.future);

        final notifier = container.read(
          supportHistoryRepositoryProvider.notifier,
        );

        final history = SupportHistory(
          timestamp: DateTime(2024, 1, 1, 12),
          plan: SupportPlan.small,
          earnedVP: 1,
          totalVPAfter: 1,
        );

        await notifier.addHistory(history);

        var notificationCount = 0;
        container.listen<AsyncValue<List<SupportHistory>>>(
          supportHistoryRepositoryProvider,
          (previous, next) {
            notificationCount++;
          },
        );

        await notifier.clear();
        expect(notificationCount, equals(1));
      });
    });
  });
}
