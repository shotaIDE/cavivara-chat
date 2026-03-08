import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';
import 'package:house_worker/ui/component/heads_up_notification_presenter.dart';
import 'package:house_worker/ui/feature/stats/cavivara_reward.dart';

class HeadsUpNotificationOverlay extends ConsumerWidget {
  const HeadsUpNotificationOverlay({
    super.key,
    required this.onTapNotification,
    required this.child,
  });

  final void Function(CavivaraReward reward) onTapNotification;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(headsUpNotificationProvider);

    return Stack(
      children: [
        child ?? const SizedBox.shrink(),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            minimum: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                ),
                child: state.when(
                  hidden: () => const SizedBox.shrink(),
                  visible: (notification) => _HeadsUpNotificationBody(
                    reward: notification,
                    onTap: onTapNotification,
                  ),
                  firstMessageBonus: (earnedVP, newTitleName) =>
                      _FirstMessageBonusNotificationBody(
                        earnedVP: earnedVP,
                        newTitleName: newTitleName,
                      ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeadsUpNotificationBody extends StatelessWidget {
  const _HeadsUpNotificationBody({
    required this.reward,
    required this.onTap,
  });

  final CavivaraReward reward;
  final void Function(CavivaraReward reward) onTap;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      '称号を獲得しました',
      style: Theme.of(context).textTheme.titleMedium,
    );

    final message = Text(
      '${reward.displayName} を獲得しました',
      style: Theme.of(context).textTheme.bodyMedium,
    );

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () {
          HapticFeedbackHelper.lightImpact();
          onTap(reward);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.emoji_events,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    title,
                    message,
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

class _FirstMessageBonusNotificationBody extends StatelessWidget {
  const _FirstMessageBonusNotificationBody({
    required this.earnedVP,
    required this.newTitleName,
  });

  final int earnedVP;
  final String newTitleName;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      '称号を獲得しました',
      style: Theme.of(context).textTheme.titleMedium,
    );

    final message = Text(
      '+$earnedVP VP で $newTitleName になりました！',
      style: Theme.of(context).textTheme.bodyMedium,
    );

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.stars,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  title,
                  message,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
