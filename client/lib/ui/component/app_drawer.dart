import 'package:flutter/material.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.isTalkSelected,
    required this.isJobMarketSelected,
    required this.isAchievementSelected,
    required this.onSelectTalk,
    required this.onSelectJobMarket,
    required this.onSelectAchievement,
    required this.onSelectSettings,
  });

  final bool isTalkSelected;
  final bool isJobMarketSelected;
  final bool isAchievementSelected;
  final VoidCallback onSelectTalk;
  final VoidCallback onSelectJobMarket;
  final VoidCallback onSelectAchievement;
  final VoidCallback onSelectSettings;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(context),
            _buildTalkTile(context),
            _buildJobMarketTile(context),
            _buildAchievementTile(context),
            const Divider(),
            _buildSettingsTile(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return DrawerHeader(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          'メニュー',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildTalkTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.chat),
      title: const Text('トーク'),
      selected: isTalkSelected,
      onTap: () {
        HapticFeedbackHelper.onNavigationTap();
        Navigator.of(context).pop();
        if (!isTalkSelected) {
          onSelectTalk();
        }
      },
    );
  }

  Widget _buildJobMarketTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.work),
      title: const Text('転職市場'),
      selected: isJobMarketSelected,
      onTap: () {
        HapticFeedbackHelper.onNavigationTap();
        Navigator.of(context).pop();
        if (!isJobMarketSelected) {
          onSelectJobMarket();
        }
      },
    );
  }

  Widget _buildAchievementTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.insights),
      title: const Text('あなたの業績'),
      selected: isAchievementSelected,
      onTap: () {
        HapticFeedbackHelper.onNavigationTap();
        Navigator.of(context).pop();
        if (!isAchievementSelected) {
          onSelectAchievement();
        }
      },
    );
  }

  Widget _buildSettingsTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.settings),
      title: const Text('設定'),
      onTap: () {
        HapticFeedbackHelper.onNavigationTap();
        Navigator.of(context).pop();
        onSelectSettings();
      },
    );
  }
}
