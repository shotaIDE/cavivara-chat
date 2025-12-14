import 'dart:io';

import 'package:flutter/services.dart';
import 'package:house_worker/data/definition/app_definition.dart';
import 'package:house_worker/data/definition/flavor.dart';
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

  try {
    if (flavor == Flavor.prod) {
      // Prod環境ではRevenueCat SDKから商品情報を取得
      logger.info('Getting available products from RevenueCat');

      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];

      logger.info('Found ${packages.length} available products');
      return packages.map(ProductPackageGenerator.fromPackage).toList();
    } else {
      // 開発環境ではダミーデータを返す
      logger.info('Getting available products (stub implementation)');
      return [
        const ProductPackage(
          identifier: 'stub_monthly',
          productId: 'stub_monthly_pro',
          priceString: '¥980',
        ),
        const ProductPackage(
          identifier: 'stub_annual',
          productId: 'stub_annual_pro',
          priceString: '¥9,800',
        ),
      ];
    }
  } on Exception catch (e, stack) {
    logger.warning('Failed to get available products', e);
    final errorReportService = ref.read(errorReportServiceProvider);
    await errorReportService.recordError(e, stack);
    rethrow;
  }
}

@riverpod
class InAppPurchaseService extends _$InAppPurchaseService {
  final _logger = Logger('InAppPurchaseService');

  @override
  Future<void> build() async {
    // Prod環境の場合のみRevenueCat SDKを初期化
    if (flavor == Flavor.prod) {
      _logger.info('Initializing RevenueCat SDK for production');

      // プラットフォームに応じたAPIキーを取得
      final apiKey = Platform.isIOS
          ? revenueCatProjectAppleApiKey
          : revenueCatProjectGoogleApiKey;

      if (apiKey.isEmpty) {
        _logger.severe('RevenueCat API key is not configured');
        throw StateError('RevenueCat API key is required in production');
      }

      await Purchases.configure(
        PurchasesConfiguration(apiKey),
      );

      _logger.info('RevenueCat SDK initialized successfully');
    } else {
      // 開発環境ではダミー実装を使用
      _logger.info('Using stub implementation for ${flavor.name} environment');
    }
  }

  /// 商品IDを指定して購入
  Future<void> purchaseProduct(String productId) async {
    try {
      _logger.info('Purchasing product: $productId');

      if (flavor == Flavor.prod) {
        // Prod環境ではRevenueCat SDKで購入処理を実行
        // まず商品情報を取得
        final offerings = await Purchases.getOfferings();
        final packages = offerings.current?.availablePackages ?? [];
        final package = packages.firstWhere(
          (p) => p.storeProduct.identifier == productId,
          orElse: () => throw Exception('Product not found: $productId'),
        );

        // 購入処理を実行
        final purchaseResult = await Purchases.purchase(
          PurchaseParams.package(package),
        );
        await _completePurchase(purchaseResult.customerInfo, productId);

        _logger.info('Purchase completed successfully: $productId');
      } else {
        // 開発環境ではダミー処理
        _logger.info('Purchase completed (stub implementation): $productId');
        // 開発環境では何もせず成功として扱う
      }
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

  /// 購入完了処理
  ///
  /// CustomerInfoを返すので、呼び出し側(Presenter)でVP加算などの
  /// ビジネスロジックを実行してください。
  Future<CustomerInfo> _completePurchase(
    CustomerInfo customerInfo,
    String productId,
  ) async {
    _logger.info('Purchase completed: $productId');
    return customerInfo;
  }
}
