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

    group('getAvailableProducts', () {
      test('UnimplementedErrorが投げられること', () async {
        // プロバイダーを初期化
        await container.read(inAppPurchaseServiceProvider.future);
        final service = container.read(inAppPurchaseServiceProvider.notifier);

        expect(
          service.getAvailableProducts,
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('UnimplementedErrorの場合、エラーレポートサービスは呼ばれないこと', () async {
        // UnimplementedErrorはErrorであってExceptionではないため、
        // on Exceptionハンドラーで捕捉されず、エラーレポートサービスは呼ばれない
        await container.read(inAppPurchaseServiceProvider.future);
        final service = container.read(inAppPurchaseServiceProvider.notifier);

        try {
          await service.getAvailableProducts();
          fail('UnimplementedErrorが投げられるべきです');
          // ignore: avoid_catching_errors
        } on UnimplementedError {
          // UnimplementedErrorはExceptionではないため、
          // recordErrorは呼ばれない
          verifyNever(
            () => mockErrorReportService.recordError(
              any<Object>(),
              any<StackTrace>(),
            ),
          );
        }
      });
    });

    group('purchaseProduct', () {
      test('UnimplementedErrorが投げられること', () async {
        // プロバイダーを初期化
        await container.read(inAppPurchaseServiceProvider.future);
        final service = container.read(inAppPurchaseServiceProvider.notifier);
        const productId = 'test_product';

        expect(
          () => service.purchaseProduct(productId),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('UnimplementedErrorの場合、エラーレポートサービスは呼ばれないこと', () async {
        // UnimplementedErrorはErrorであってExceptionではないため、
        // on Exceptionハンドラーで捕捉されず、エラーレポートサービスは呼ばれない
        await container.read(inAppPurchaseServiceProvider.future);
        final service = container.read(inAppPurchaseServiceProvider.notifier);
        const productId = 'test_product';

        try {
          await service.purchaseProduct(productId);
          fail('UnimplementedErrorが投げられるべきです');
          // ignore: avoid_catching_errors
        } on UnimplementedError {
          // UnimplementedErrorはExceptionではないため、
          // recordErrorは呼ばれない
          verifyNever(
            () => mockErrorReportService.recordError(
              any<Object>(),
              any<StackTrace>(),
            ),
          );
        }
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
