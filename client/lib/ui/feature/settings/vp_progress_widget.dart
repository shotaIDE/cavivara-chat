import 'package:flutter/material.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';
import 'package:house_worker/ui/feature/settings/supporter_title_badge.dart';

/// VP進捗表示ウィジェット
class VPProgressWidget extends StatelessWidget {
  const VPProgressWidget({
    required this.currentVP,
    required this.currentTitle,
    required this.nextTitle,
    required this.vpToNext,
    required this.progress,
    super.key,
  });

  /// 累計VP
  final int currentVP;

  /// 現在の称号
  final SupporterTitle currentTitle;

  /// 次の称号（最上位の場合null）
  final SupporterTitle? nextTitle;

  /// 次の称号までに必要なVP数
  final int vpToNext;

  /// 次の称号までの進捗率（0.0-1.0）
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 累計VP表示
        Text(
          '累計: ${currentVP}VP',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // 現在の称号バッジ
        SupporterTitleBadge(
          title: currentTitle,
          showDescription: true,
        ),
        const SizedBox(height: 24),

        // 次の称号への進捗
        if (nextTitle != null) ...[
          // 次の称号までのメッセージ
          Text(
            '次の称号「${nextTitle!.displayName}」まであと${vpToNext}VP',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),

          // 進捗バー
          Semantics(
            label: '次の称号「${nextTitle!.displayName}」への進捗',
            value: '${(progress * 100).toInt()}%',
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(nextTitle!.color),
            ),
          ),
        ] else ...[
          // 最上位称号の場合
          Text(
            '最高称号獲得！',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: currentTitle.color,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: '最高称号の進捗',
            value: '${(progress * 100).toInt()}%',
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(currentTitle.color),
            ),
          ),
        ],
      ],
    );
  }
}
