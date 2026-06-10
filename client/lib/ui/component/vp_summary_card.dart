import 'package:flutter/material.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';

/// 累計VPと次の称号までの進捗を表示するカード。
///
/// 業績画面と応援画面で共有する。
class VpSummaryCard extends StatelessWidget {
  const VpSummaryCard({
    required this.totalVP,
    required this.currentTitle,
    required this.nextTitle,
    required this.vpToNext,
    required this.progress,
    super.key,
  });

  /// 累計VP
  final int totalVP;

  /// 現在の称号
  final SupporterTitle currentTitle;

  /// 次の称号（最上位の場合 null）
  final SupporterTitle? nextTitle;

  /// 次の称号までに必要なVP数
  final int vpToNext;

  /// 次の称号までの進捗率（0.0〜1.0）
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = currentTitle.color;

    return Card(
      // 影を消してフラットにし、存在感を抑える
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 累計VP
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: titleColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$totalVP VP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // 次の称号への進捗。称号名は到達時の楽しみのため伏せる
            if (nextTitle != null) ...[
              const SizedBox(height: 16),
              Text(
                '次の称号まであと${vpToNext}VP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(titleColor),
                  // 称号名は伏せるため、進捗率のみ読み上げる。
                  // 進捗率は value から自動で読み上げられるため、
                  // semanticsValue（progressBar ロールでは数値が必須）は指定しない。
                  semanticsLabel: '次の称号への進捗',
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                '最高称号を獲得しました！',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
