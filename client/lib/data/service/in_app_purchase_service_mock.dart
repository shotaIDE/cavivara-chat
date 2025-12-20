import 'package:house_worker/data/model/product_package.dart';
import 'package:house_worker/data/service/in_app_purchase_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

Future<List<ProductPackage>> currentPackagesMock(Ref ref) async {
  return [];
}

InAppPurchaseService inAppPurchaseServiceMock(Ref ref) {
  return const InAppPurchaseServiceMock();
}

class InAppPurchaseServiceMock implements InAppPurchaseService {
  const InAppPurchaseServiceMock();

  @override
  Future<void> purchaseProduct(ProductPackage product) async {}
}
