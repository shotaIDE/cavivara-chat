import 'package:flutter/services.dart';
import 'package:house_worker/data/model/product_package.dart';
import 'package:house_worker/data/model/purchase_exception.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:logging/logging.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_app_purchase_service.g.dart';

/// 現在のOfferingから利用可能なパッケージを取得するProvider
@riverpod
Future<List<ProductPackage>> currentPackages(Ref ref) async {
  final logger = Logger('InAppPurchaseService');
  final errorReportService = ref.read(errorReportServiceProvider);

  try {
    logger.info('Getting available products from RevenueCat');

    final offerings = await Purchases.getOfferings();
    final packages = offerings.current?.availablePackages ?? [];

    logger.info('Found ${packages.length} available products');

    final productPackages = packages
        .map((package) {
          final productPackage = ProductPackageGenerator.fromPackage(package);
          if (productPackage == null) {
            logger.severe('Found unknown package: ${package.identifier}');

            errorReportService.recordError(
              UnimplementedError(),
              StackTrace.current,
            );
          }

          return productPackage;
        })
        .whereType<ProductPackage>()
        .toList();

    logger.info('Found ${productPackages.length} valid products');

    return productPackages;
  } on Exception catch (e, stack) {
    logger.warning('Failed to get available products', e);
    final errorReportService = ref.read(errorReportServiceProvider);
    await errorReportService.recordError(e, stack);
    rethrow;
  }
}

@riverpod
InAppPurchaseService inAppPurchaseService(Ref ref) {
  return InAppPurchaseService(
    errorReportService: ref.watch(errorReportServiceProvider),
  );
}

class InAppPurchaseService {
  InAppPurchaseService({
    required ErrorReportService errorReportService,
  }) : _errorReportService = errorReportService;

  final ErrorReportService _errorReportService;
  final _logger = Logger('InAppPurchaseService');

  /// 商品IDを指定して購入
  Future<void> purchaseProduct(ProductPackage product) async {
    final identifier = product.identifier;
    _logger.info('Purchasing product: $identifier');

    try {
      // まず商品情報を取得
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];
      final package = packages.firstWhere(
        (p) => p.identifier == identifier,
        orElse: () => throw Exception('Product not found: $identifier'),
      );

      await Purchases.purchase(
        PurchaseParams.package(package),
      );
    } on PlatformException catch (e, stack) {
      // PlatformExceptionからエラーコードを取得
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      // ユーザーキャンセルは静かに処理
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        _logger.info('Purchase cancelled by user');
        throw const PurchaseException.cancelled();
      }

      // その他のエラーはエラーレポートに送信
      _logger.warning('Purchase failed with error code: $errorCode');
      await _errorReportService.recordError(e, stack);
      throw const PurchaseException.uncategorized();
    } on Exception catch (e, stack) {
      _logger.warning('Purchase failed', e);
      await _errorReportService.recordError(e, stack);
      throw const PurchaseException.uncategorized();
    }

    _logger.info('Purchase completed successfully: $identifier');
  }
}
