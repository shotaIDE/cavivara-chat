import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/ui/component/heads_up_notification_presenter.dart';

class HeadsUpNotificationOverlay extends ConsumerWidget {
  const HeadsUpNotificationOverlay({
    super.key,
    required this.child,
  });

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
                  firstMessageBonus: (earnedVP, newTitleName) => Dismissible(
                    key: const ValueKey('firstMessageBonus'),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) =>
                        ref.read(headsUpNotificationProvider.notifier).hide(),
                    child: _FirstMessageBonusNotificationBody(
                      earnedVP: earnedVP,
                      newTitleName: newTitleName,
                    ),
                  ),
                  dailyLoginBonus: (earnedVP) => Dismissible(
                    key: const ValueKey('dailyLoginBonus'),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) =>
                        ref.read(headsUpNotificationProvider.notifier).hide(),
                    child: _DailyLoginBonusNotificationBody(
                      earnedVP: earnedVP,
                    ),
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

class _DailyLoginBonusNotificationBody extends StatelessWidget {
  const _DailyLoginBonusNotificationBody({
    required this.earnedVP,
  });

  final int earnedVP;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'ログインボーナス',
      style: Theme.of(context).textTheme.titleMedium,
    );

    final message = Text(
      '+$earnedVP VP を獲得しました！',
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
              Icons.card_giftcard,
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
