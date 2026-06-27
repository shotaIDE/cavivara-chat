import 'package:flutter/material.dart';
import 'package:house_worker/data/model/earned_badge.dart';
import 'package:house_worker/ui/component/app_badge_extension.dart';

/// バッジ獲得ダイアログ
class BadgeAcquiredDialog extends StatelessWidget {
  const BadgeAcquiredDialog({
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
      builder: (_) => BadgeAcquiredDialog(earnedBadge: earnedBadge),
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

    final congratsText = Text(
      'おめでとう！',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.orange,
      ),
    );

    final description = Text(
      'バッジを獲得しました',
      style: theme.textTheme.bodyMedium,
    );

    final badgeTitle = Text(
      earnedBadge.badge.displayName,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
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
            congratsText,
            const SizedBox(height: 8),
            description,
            const SizedBox(height: 12),
            badgeTitle,
            const SizedBox(height: 24),
            closeButton,
          ],
        ),
      ),
    );
  }
}
