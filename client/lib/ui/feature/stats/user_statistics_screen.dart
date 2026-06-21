import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              animate: true,
            ),
            const SizedBox(height: 32),
            _buildSupporterSection(context, supporterState),
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
