import 'package:flutter/material.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/ui/component/support_plan_extension.dart';

/// 応援プラン選択カード
class SupportPlanCard extends StatelessWidget {
  const SupportPlanCard({
    required this.plan,
    required this.title,
    required this.description,
    required this.priceString,
    required this.onTap,
    super.key,
  });

  final SupportPlan plan;
  final String title;
  final String description;
  final String priceString;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = '${plan.displayName}、$priceString、獲得${plan.vivaPoint}VP';

    // トーク画面のアクションボタンと同様に、目立つ背景色で購入を促す
    return Card(
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHigh,
      child: Semantics(
        label: label,
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 獲得VP
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  priceString,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
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
