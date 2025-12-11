import 'package:flutter/material.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/cavivara_avatar.dart';
import 'package:house_worker/ui/component/support_plan_extension.dart';
import 'package:house_worker/ui/feature/settings/supporter_title_badge.dart';

/// 応援感謝ダイアログ
class ThankYouDialog extends StatelessWidget {
  const ThankYouDialog({
    required this.plan,
    required this.earnedVP,
    required this.newTitle,
    super.key,
  });

  /// 応援プラン
  final SupportPlan plan;

  /// 獲得VP
  final int earnedVP;

  /// 新しい称号（昇格した場合のみ）
  final SupporterTitle? newTitle;

  /// ダイアログを表示
  static Future<void> show(
    BuildContext context, {
    required SupportPlan plan,
    required int earnedVP,
    SupporterTitle? newTitle,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ThankYouDialog(
        plan: plan,
        earnedVP: earnedVP,
        newTitle: newTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // カヴィヴァラのアバター
            const CavivaraAvatar(size: 80),
            const SizedBox(height: 16),

            // 感謝メッセージ
            Text(
              plan.thankYouMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 獲得VP表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+$earnedVP VP',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),

            // 称号昇格時の表示
            if (newTitle != null) ...[
              const SizedBox(height: 24),
              Text(
                'おめでとう！',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '新しい称号を獲得しました',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              SupporterTitleBadge(
                title: newTitle!,
              ),
            ],

            const SizedBox(height: 24),

            // 閉じるボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
