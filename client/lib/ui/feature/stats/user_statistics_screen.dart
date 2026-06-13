import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/repository/received_chat_string_count_repository.dart';
import 'package:house_worker/data/repository/sent_chat_string_count_repository.dart';
import 'package:house_worker/ui/component/app_drawer.dart';
import 'package:house_worker/ui/component/cavivara_portrait.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';
import 'package:house_worker/ui/component/supporter_title_caption.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';
import 'package:house_worker/ui/component/vp_summary_card.dart';
import 'package:house_worker/ui/feature/home/home_screen.dart';
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
    final sentCount = ref.watch(sentChatStringCountRepositoryProvider);
    final receivedCount = ref.watch(receivedChatStringCountRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('あなたの業績'),
      ),
      drawer: AppDrawer(
        isTalkSelected: false,
        isAchievementSelected: true,
        onSelectTalk: () {
          Navigator.of(context).pushAndRemoveUntil(
            HomeScreen.route(),
            (route) => false,
          );
        },
        onSelectAchievement: () {
          Navigator.of(context).pushAndRemoveUntil(
            UserStatisticsScreen.route(),
            (route) => false,
          );
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
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<int> sentCount,
    AsyncValue<int> receivedCount,
  ) {
    // すべてのデータが読み込まれているかチェック
    if (sentCount.isLoading || receivedCount.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // エラーがあるかチェック
    if (sentCount.hasError || receivedCount.hasError) {
      return Center(
        child: Text(
          'データの取得に失敗しました',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final sent = sentCount.value ?? 0;
    final received = receivedCount.value ?? 0;
    final theme = Theme.of(context);

    // サポーター情報を取得
    final supporterState = ref.watch(supportCavivaraPresenterProvider);

    return ListView(
      // 肖像画の発光（グロー）が上端で途切れないようにクリップを無効化する
      clipBehavior: Clip.none,
      children: [
        // 発光が AppBar に被らないよう、上部に余白を確保する
        const SizedBox(height: 16),
        // カヴィヴァラさんの肖像画（額縁付き）
        CavivaraPortrait(
          frameColor: supporterState.value?.currentTitle.color,
          animate: true,
        ),
        const SizedBox(height: 32),

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
        // 美術館の作品キャプションのように、称号と説明を表示する（応援画面と共有）
        final titleCard = SupporterTitleCaption(title: state.currentTitle);

        // 累計VPと次の称号までのVPを表示するカード（応援画面と共有）
        final vpCard = VpSummaryCard(
          totalVP: state.totalVP,
          currentTitle: state.currentTitle,
          nextTitle: state.nextTitle,
          vpToNext: state.vpToNextTitle,
          progress: state.progressToNextTitle,
        );

        // 応援画面へのナビゲーションボタン
        final supportButton = SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedbackHelper.lightImpact();
              Navigator.of(context).push(SupportCavivaraScreen.route());
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const Icon(Icons.favorite, size: 28),
            label: const Text('カヴィヴァラを応援する'),
          ),
        );

        return Column(
          children: [
            titleCard,
            const SizedBox(height: 48),
            supportButton,
            const SizedBox(height: 32),
            vpCard,
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
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
