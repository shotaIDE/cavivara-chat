import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/product_package.dart';
import 'package:house_worker/data/model/purchase_exception.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_presenter.dart';
import 'package:house_worker/ui/feature/settings/support_plan_card.dart';
import 'package:house_worker/ui/feature/settings/thank_you_dialog.dart';
import 'package:house_worker/ui/feature/settings/vp_progress_widget.dart';

/// カヴィヴァラ応援画面
class SupportCavivaraScreen extends ConsumerStatefulWidget {
  const SupportCavivaraScreen({super.key});

  static const name = 'SupportCavivaraScreen';

  static MaterialPageRoute<SupportCavivaraScreen> route() =>
      MaterialPageRoute<SupportCavivaraScreen>(
        builder: (_) => const SupportCavivaraScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<SupportCavivaraScreen> createState() =>
      _SupportCavivaraScreenState();
}

class _SupportCavivaraScreenState extends ConsumerState<SupportCavivaraScreen> {
  @override
  Widget build(BuildContext context) {
    final presenterState = ref.watch(supportCavivaraPresenterProvider);

    return presenterState.when(
      data: (state) => Scaffold(
        appBar: AppBar(
          title: const Text('カヴィヴァラを応援'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16 + MediaQuery.of(context).viewPadding.left,
              top: 16,
              right: 16 + MediaQuery.of(context).viewPadding.right,
              bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // VP進捗表示セクション
                VPProgressWidget(
                  currentVP: state.totalVP,
                  currentTitle: state.currentTitle,
                  nextTitle: state.nextTitle,
                  vpToNext: state.vpToNextTitle,
                  progress: state.progressToNextTitle,
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

                ...state.packages.map((package) {
                  return SupportPlanCard(
                    plan: package.plan,
                    title: package.title,
                    description: package.description,
                    priceString: package.priceString,
                    onTap: () => _onPlanTap(package),
                  );
                }),

                const SizedBox(height: 12),

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
      ),
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('カヴィヴァラを応援'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('カヴィヴァラを応援'),
        ),
        body: Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }

  /// プランタップ時の処理
  Future<void> _onPlanTap(ProductPackage product) async {
    final presenter = ref.read(supportCavivaraPresenterProvider.notifier);

    // 購入前の称号を保存
    final oldState = await ref.read(supportCavivaraPresenterProvider.future);
    final oldTitle = oldState.currentTitle;

    // 購入処理
    try {
      await presenter.supportCavivara(product);
    } on PurchaseException catch (e) {
      // 購入キャンセルの場合は何もしない
      if (e is PurchaseExceptionCancelled) {
        return;
      }

      // その他のエラーの場合はスナックバーで通知
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('購入処理に失敗しました'),
        ),
      );
      return;
    }

    // 購入後の称号
    final newState = await ref.read(supportCavivaraPresenterProvider.future);
    final newTitle = newState.currentTitle;

    // 称号が変わった場合のみ新しい称号を渡す
    final promotedTitle = newTitle != oldTitle ? newTitle : null;

    // マウントチェック
    if (!mounted) {
      return;
    }

    // 感謝ダイアログ表示
    await ThankYouDialog.show(
      context,
      plan: product.plan,
      earnedVP: product.plan.vivaPoint,
      newTitle: promotedTitle,
    );
  }
}
