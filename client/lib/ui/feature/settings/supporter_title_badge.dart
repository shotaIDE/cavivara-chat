import 'package:flutter/material.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';

/// 称号バッジウィジェット
class SupporterTitleBadge extends StatelessWidget {
  const SupporterTitleBadge({
    required this.title,
    this.showDescription = false,
    super.key,
  });

  /// 表示する称号
  final SupporterTitle title;

  /// 説明文の表示有無
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    // アクセシビリティラベルの構築
    final label = showDescription
        ? '${title.displayName}、${title.description}'
        : title.displayName;

    return Card(
      elevation: 2,
      child: Semantics(
        label: label,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // アイコン
              Icon(
                title.icon,
                size: 32,
                color: title.color,
              ),
              const SizedBox(width: 16),
              // テキスト部分
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 称号名
                    Text(
                      title.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: title.color,
                      ),
                    ),
                    // 説明文（条件付き表示）
                    if (showDescription) ...[
                      const SizedBox(height: 4),
                      Text(
                        title.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
