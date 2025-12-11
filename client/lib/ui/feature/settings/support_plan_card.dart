import 'package:flutter/material.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/ui/component/support_plan_extension.dart';

/// 応援プラン選択カード
class SupportPlanCard extends StatelessWidget {
  const SupportPlanCard({
    required this.plan,
    required this.priceString,
    required this.onTap,
    super.key,
  });

  /// 応援プラン
  final SupportPlan plan;

  /// 価格文字列（商品情報から取得した価格）
  final String? priceString;

  /// タップ時のコールバック
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        '${plan.displayName}、${priceString ?? '価格未設定'}、獲得${plan.vivaPoint}VP';

    return Card(
      elevation: 2,
      child: Semantics(
        label: label,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // アイコン
                Icon(
                  plan.icon,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                // テキスト部分
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // プラン名
                      Text(
                        plan.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      // 獲得VP
                      Text(
                        '+${plan.vivaPoint}VP',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // 価格
                Text(
                  priceString ?? '---',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
