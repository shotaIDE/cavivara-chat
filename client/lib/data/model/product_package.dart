import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_package.freezed.dart';

/// 商品パッケージ情報(RevenueCatのPackageをラップ)
@freezed
abstract class ProductPackage with _$ProductPackage {
  const factory ProductPackage({
    required String identifier,
    required String productId,
    required String priceString,
  }) = _ProductPackage;
}
