import 'package:flutter/material.dart';
import 'package:house_worker/data/model/app_badge.dart';
import 'package:house_worker/ui/component/app_badge_extension.dart';
import 'package:house_worker/ui/component/app_badge_icon.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';
import 'package:house_worker/ui/feature/stats/user_statistics_screen.dart';

/// バッジ獲得を全画面で祝福する画面。
class BadgeAcquiredScreen extends StatelessWidget {
  const BadgeAcquiredScreen({
    required this.badge,
    required this.earnedVP,
    super.key,
  });

  /// 獲得したバッジ。
  final AppBadge badge;

  /// 獲得したVP。
  final int earnedVP;

  static const name = 'BadgeAcquiredScreen';

  static MaterialPageRoute<BadgeAcquiredScreen> route({
    required AppBadge badge,
    required int earnedVP,
  }) => MaterialPageRoute<BadgeAcquiredScreen>(
    builder: (_) => BadgeAcquiredScreen(badge: badge, earnedVP: earnedVP),
    settings: const RouteSettings(name: name),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final badgeIcon = AppBadgeIcon(
      badge: badge,
      size: 160,
    );

    final congratsText = Text(
      'おめでとう！',
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.tertiary,
      ),
    );

    final description = Text(
      'バッジを獲得しました',
      style: theme.textTheme.titleMedium,
    );

    final badgeTitle = Text(
      badge.displayName,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );

    final badgeDescription = Text(
      badge.description,
      style: theme.textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );

    final earnedVPText = Text(
      '+$earnedVP VP を獲得しました！',
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
      textAlign: TextAlign.center,
    );

    final checkAchievementButton = SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          HapticFeedbackHelper.lightImpact();
          Navigator.of(context).pushAndRemoveUntil(
            UserStatisticsScreen.route(),
            (route) => false,
          );
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24 + MediaQuery.of(context).viewPadding.left,
              right: 24 + MediaQuery.of(context).viewPadding.right,
              top: 24,
              bottom: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                badgeIcon,
                const SizedBox(height: 24),
                congratsText,
                const SizedBox(height: 8),
                description,
                const SizedBox(height: 24),
                badgeTitle,
                const SizedBox(height: 12),
                badgeDescription,
                const SizedBox(height: 24),
                earnedVPText,
                const SizedBox(height: 40),
                checkAchievementButton,
                const SizedBox(height: 8),
                closeButton,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
