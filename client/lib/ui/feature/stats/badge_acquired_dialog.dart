import 'package:flutter/material.dart';
import 'package:house_worker/data/model/earned_badge.dart';
import 'package:house_worker/ui/component/app_badge_extension.dart';
import 'package:house_worker/ui/component/app_badge_icon.dart';
import 'package:house_worker/ui/component/cavivara_entrance_animation.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';
import 'package:house_worker/ui/feature/stats/user_statistics_screen.dart';

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

    // 表示時に、拡大しながらふわっとフェードインさせる（業績画面の肖像画と同様）
    final badgeIcon = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: CavivaraEntranceAnimation.duration,
      curve: CavivaraEntranceAnimation.curve,
      child: AppBadgeIcon(
        badge: earnedBadge.badge,
        size: 88,
      ),
      builder: (context, value, child) {
        return Opacity(
          // easeOutBack は終盤で 1.0 を超えるため、不透明度は範囲内に収める
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.7 + 0.3 * value,
            child: child,
          ),
        );
      },
    );

    final congratsText = Text(
      'おめでとう！',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.tertiary,
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

    final badgeDescription = Text(
      earnedBadge.badge.description,
      style: theme.textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );

    final checkAllBadgesButton = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedbackHelper.lightImpact();
          Navigator.of(context)
            ..pop()
            ..push(UserStatisticsScreen.route());
        },
        child: const Text('業績を確認する'),
      ),
    );

    final closeButton = SizedBox(
      width: double.infinity,
      child: TextButton(
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
            const SizedBox(height: 8),
            badgeDescription,
            const SizedBox(height: 24),
            checkAllBadgesButton,
            const SizedBox(height: 8),
            closeButton,
          ],
        ),
      ),
    );
  }
}
