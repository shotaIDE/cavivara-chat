import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

part 'product_package.freezed.dart';

/// 商品パッケージ情報(RevenueCatのPackageをラップ)
@freezed
abstract class ProductPackage with _$ProductPackage {
  const factory ProductPackage({
    required String identifier,
    required String productId,
    required String title,
    required String description,
    required String priceString,
  }) = _ProductPackage;
}

extension ProductPackageGenerator on ProductPackage {
  static ProductPackage fromPackage(Package package) {
    return ProductPackage(
      identifier: package.identifier,
      productId: package.storeProduct.identifier,
      title: package.storeProduct.title,
      description: package.storeProduct.description,
      priceString: package.storeProduct.priceString,
    );
  }
}
