import 'package:flutter/material.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';

/// 称号とその説明を、美術館の作品キャプションのように中央に表示するウィジェット。
///
/// 業績画面と応援画面で共有する。
class SupporterTitleCaption extends StatelessWidget {
  const SupporterTitleCaption({
    required this.title,
    super.key,
  });

  /// 表示する称号
  final SupporterTitle title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = title.color;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 作品名（称号）
          Text(
            title.displayName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark
                  ? titleColor
                  : HSLColor.fromColor(titleColor).withLightness(0.3).toColor(),
            ),
          ),
          const SizedBox(height: 8),
          // 作品名と解説を区切る細い罫線
          Container(
            width: 32,
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 8),
          // 解説（称号の説明）
          Text(
            title.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
