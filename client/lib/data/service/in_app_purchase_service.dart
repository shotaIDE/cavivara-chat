import 'package:flutter/services.dart';
import 'package:house_worker/data/model/product_package.dart';
import 'package:house_worker/data/model/purchase_exception.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:logging/logging.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_purchase_service.g.dart';

@riverpod
class InAppPurchaseService extends _$InAppPurchaseService {
  final _logger = Logger('InAppPurchaseService');

  @override
  Future<void> build() async {
    // TODO(claude): RevenueCat SDKの初期化
    // RevenueCat APIキーはPhase 10で設定する
    // await Purchases.configure(
    //   PurchasesConfiguration('YOUR_API_KEY'),
    // );
  }

  /// 利用可能な商品を取得
  Future<List<ProductPackage>> getAvailableProducts() async {
    try {
      // TODO(claude): RevenueCat SDKから商品情報を取得
      // final offerings = await Purchases.getOfferings();
      // final packages = offerings.current?.availablePackages ?? [];
      // return packages.map(_convertToProductPackage).toList();

      // 現時点ではダミーデータを返す
      _logger.info('Getting available products (stub implementation)');
      throw UnimplementedError('RevenueCat integration not yet implemented');
    } on Exception catch (e, stack) {
      _logger.warning('Failed to get available products', e);
      final errorReportService = ref.read(errorReportServiceProvider);
      await errorReportService.recordError(e, stack);
      rethrow;
    }
  }

  /// 商品IDを指定して購入
  Future<void> purchaseProduct(String productId) async {
    try {
      _logger.info('Purchasing product: $productId');

      // TODO(claude): RevenueCat SDKで購入処理
      // final customerInfo = await Purchases.purchaseStoreProduct(product);
      // await _completePurchase(customerInfo, productId);

      throw UnimplementedError('RevenueCat integration not yet implemented');
    } on PlatformException catch (e, stack) {
      // PlatformExceptionからエラーコードを取得
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      // ユーザーキャンセルは静かに処理
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        _logger.info('Purchase cancelled by user');
        return;
      }

      // その他のエラーはエラーレポートに送信
      _logger.warning('Purchase failed with error code: $errorCode');
      final errorReportService = ref.read(errorReportServiceProvider);
      await errorReportService.recordError(e, stack);
      throw const PurchaseException.uncategorized();
    } on Exception catch (e, stack) {
      _logger.warning('Purchase failed', e);
      final errorReportService = ref.read(errorReportServiceProvider);
      await errorReportService.recordError(e, stack);
      throw const PurchaseException.uncategorized();
    }
  }

  /// RevenueCatのPackageを独自のProductPackageに変換
  // ignore: unused_element
  ProductPackage _convertToProductPackage(Package package) {
    return ProductPackage(
      identifier: package.identifier,
      productId: package.storeProduct.identifier,
      priceString: package.storeProduct.priceString,
    );
  }

  /// 購入完了処理
  ///
  /// CustomerInfoを返すので、呼び出し側(Presenter)でVP加算などの
  /// ビジネスロジックを実行してください。
  // ignore: unused_element
  Future<CustomerInfo> _completePurchase(
    CustomerInfo customerInfo,
    String productId,
  ) async {
    _logger.info('Purchase completed: $productId');
    return customerInfo;
  }
}
