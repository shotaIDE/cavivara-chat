import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/cavivara_portrait.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';
import 'package:house_worker/ui/component/supporter_title_caption.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_presenter.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    required this.isTalkSelected,
    required this.isAchievementSelected,
    required this.onSelectTalk,
    required this.onSelectAchievement,
    required this.onSelectCamera,
    required this.onSelectSettings,
  });

  final bool isTalkSelected;
  final bool isAchievementSelected;
  final VoidCallback onSelectTalk;
  final VoidCallback onSelectAchievement;
  final VoidCallback onSelectCamera;
  final VoidCallback onSelectSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 称号は取得できなくてもメニューは表示するため、値のみ取り出す
    final currentTitle = ref
        .watch(supportCavivaraPresenterProvider)
        .value
        ?.currentTitle;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(context, currentTitle),
            const Divider(),
            _buildTalkTile(context),
            _buildCameraTile(context),
            _buildSettingsTile(context),
          ],
        ),
      ),
    );
  }

  /// 額縁付きの肖像画と称号を表示し、タップで業績画面へ遷移するヘッダー。
  Widget _buildHeader(BuildContext context, SupporterTitle? currentTitle) {
    final header = Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          CavivaraPortrait(
            frameColor: currentTitle?.color,
            imagePath: currentTitle?.imagePath,
            maxWidth: 120,
            simplified: true,
          ),
          if (currentTitle != null) ...[
            const SizedBox(height: 16),
            SupporterTitleCaption(title: currentTitle),
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      onTapHint: '業績画面を開く',
      child: InkWell(
        onTap: () {
          HapticFeedbackHelper.onNavigationTap();
          Navigator.of(context).pop();
          if (!isAchievementSelected) {
            onSelectAchievement();
          }
        },
        child: header,
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

  Widget _buildCameraTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.camera_alt),
      title: const Text('カメラ'),
      onTap: () {
        HapticFeedbackHelper.onNavigationTap();
        Navigator.of(context).pop();
        onSelectCamera();
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
