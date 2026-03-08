import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/repository/received_chat_string_count_repository.dart';
import 'package:house_worker/data/repository/resume_viewing_duration_repository.dart';
import 'package:house_worker/data/repository/sent_chat_string_count_repository.dart';
import 'package:house_worker/data/service/employment_state_service.dart';
import 'package:house_worker/ui/component/app_drawer.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';
import 'package:house_worker/ui/feature/home/home_screen.dart';
import 'package:house_worker/ui/feature/job_market/job_market_screen.dart';
import 'package:house_worker/ui/feature/settings/settings_screen.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_presenter.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_screen.dart';
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

        // 称号セクション（統計の上に配置）
        Text(
          '称号',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // タイル状のグリッドレイアウト
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final reward in CavivaraReward.values)
              _RewardTile(
                cavivaraReward: reward,
                isHighlighted: highlightedReward == reward,
                receivedStringCount: received,
              ),
          ],
        ),
        const SizedBox(height: 32),

        // 統計セクション
        Text(
          '統計',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }

  Widget _buildSupporterSection(
    BuildContext context,
    AsyncValue<SupportCavivaraState> supporterState,
  ) {
    final theme = Theme.of(context);

    return supporterState.when(
      data: (state) {
        final titleColor = state.currentTitle.color;
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                titleColor.withValues(alpha: isDark ? 0.35 : 0.25),
                titleColor.withValues(alpha: isDark ? 0.15 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: titleColor.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: titleColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // アイコンと称号名
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 大きな称号アイコン
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            titleColor,
                            titleColor.withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: titleColor.withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        state.currentTitle.icon,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // 称号情報
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'サポーター称号',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.currentTitle.displayName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? titleColor
                                  : HSLColor.fromColor(
                                      titleColor,
                                    ).withLightness(0.3).toColor(),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.currentTitle.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 累計VP表示（大きく目立つように）
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: titleColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '累計 ${state.totalVP} VP',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 次の称号への進捗
                if (state.nextTitle != null) ...[
                  Text(
                    '次の称号「${state.nextTitle!.displayName}」まで'
                    'あと${state.vpToNextTitle}VP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: state.progressToNextTitle,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(titleColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 応援画面へのナビゲーションボタン
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedbackHelper.lightImpact();
                      Navigator.of(context).push(SupportCavivaraScreen.route());
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: titleColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.favorite),
                    label: const Text('カヴィヴァラを応援する'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  // タイルのサイズ
  static const double _tileSize = 80;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAchieved = cavivaraReward.isAchieved(receivedStringCount);

    // 進捗率を計算（0.0 ~ 1.0）
    final progress = (receivedStringCount / cavivaraReward.threshold).clamp(
      0.0,
      1.0,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedbackHelper.lightImpact();
        _showRewardDetail(context, theme, isAchieved, progress);
      },
      child: Opacity(
        opacity: isAchieved ? 1.0 : 0.5,
        child: Container(
          width: _tileSize,
          height: _tileSize,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Icon(
            isAchieved ? Icons.emoji_events : Icons.lock_outline,
            size: 32,
            color: isAchieved
                ? const Color(0xFFFFB300)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// タップ時に詳細を表示するダイアログ
  void _showRewardDetail(
    BuildContext context,
    ThemeData theme,
    bool isAchieved,
    double progress,
  ) {
    final remaining = math.max(
      cavivaraReward.threshold - receivedStringCount,
      0,
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          cavivaraReward.displayName,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cavivaraReward.conditionDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isAchieved)
              Text(
                '獲得済み',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                'あと$remaining文字（${(progress * 100).toInt()}%）',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
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
