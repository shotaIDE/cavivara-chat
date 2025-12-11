import 'package:house_worker/data/model/support_history.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/data/repository/support_history_repository.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:house_worker/data/service/in_app_purchase_service.dart';
import 'package:house_worker/ui/component/support_plan_extension.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'support_cavivara_presenter.g.dart';

/// カヴィヴァラ応援画面のPresenter
@riverpod
class SupportCavivaraPresenter extends _$SupportCavivaraPresenter {
  @override
  void build() {
    // 初期化不要
  }

  /// 累計VP取得
  int getTotalVP() {
    final vivaPointState = ref.read(vivaPointRepositoryProvider);
    return vivaPointState.value ?? 0;
  }

  /// 現在の称号取得
  SupporterTitle getCurrentTitle() {
    final totalVP = getTotalVP();
    return SupporterTitleLogic.fromTotalVP(totalVP);
  }

  /// 次の称号取得（最上位の場合はnull）
  SupporterTitle? getNextTitle() {
    final currentTitle = getCurrentTitle();
    return currentTitle.nextTitle;
  }

  /// 次の称号までに必要なVP数
  int getVPToNextTitle() {
    final totalVP = getTotalVP();
    final currentTitle = getCurrentTitle();
    return currentTitle.vpToNextTitle(totalVP);
  }

  /// 次の称号までの進捗率（0.0 - 1.0）
  double getProgressToNextTitle() {
    final currentTitle = getCurrentTitle();
    final nextTitle = getNextTitle();

    // 最上位称号の場合
    if (nextTitle == null) {
      return 1;
    }

    final totalVP = getTotalVP();
    final currentTitleVP = currentTitle.requiredVP;
    final nextTitleVP = nextTitle.requiredVP;
    final vpRange = nextTitleVP - currentTitleVP;

    if (vpRange == 0) {
      return 0;
    }

    final progress = (totalVP - currentTitleVP) / vpRange;
    return progress.clamp(0.0, 1.0);
  }

  /// カヴィヴァラを応援する（購入処理）
  Future<void> supportCavivara(SupportPlan plan) async {
    // InAppPurchaseServiceで購入処理
    final inAppPurchaseService = ref.read(
      inAppPurchaseServiceProvider.notifier,
    );
    await inAppPurchaseService.purchaseProduct(plan.productId);

    // 購入成功後、VPを加算
    final currentVP = getTotalVP();
    final newTotalVP = currentVP + plan.vivaPoint;
    final vivaPointRepository = ref.read(vivaPointRepositoryProvider.notifier);
    await vivaPointRepository.setPoint(newTotalVP);

    // 履歴を記録
    final supportHistory = SupportHistory(
      timestamp: DateTime.now(),
      plan: plan,
      earnedVP: plan.vivaPoint,
      totalVPAfter: newTotalVP,
    );

    final supportHistoryRepository = ref.read(
      supportHistoryRepositoryProvider.notifier,
    );
    await supportHistoryRepository.addHistory(supportHistory);

    // 状態を再読み込み
    ref.invalidateSelf();
  }
}
