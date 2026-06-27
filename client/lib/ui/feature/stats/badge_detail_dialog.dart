import 'package:flutter/material.dart';
import 'package:house_worker/data/model/earned_badge.dart';
import 'package:house_worker/ui/component/app_badge_extension.dart';

/// バッジ詳細ダイアログ
class BadgeDetailDialog extends StatelessWidget {
  const BadgeDetailDialog({
    required this.earnedBadge,
    super.key,
  });

  final EarnedBadge earnedBadge;

  /// ダイアログを表示
  static Future<void> show(
    BuildContext context, {
    required EarnedBadge earnedBadge,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => BadgeDetailDialog(earnedBadge: earnedBadge),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final badgeIcon = Icon(
      earnedBadge.badge.icon,
      size: 64,
      color: theme.colorScheme.primary,
    );

    final badgeTitle = Text(
      earnedBadge.badge.displayName,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );

    final description = Text(
      earnedBadge.badge.description,
      style: theme.textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );

    final earnedAt = earnedBadge.earnedAt;
    final dateLabel = Text(
      '獲得日: ${earnedAt.year}/${earnedAt.month.toString().padLeft(2, '0')}/${earnedAt.day.toString().padLeft(2, '0')}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );

    final closeButton = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('閉じる'),
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badgeIcon,
            const SizedBox(height: 16),
            badgeTitle,
            const SizedBox(height: 12),
            description,
            const SizedBox(height: 16),
            dateLabel,
            const SizedBox(height: 24),
            closeButton,
          ],
        ),
      ),
    );
  }
}
