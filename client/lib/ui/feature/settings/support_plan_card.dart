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
    final label = '${plan.displayName}、$priceString、獲得${plan.vivaPoint}VP';

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
              spacing: 8,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      // 獲得VP
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  priceString,
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
