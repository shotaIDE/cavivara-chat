import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/data/model/product_package.dart';
import 'package:house_worker/data/model/support_history.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/data/repository/support_history_repository.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:house_worker/data/service/in_app_purchase_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'support_cavivara_presenter.freezed.dart';
part 'support_cavivara_presenter.g.dart';

/// カヴィヴァラ応援画面のUIステート
@freezed
abstract class SupportCavivaraState with _$SupportCavivaraState {
  const factory SupportCavivaraState({
    /// 累計VP
    required int totalVP,

    /// 現在の称号
    required SupporterTitle currentTitle,

    /// 次の称号（最上位の場合はnull）
    required SupporterTitle? nextTitle,

    /// 次の称号までに必要なVP数
    required int vpToNextTitle,

    /// 次の称号までの進捗率（0.0 - 1.0）
    required double progressToNextTitle,

    required List<ProductPackage> packages,
  }) = _SupportCavivaraState;
}

/// カヴィヴァラ応援画面のPresenter
@riverpod
class SupportCavivaraPresenter extends _$SupportCavivaraPresenter {
  @override
  Future<SupportCavivaraState> build() async {
    // ref.watchを使用してVP変更を自動追跡
    final vivaPointState = ref.watch(vivaPointRepositoryProvider);
    final totalVP = vivaPointState.value ?? 0;

    // 商品情報を取得
    final packagesFuture = ref.watch(currentPackagesProvider.future);

    final currentTitle = SupporterTitleLogic.fromTotalVP(totalVP);
    final nextTitle = currentTitle.nextTitle;

    // 次の称号までに必要なVP数
    final vpToNextTitle = currentTitle.vpToNextTitle(totalVP);

    // 次の称号までの進捗率（0.0 - 1.0）
    final double progressToNextTitle;
    if (nextTitle == null) {
      // 最上位称号の場合
      progressToNextTitle = 1;
    } else {
      final currentTitleVP = currentTitle.requiredVP;
      final nextTitleVP = nextTitle.requiredVP;
      final vpRange = nextTitleVP - currentTitleVP;

      if (vpRange == 0) {
        progressToNextTitle = 0;
      } else {
        final progress = (totalVP - currentTitleVP) / vpRange;
        progressToNextTitle = progress.clamp(0.0, 1.0);
      }
    }

    // 商品パッケージを取得
    final packages = await packagesFuture;

    return SupportCavivaraState(
      totalVP: totalVP,
      currentTitle: currentTitle,
      nextTitle: nextTitle,
      vpToNextTitle: vpToNextTitle,
      progressToNextTitle: progressToNextTitle,
      packages: packages,
    );
  }

  /// カヴィヴァラを応援する（購入処理）
  Future<void> supportCavivara(ProductPackage product) async {
    // InAppPurchaseServiceで購入処理
    final inAppPurchaseService = ref.read(
      inAppPurchaseServiceProvider.notifier,
    );
    await inAppPurchaseService.purchaseProduct(product.productId);

    // 購入成功後、VPを加算
    final currentState = await future;
    final currentVP = currentState.totalVP;
    final newTotalVP = currentVP + product.plan.vivaPoint;
    final vivaPointRepository = ref.read(vivaPointRepositoryProvider.notifier);
    await vivaPointRepository.setPoint(newTotalVP);

    // 履歴を記録
    final supportHistory = SupportHistory(
      timestamp: DateTime.now(),
      plan: product.plan,
      earnedVP: product.plan.vivaPoint,
      totalVPAfter: newTotalVP,
    );

    final supportHistoryRepository = ref.read(
      supportHistoryRepositoryProvider.notifier,
    );
    await supportHistoryRepository.addHistory(supportHistory);

    // ref.watchを使用しているため、VPが更新されると自動的に状態が再構築される
  }
}
