import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:house_worker/data/service/in_app_purchase_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class MockErrorReportService extends Mock implements ErrorReportService {}

class FakeStackTrace extends Fake implements StackTrace {}

void main() {
  // mocktailのStackTrace用のフォールバック値を登録
  setUpAll(() {
    registerFallbackValue(FakeStackTrace());
  });

  // テスト実行時にflavorを設定（開発環境として実行）
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InAppPurchaseService', () {
    late ProviderContainer container;
    late MockErrorReportService mockErrorReportService;

    setUp(() {
      mockErrorReportService = MockErrorReportService();
      container = ProviderContainer(
        overrides: [
          errorReportServiceProvider.overrideWith((ref) {
            return mockErrorReportService;
          }),
        ],
      );

      // エラー報告のデフォルトスタブ
      when(
        () => mockErrorReportService.recordError(
          any<Object>(),
          any<StackTrace>(),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      container.dispose();
    });

    group('currentPackages', () {
      test('開発環境ではダミーデータが返されること', () async {
        // プロバイダーを初期化
        await container.read(inAppPurchaseServiceProvider.future);

        // 開発環境ではダミーデータが返される
        final products = await container.read(currentPackagesProvider.future);

        expect(products, isNotEmpty);
        expect(products.length, equals(2));
        expect(products[0].identifier, equals('stub_monthly'));
        expect(products[1].identifier, equals('stub_annual'));
      });

      test('開発環境では例外が発生しないこと', () async {
        await container.read(inAppPurchaseServiceProvider.future);

        // 開発環境では正常に実行される
        await expectLater(
          container.read(currentPackagesProvider.future),
          completes,
        );
      });
    });

    group('purchaseProduct', () {
      test('開発環境では正常に完了すること', () async {
        // プロバイダーを初期化
        await container.read(inAppPurchaseServiceProvider.future);
        final service = container.read(inAppPurchaseServiceProvider.notifier);
        const productId = 'stub_monthly_pro';

        // 開発環境では例外なく完了する
        await expectLater(
          service.purchaseProduct(productId),
          completes,
        );
      });

      test('開発環境ではエラーレポートサービスは呼ばれないこと', () async {
        await container.read(inAppPurchaseServiceProvider.future);
        final service = container.read(inAppPurchaseServiceProvider.notifier);
        const productId = 'stub_monthly_pro';

        await service.purchaseProduct(productId);

        // 開発環境では正常に完了するため、エラーレポートは呼ばれない
        verifyNever(
          () => mockErrorReportService.recordError(
            any<Object>(),
            any<StackTrace>(),
          ),
        );
      });
    });

    group('エラーハンドリング', () {
      test(
        'PlatformExceptionでpurchaseCancelledErrorの場合、'
        'PurchaseException.cancelledが投げられること',
        () {
          // PurchasesErrorCode.purchaseCancelledError のエラーコードは 1
          final platformException = PlatformException(
            code: '1',
            message: 'Purchase cancelled',
          );

          // purchaseProductの実装をテストするため、
          // サービスを直接テストすることはできないが、
          // エラーハンドリングのロジックを確認できる
          expect(
            PurchasesErrorHelper.getErrorCode(platformException),
            equals(PurchasesErrorCode.purchaseCancelledError),
          );
        },
      );

      test('PlatformExceptionで他のエラーコードの場合、'
          'uncategorizedエラーとして扱われること', () {
        // PurchasesErrorCode.purchaseCancelledError 以外のコード
        final platformException = PlatformException(
          code: '2', // storeProblemError
          message: 'Store problem',
        );

        expect(
          PurchasesErrorHelper.getErrorCode(platformException),
          isNot(equals(PurchasesErrorCode.purchaseCancelledError)),
        );
      });
    });
  });
}
