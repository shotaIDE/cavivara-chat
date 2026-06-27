import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/earned_badge.dart';
import 'package:house_worker/data/repository/earned_badges_repository.dart';
import 'package:house_worker/ui/component/app_badge_extension.dart';
import 'package:house_worker/ui/component/app_badge_icon.dart';
import 'package:house_worker/ui/component/app_drawer.dart';
import 'package:house_worker/ui/component/cavivara_portrait.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';
import 'package:house_worker/ui/component/supporter_title_caption.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';
import 'package:house_worker/ui/component/vp_summary_card.dart';
import 'package:house_worker/ui/feature/code_scanner/code_scanner_screen.dart';
import 'package:house_worker/ui/feature/home/home_screen.dart';
import 'package:house_worker/ui/feature/settings/settings_screen.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_presenter.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_screen.dart';
import 'package:house_worker/ui/feature/stats/badge_detail_dialog.dart';

class UserStatisticsScreen extends ConsumerWidget {
  const UserStatisticsScreen({super.key});

  static const name = 'UserStatisticsScreen';

  static MaterialPageRoute<UserStatisticsScreen> route() =>
      MaterialPageRoute<UserStatisticsScreen>(
        builder: (_) => const UserStatisticsScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supporterState = ref.watch(supportCavivaraPresenterProvider);

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
        onSelectCamera: () {
          Navigator.of(context).push(CodeScannerScreen.route());
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
        child: ListView(
          clipBehavior: Clip.none,
          children: [
            const SizedBox(height: 16),
            CavivaraPortrait(
              frameColor: supporterState.value?.currentTitle.color,
              imagePath: supporterState.value?.currentTitle.imagePath,
              animate: true,
            ),
            const SizedBox(height: 32),
            _buildSupporterSection(context, supporterState),
            const SizedBox(height: 48),
            const _EarnedBadgeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupporterSection(
    BuildContext context,
    AsyncValue<SupportCavivaraState> supporterState,
  ) {
    final theme = Theme.of(context);

    return supporterState.when(
      data: (state) {
        final titleCard = SupporterTitleCaption(title: state.currentTitle);

        final vpCard = VpSummaryCard(
          totalVP: state.totalVP,
          currentTitle: state.currentTitle,
          nextTitle: state.nextTitle,
          vpToNext: state.vpToNextTitle,
          progress: state.progressToNextTitle,
        );

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

/// 獲得済みバッジ一覧セクション
class _EarnedBadgeSection extends ConsumerWidget {
  const _EarnedBadgeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnedBadgesAsync = ref.watch(earnedBadgesRepositoryProvider);

    return earnedBadgesAsync.when(
      data: (badges) {
        if (badges.isEmpty) {
          return const SizedBox.shrink();
        }

        final sectionTitle = Text(
          '獲得済みバッジ',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        );

        // タイルの内容（パディング + アイコン + 余白 + タイトル2行 + 余白 + 日付1行）
        // がちょうど収まる高さを算出し、余分な余白が出ないようにする。
        // 文字サイズ設定にも追従させるため textScaler で換算する。
        final textScaler = MediaQuery.textScalerOf(context);
        final lineHeight =
            (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * 1.4;
        final tileExtent =
            _tilePadding * 2 +
            _tileIconSize +
            8 +
            textScaler.scale(lineHeight * 2) +
            4 +
            textScaler.scale(lineHeight);

        // タイルレイアウト（2列グリッド、新しい順に左上から配置）
        final grid = GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: tileExtent,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) =>
              _EarnedBadgeTile(earnedBadge: badges[index]),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle,
            const SizedBox(height: 16),
            grid,
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// 獲得済みバッジタイルの内側パディング
const _tilePadding = 8.0;

/// 獲得済みバッジタイルのアイコンの一辺の長さ
const _tileIconSize = 64.0;

/// 獲得済みバッジのタイル
class _EarnedBadgeTile extends StatelessWidget {
  const _EarnedBadgeTile({required this.earnedBadge});

  final EarnedBadge earnedBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final badgeIcon = AppBadgeIcon(
      badge: earnedBadge.badge,
      size: _tileIconSize,
    );

    final titleStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.bold,
    );
    // タイトルが1行か2行かでアイコンや日付の位置がずれないよう、
    // 常に2行分の高さを確保してタイトル領域の高さを揃える。
    final titleLineHeight = (titleStyle?.fontSize ?? 12) * 1.4;
    final title = SizedBox(
      height: MediaQuery.textScalerOf(context).scale(titleLineHeight * 2),
      child: Center(
        child: Text(
          earnedBadge.badge.displayName,
          style: titleStyle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    final earnedAt = earnedBadge.earnedAt;
    final dateLabel = Text(
      '${earnedAt.year}/${earnedAt.month.toString().padLeft(2, '0')}/${earnedAt.day.toString().padLeft(2, '0')}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedbackHelper.lightImpact();
        BadgeDetailDialog.show(context, earnedBadge: earnedBadge);
      },
      child: Padding(
        padding: const EdgeInsets.all(_tilePadding),
        child: Column(
          // アイコンを各セルの上端で揃えるため、上詰め(既定)で配置する。
          children: [
            badgeIcon,
            const SizedBox(height: 8),
            title,
            const SizedBox(height: 4),
            dateLabel,
          ],
        ),
      ),
    );
  }
}
