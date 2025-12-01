import 'package:house_worker/data/model/product_package.dart';
import 'package:house_worker/data/model/purchase_exception.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:house_worker/ui/component/support_plan_extension.dart';
import 'package:logging/logging.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_purchase_service.g.dart';

@riverpod
class InAppPurchaseService extends _$InAppPurchaseService {
  final _logger = Logger('InAppPurchaseService');

  @override
  Future<void> build() async {
    // TODO(implementation): RevenueCat SDKの初期化
    // RevenueCat APIキーはPhase 10で設定する
    // await Purchases.configure(
    //   PurchasesConfiguration('YOUR_API_KEY'),
    // );
  }

  /// 利用可能な商品を取得
  Future<List<ProductPackage>> getAvailableProducts() async {
    try {
      // TODO(implementation): RevenueCat SDKから商品情報を取得
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

      // TODO(implementation): RevenueCat SDKで購入処理
      // final customerInfo = await Purchases.purchaseStoreProduct(product);
      // await _completePurchase(customerInfo, productId);

      throw UnimplementedError('RevenueCat integration not yet implemented');
    } on PurchasesErrorCode catch (errorCode) {
      // ユーザーキャンセルは静かに処理
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        _logger.info('Purchase cancelled by user');
        return;
      }

      // その他のエラーはエラーレポートに送信
      _logger.warning('Purchase failed with error code: $errorCode');
      final errorReportService = ref.read(errorReportServiceProvider);
      await errorReportService.recordError(
        errorCode,
        StackTrace.current,
      );
      throw const PurchaseException();
    } on Exception catch (e, stack) {
      _logger.warning('Purchase failed', e);
      final errorReportService = ref.read(errorReportServiceProvider);
      await errorReportService.recordError(e, stack);
      throw const PurchaseException();
    }
  }

  /// RevenueCatのPackageを独自のProductPackageに変換
  ProductPackage _convertToProductPackage(Package package) {
    return ProductPackage(
      identifier: package.identifier,
      productId: package.storeProduct.identifier,
      priceString: package.storeProduct.priceString,
    );
  }

  /// 購入完了処理 (VP加算)
  Future<void> _completePurchase(
    CustomerInfo customerInfo,
    String productId,
  ) async {
    final plan = _getPlanFromProductId(productId);
    if (plan == null) {
      _logger.warning('Unknown product ID: $productId');
      return;
    }

    // VPを加算
    final vivaPoint = plan.vivaPoint;
    await ref.read(vivaPointRepositoryProvider.notifier).add(vivaPoint);

    _logger.info('Purchase completed: $productId, VP: $vivaPoint');
  }

  /// productIdからSupportPlanを取得
  SupportPlan? _getPlanFromProductId(String productId) {
    for (final plan in SupportPlan.values) {
      if (plan.productId == productId) {
        return plan;
      }
    }
    return null;
  }
}
