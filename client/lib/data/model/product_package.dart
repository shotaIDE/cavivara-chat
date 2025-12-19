import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

part 'product_package.freezed.dart';

/// 商品パッケージ情報(RevenueCatのPackageをラップ)
@freezed
abstract class ProductPackage with _$ProductPackage {
  const factory ProductPackage({
    required String identifier,
    required String title,
    required String description,
    required String priceString,
    required SupportPlan plan,
  }) = _ProductPackage;
}

extension ProductPackageGenerator on ProductPackage {
  static ProductPackage? fromPackage(Package package) {
    final supportPlan = SupportPlan.values.firstWhereOrNull(
      (plan) => plan.storeIdentifier == package.identifier,
    );
    if (supportPlan == null) {
      return null;
    }

    return ProductPackage(
      identifier: package.identifier,
      title: package.storeProduct.title,
      description: package.storeProduct.description,
      priceString: package.storeProduct.priceString,
      plan: supportPlan,
    );
  }
}
