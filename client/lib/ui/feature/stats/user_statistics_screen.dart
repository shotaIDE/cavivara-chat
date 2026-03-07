import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/repository/received_chat_string_count_repository.dart';
import 'package:house_worker/data/repository/resume_viewing_duration_repository.dart';
import 'package:house_worker/data/repository/sent_chat_string_count_repository.dart';
import 'package:house_worker/data/service/employment_state_service.dart';
import 'package:house_worker/ui/component/app_drawer.dart';
import 'package:house_worker/ui/feature/home/home_screen.dart';
import 'package:house_worker/ui/feature/job_market/job_market_screen.dart';
import 'package:house_worker/ui/feature/settings/settings_screen.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_presenter.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_screen.dart';
import 'package:house_worker/ui/feature/settings/supporter_title_badge.dart';
import 'package:house_worker/ui/feature/stats/cavivara_reward.dart';

class UserStatisticsScreen extends ConsumerWidget {
  const UserStatisticsScreen({
    super.key,
    this.highlightedReward,
  });

  static const name = 'UserStatisticsScreen';

  final CavivaraReward? highlightedReward;

  static MaterialPageRoute<UserStatisticsScreen> route({
    CavivaraReward? highlightedReward,
  }) => MaterialPageRoute<UserStatisticsScreen>(
    builder: (_) => UserStatisticsScreen(
      highlightedReward: highlightedReward,
    ),
    settings: const RouteSettings(name: name),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employmentState = ref.watch(employmentStateProvider);
    final defaultCavivaraId = employmentState.isNotEmpty
        ? employmentState.first
        : HomeScreen.defaultCavivaraId;
    final sentCount = ref.watch(sentChatStringCountRepositoryProvider);
    final receivedCount = ref.watch(receivedChatStringCountRepositoryProvider);
    final resumeDuration = ref.watch(resumeViewingDurationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('あなたの業績'),
      ),
      drawer: AppDrawer(
        isTalkSelected: false,
        isJobMarketSelected: false,
        isAchievementSelected: true,
        onSelectTalk: () {
          Navigator.of(context).pushAndRemoveUntil(
            HomeScreen.route(defaultCavivaraId),
            (route) => false,
          );
        },
        onSelectJobMarket: () {
          Navigator.of(context).pushAndRemoveUntil(
            JobMarketScreen.route(),
            (route) => false,
          );
        },
        onSelectAchievement: () {
          Navigator.of(context).pop();
        },
        onSelectSettings: () {
          Navigator.of(context).push(SettingsScreen.route());
        },
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 16 + MediaQuery.of(context).viewPadding.left,
          right: 16 + MediaQuery.of(context).viewPadding.right,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: _buildStatisticsContent(
          context,
          ref,
          sentCount,
          receivedCount,
          resumeDuration,
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<int> sentCount,
    AsyncValue<int> receivedCount,
    AsyncValue<Duration> resumeDuration,
  ) {
    // すべてのデータが読み込まれているかチェック
    if (sentCount.isLoading ||
        receivedCount.isLoading ||
        resumeDuration.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // エラーがあるかチェック
    if (sentCount.hasError ||
        receivedCount.hasError ||
        resumeDuration.hasError) {
      return Center(
        child: Text(
          'データの取得に失敗しました',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final sent = sentCount.value ?? 0;
    final received = receivedCount.value ?? 0;
    final duration = resumeDuration.value ?? Duration.zero;
    final theme = Theme.of(context);

    // サポーター情報を取得
    final supporterState = ref.watch(supportCavivaraPresenterProvider);

    return ListView(
      children: [
        // 累計VPとサポーター称号セクション
        _buildSupporterSection(context, supporterState),
        const SizedBox(height: 32),
        _StatisticsTile(
          title: 'チャットを送信した文字数',
          value: '$sent文字',
          icon: Icons.outgoing_mail,
        ),
        const SizedBox(height: 16),
        _StatisticsTile(
          title: 'カヴィヴァラさんたちから受信したチャットの文字数',
          value: '$received文字',
          icon: Icons.inbox,
        ),
        const SizedBox(height: 16),
        _StatisticsTile(
          title: 'カヴィヴァラさんの履歴書を眺めていた時間',
          value: _formatDuration(duration),
          icon: Icons.schedule,
        ),
        const SizedBox(height: 32),
        Text(
          '称号',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final reward in CavivaraReward.values) ...[
          _RewardTile(
            cavivaraReward: reward,
            isHighlighted: highlightedReward == reward,
            receivedStringCount: received,
          ),
          if (reward != CavivaraReward.values.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildSupporterSection(
    BuildContext context,
    AsyncValue<SupportCavivaraState> supporterState,
  ) {
    final theme = Theme.of(context);

    return supporterState.when(
      data: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 累計VP表示
          Text(
            '累計: ${state.totalVP}VP',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 現在の称号バッジ
          SupporterTitleBadge(
            title: state.currentTitle,
            showDescription: true,
          ),
          const SizedBox(height: 16),

          // 応援画面へのナビゲーションボタン
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(SupportCavivaraScreen.route());
              },
              icon: const Icon(Icons.favorite),
              label: const Text('カヴィヴァラを応援する'),
            ),
          ),
        ],
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration <= Duration.zero) {
      return '0秒';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final buffer = <String>[];

    if (hours > 0) {
      buffer.add('$hours時間');
    }
    if (minutes > 0) {
      buffer.add('$minutes分');
    }
    if (seconds > 0 || buffer.isEmpty) {
      buffer.add('$seconds秒');
    }

    return buffer.join();
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.cavivaraReward,
    required this.isHighlighted,
    required this.receivedStringCount,
  });

  final CavivaraReward cavivaraReward;
  final bool isHighlighted;
  final int receivedStringCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAchieved = cavivaraReward.isAchieved(receivedStringCount);
    final remaining = math.max(
      cavivaraReward.threshold - receivedStringCount,
      0,
    );
    final backgroundColor = isHighlighted
        ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.35)
        : theme.colorScheme.surface;
    final borderColor = isHighlighted
        ? theme.colorScheme.secondary
        : theme.colorScheme.outlineVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isAchieved ? Icons.emoji_events : Icons.lock_outline,
                  size: 32,
                  color: isAchieved
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        cavivaraReward.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        cavivaraReward.conditionDescription,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                isAchieved ? '獲得済み' : 'あと$remaining文字で獲得できます',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isAchieved
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsTile extends StatelessWidget {
  const _StatisticsTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
