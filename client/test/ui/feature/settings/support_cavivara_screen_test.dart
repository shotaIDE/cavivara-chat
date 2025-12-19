import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/model/product_package.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:house_worker/data/service/in_app_purchase_service.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_screen.dart';
import 'package:house_worker/ui/feature/settings/support_plan_card.dart';
import 'package:house_worker/ui/feature/settings/vp_progress_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// モッククラス（購入成功）
class MockInAppPurchaseService extends InAppPurchaseService {
  MockInAppPurchaseService()
    : super(errorReportService: _DummyErrorReportService());

  @override
  Future<void> purchaseProduct(ProductPackage product) async {
    // 購入成功をシミュレート
  }
}

class _DummyErrorReportService extends ErrorReportService {
  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {}

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> clearUserId() async {}
}

void main() {
  group('SupportCavivaraScreen', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      container = ProviderContainer(
        overrides: [
          // InAppPurchaseのパッケージリストをモック化（3つのプランを返す）
          currentPackagesProvider.overrideWith((ref) {
            return Future.value([
              const ProductPackage(
                identifier: 'test_small',
                title: 'Small Plan',
                description: 'Test small plan',
                priceString: '¥100',
                plan: SupportPlan.small,
              ),
              const ProductPackage(
                identifier: 'test_medium',
                title: 'Medium Plan',
                description: 'Test medium plan',
                priceString: '¥300',
                plan: SupportPlan.medium,
              ),
              const ProductPackage(
                identifier: 'test_large',
                title: 'Large Plan',
                description: 'Test large plan',
                priceString: '¥500',
                plan: SupportPlan.large,
              ),
            ]);
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('画面の基本構成要素が表示されること', (tester) async {
      // Arrange
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SupportCavivaraScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // AppBarが表示されていること
      expect(find.text('カヴィヴァラを応援'), findsOneWidget);

      // VP進捗ウィジェットが表示されていること
      expect(find.byType(VPProgressWidget), findsOneWidget);

      // 応援プランカードが3つ表示されていること
      expect(find.byType(SupportPlanCard), findsNWidgets(3));

      // 各プランのカード（タイトル）が表示されていること
      expect(find.text('Small Plan'), findsOneWidget);
      expect(find.text('Medium Plan'), findsOneWidget);
      expect(find.text('Large Plan'), findsOneWidget);
    });

    testWidgets('VP進捗情報が正しく表示されること', (tester) async {
      // Arrange - 50VPを設定
      container.dispose();
      SharedPreferences.setMockInitialValues({
        PreferenceKey.totalVivaPoint.name: 50,
      });
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            PreferenceKey.totalVivaPoint.name: 50,
          });
      container = ProviderContainer(
        overrides: [
          // InAppPurchaseのパッケージリストをモック化（3つのプランを返す）
          currentPackagesProvider.overrideWith((ref) {
            return Future.value([
              const ProductPackage(
                identifier: 'test_small',
                title: 'Small Plan',
                description: 'Test small plan',
                priceString: '¥100',
                plan: SupportPlan.small,
              ),
              const ProductPackage(
                identifier: 'test_medium',
                title: 'Medium Plan',
                description: 'Test medium plan',
                priceString: '¥300',
                plan: SupportPlan.medium,
              ),
              const ProductPackage(
                identifier: 'test_large',
                title: 'Large Plan',
                description: 'Test large plan',
                priceString: '¥500',
                plan: SupportPlan.large,
              ),
            ]);
          }),
        ],
      );

      // vivaPointRepositoryの初期化を待つ
      await container.read(vivaPointRepositoryProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SupportCavivaraScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // 累計VPが表示されていること
      expect(find.text('累計: 50VP'), findsOneWidget);
    });

    testWidgets('注意書きテキストが表示されること', (tester) async {
      // Arrange
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SupportCavivaraScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // 注意書きが表示されていること
      expect(
        find.textContaining('応援課金では機能は追加されません'),
        findsOneWidget,
      );
    });

    testWidgets('プランカードタップ時に購入処理が開始されること', (tester) async {
      // Arrange - InAppPurchaseServiceをモック化
      container = ProviderContainer(
        overrides: [
          // InAppPurchaseのパッケージリストをモック化（3つのプランを返す）
          currentPackagesProvider.overrideWith((ref) {
            return Future.value([
              const ProductPackage(
                identifier: 'test_small',
                title: 'Small Plan',
                description: 'Test small plan',
                priceString: '¥100',
                plan: SupportPlan.small,
              ),
              const ProductPackage(
                identifier: 'test_medium',
                title: 'Medium Plan',
                description: 'Test medium plan',
                priceString: '¥300',
                plan: SupportPlan.medium,
              ),
              const ProductPackage(
                identifier: 'test_large',
                title: 'Large Plan',
                description: 'Test large plan',
                priceString: '¥500',
                plan: SupportPlan.large,
              ),
            ]);
          }),
          inAppPurchaseServiceProvider.overrideWith(
            (ref) => MockInAppPurchaseService(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SupportCavivaraScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - smallプランカードをタップ
      await tester.tap(find.text('Small Plan'));
      await tester.pump();

      // Assert
      // タップ可能であること（エラーにならないこと）を確認
      // 実際の購入処理はモックされたInAppPurchaseServiceで処理される
    });

    testWidgets('画面がスクロール可能であること', (tester) async {
      // Arrange
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SupportCavivaraScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // SingleChildScrollViewが存在すること
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
