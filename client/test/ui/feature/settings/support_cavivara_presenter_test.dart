import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/model/purchase_exception.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/data/repository/support_history_repository.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:house_worker/data/service/in_app_purchase_service.dart';
import 'package:house_worker/ui/component/support_plan_extension.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_presenter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('SupportCavivaraPresenter', () {
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

    group('getTotalVP', () {
      test('VivaPointRepositoryから累計VPを取得できること', () async {
        // Arrange
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 50,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 50,
            });
        container = ProviderContainer();

        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final totalVP = presenter.getTotalVP();

        // Assert
        expect(totalVP, 50);
      });

      test('0VPの場合も正しく取得できること', () async {
        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final totalVP = presenter.getTotalVP();

        // Assert
        expect(totalVP, 0);
      });
    });

    group('getCurrentTitle', () {
      test('現在の称号を取得できること', () async {
        // Arrange
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 50,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 50,
            });
        container = ProviderContainer();

        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final title = presenter.getCurrentTitle();

        // Assert
        expect(title, SupporterTitle.intermediate);
      });

      test('0VPの場合はnewbie称号が返ること', () async {
        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final title = presenter.getCurrentTitle();

        // Assert
        expect(title, SupporterTitle.newbie);
      });
    });

    group('getNextTitle', () {
      test('次の称号を取得できること', () async {
        // Arrange
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 50,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 50,
            });
        container = ProviderContainer();

        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final nextTitle = presenter.getNextTitle();

        // Assert
        expect(nextTitle, SupporterTitle.advanced);
      });

      test('最上位称号の場合はnullが返ること', () async {
        // Arrange
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 500,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 500,
            });
        container = ProviderContainer();

        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final nextTitle = presenter.getNextTitle();

        // Assert
        expect(nextTitle, null);
      });
    });

    group('getVPToNextTitle', () {
      test('次の称号までのVP数を取得できること', () async {
        // Arrange
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 50,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 50,
            });
        container = ProviderContainer();

        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final vpToNext = presenter.getVPToNextTitle();

        // Assert
        expect(vpToNext, 20); // 50VP (intermediate), 次はadvanced (70VP必要)
      });

      test('最上位称号の場合は0が返ること', () async {
        // Arrange
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 500,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 500,
            });
        container = ProviderContainer();

        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final vpToNext = presenter.getVPToNextTitle();

        // Assert
        expect(vpToNext, 0);
      });
    });

    group('getProgressToNextTitle', () {
      test('次の称号までの進捗率を0.0-1.0の範囲で取得できること', () async {
        // Arrange
        // 50VP (intermediate: 30-69), 次はadvanced (70VP必要)
        // 進捗 = (50 - 30) / (70 - 30) = 20 / 40 = 0.5
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 50,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 50,
            });
        container = ProviderContainer();

        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final progress = presenter.getProgressToNextTitle();

        // Assert
        expect(progress, closeTo(0.5, 0.01));
      });

      test('最上位称号の場合は1.0が返ること', () async {
        // Arrange
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 500,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 500,
            });
        container = ProviderContainer();

        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final progress = presenter.getProgressToNextTitle();

        // Assert
        expect(progress, 1.0);
      });

      test('称号の境界値では0.0が返ること', () async {
        // Arrange
        // 30VP (intermediateの開始位置)
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.totalVivaPoint.name: 30,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.totalVivaPoint.name: 30,
            });
        container = ProviderContainer();

        // vivaPointRepositoryの初期化を待つ
        await container.read(vivaPointRepositoryProvider.future);

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        final progress = presenter.getProgressToNextTitle();

        // Assert
        expect(progress, 0.0);
      });
    });

    group('supportCavivara', () {
      test('購入成功時にVPが加算され、履歴が記録されること', () async {
        // Arrange
        const plan = SupportPlan.medium;
        // InAppPurchaseServiceをモック化（購入成功）
        container = ProviderContainer(
          overrides: [
            inAppPurchaseServiceProvider.overrideWith(
              MockInAppPurchaseService.new,
            ),
          ],
        );

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        await presenter.supportCavivara(plan);

        // Assert
        // VP加算を確認
        final updatedPresenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        expect(updatedPresenter.getTotalVP(), plan.vivaPoint);

        // 履歴記録を確認
        final history = await container.read(
          supportHistoryRepositoryProvider.future,
        );
        expect(history, hasLength(1));
        expect(history.first.plan, plan);
        expect(history.first.earnedVP, plan.vivaPoint);
        expect(history.first.totalVPAfter, plan.vivaPoint);
      });

      test('購入キャンセル時はPurchaseException.cancelledが投げられること', () async {
        // Arrange
        const plan = SupportPlan.small;
        // InAppPurchaseServiceをモック化（購入キャンセル）
        container = ProviderContainer(
          overrides: [
            inAppPurchaseServiceProvider.overrideWith(
              MockInAppPurchaseServiceCancelled.new,
            ),
          ],
        );

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );

        // Assert
        await expectLater(
          presenter.supportCavivara(plan),
          throwsA(isA<PurchaseException>()),
        );

        // VPが加算されていないことを確認
        final updatedPresenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        expect(updatedPresenter.getTotalVP(), 0);

        // 履歴が記録されていないことを確認
        final history = await container.read(
          supportHistoryRepositoryProvider.future,
        );
        expect(history, isEmpty);
      });

      test('購入失敗時はPurchaseException.uncategorizedが投げられること', () async {
        // Arrange
        const plan = SupportPlan.large;
        // InAppPurchaseServiceをモック化（購入失敗）
        container = ProviderContainer(
          overrides: [
            inAppPurchaseServiceProvider.overrideWith(
              MockInAppPurchaseServiceUncategorized.new,
            ),
          ],
        );

        // Act
        final presenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );

        // Assert
        await expectLater(
          presenter.supportCavivara(plan),
          throwsA(isA<PurchaseException>()),
        );

        // VPが加算されていないことを確認
        final updatedPresenter = container.read(
          supportCavivaraPresenterProvider.notifier,
        );
        expect(updatedPresenter.getTotalVP(), 0);
      });
    });
  });
}

// モッククラス（購入成功）
class MockInAppPurchaseService extends InAppPurchaseService {
  @override
  Future<void> purchaseProduct(String productId) async {
    // 購入成功をシミュレート
  }
}

// モッククラス（購入キャンセル）
class MockInAppPurchaseServiceCancelled extends InAppPurchaseService {
  @override
  Future<void> purchaseProduct(String productId) async {
    throw const PurchaseException.cancelled();
  }
}

// モッククラス（購入失敗）
class MockInAppPurchaseServiceUncategorized extends InAppPurchaseService {
  @override
  Future<void> purchaseProduct(String productId) async {
    throw const PurchaseException.uncategorized();
  }
}
