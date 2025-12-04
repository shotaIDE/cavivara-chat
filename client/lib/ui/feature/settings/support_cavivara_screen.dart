import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/purchase_exception.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/ui/component/support_plan_extension.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_presenter.dart';
import 'package:house_worker/ui/feature/settings/support_plan_card.dart';
import 'package:house_worker/ui/feature/settings/thank_you_dialog.dart';
import 'package:house_worker/ui/feature/settings/vp_progress_widget.dart';

/// カヴィヴァラ応援画面
class SupportCavivaraScreen extends ConsumerWidget {
  const SupportCavivaraScreen({super.key});

  static const name = 'SupportCavivaraScreen';

  static MaterialPageRoute<SupportCavivaraScreen> route() =>
      MaterialPageRoute<SupportCavivaraScreen>(
        builder: (_) => const SupportCavivaraScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenter = ref.watch(supportCavivaraPresenterProvider.notifier);

    // VP情報を取得
    final totalVP = presenter.getTotalVP();
    final currentTitle = presenter.getCurrentTitle();
    final nextTitle = presenter.getNextTitle();
    final vpToNext = presenter.getVPToNextTitle();
    final progress = presenter.getProgressToNextTitle();

    return Scaffold(
      appBar: AppBar(
        title: const Text('カヴィヴァラを応援'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // VP進捗表示セクション
              VPProgressWidget(
                currentVP: totalVP,
                currentTitle: currentTitle,
                nextTitle: nextTitle,
                vpToNext: vpToNext,
                progress: progress,
              ),
              const SizedBox(height: 32),

              // 応援プラン選択セクション
              Text(
                '応援プランを選択',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 応援プランカード（small）
              SupportPlanCard(
                plan: SupportPlan.small,
                priceString: null, // TODO(claude): 商品情報から取得
                onTap: () => _onPlanTap(context, ref, SupportPlan.small),
              ),
              const SizedBox(height: 12),

              // 応援プランカード（medium）
              SupportPlanCard(
                plan: SupportPlan.medium,
                priceString: null, // TODO(claude): 商品情報から取得
                onTap: () => _onPlanTap(context, ref, SupportPlan.medium),
              ),
              const SizedBox(height: 12),

              // 応援プランカード（large）
              SupportPlanCard(
                plan: SupportPlan.large,
                priceString: null, // TODO(claude): 商品情報から取得
                onTap: () => _onPlanTap(context, ref, SupportPlan.large),
              ),
              const SizedBox(height: 24),

              // 区切り線
              const Divider(),
              const SizedBox(height: 16),

              // 注意書き
              Text(
                '※ 応援課金では機能は追加されません',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '※ カヴィヴァラさんの開発を応援するための課金です',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '※ 累計VPに応じて称号が変化します',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// プランタップ時の処理
  Future<void> _onPlanTap(
    BuildContext context,
    WidgetRef ref,
    SupportPlan plan,
  ) async {
    final presenter = ref.read(supportCavivaraPresenterProvider.notifier);

    // 購入前の称号を保存
    final oldTitle = presenter.getCurrentTitle();

    try {
      // 購入処理
      await presenter.supportCavivara(plan);

      // 購入後の称号
      final newTitle = presenter.getCurrentTitle();

      // 称号が変わった場合のみ新しい称号を渡す
      final promotedTitle = newTitle != oldTitle ? newTitle : null;

      // マウントチェック
      if (!context.mounted) {
        return;
      }

      // 感謝ダイアログ表示
      await ThankYouDialog.show(
        context,
        plan: plan,
        earnedVP: plan.vivaPoint,
        newTitle: promotedTitle,
      );
    } on PurchaseException catch (e) {
      // 購入キャンセルの場合は何もしない
      if (e is PurchaseExceptionCancelled) {
        return;
      }

      // その他のエラーの場合はスナックバーで通知
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('購入処理に失敗しました'),
        ),
      );
    }
  }
}
