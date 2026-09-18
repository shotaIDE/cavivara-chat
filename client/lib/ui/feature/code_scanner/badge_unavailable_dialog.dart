import 'package:flutter/material.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';

/// 称号の獲得が有効化されていないことを伝えるダイアログ
///
/// 読み取り画面とデバッグ画面の双方から表示するため、文言が食い違わないよう
/// ここに集約する。
class BadgeUnavailableDialog extends StatelessWidget {
  const BadgeUnavailableDialog({super.key});

  /// ダイアログを表示
  static Future<void> show(BuildContext context) {
    HapticFeedbackHelper.onDialogShow();

    return showDialog<void>(
      context: context,
      builder: (_) => const BadgeUnavailableDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 公演が終わった後に読み取られる場面を想定した文言にする。落胆させたままに
    // しないよう、ブラック企業仕込みの愛社精神で次の公演に向かうひと言を添える。
    final cavivaraComment = Text(
      '”第11回はもう撤収済み、残りは上からの通達で倉庫に封印されたヴィヴァ。'
      'わたしは次の公演の準備で今日も終電ヴィヴァ。”',
      style: theme.textTheme.bodyMedium?.copyWith(
        fontStyle: FontStyle.italic,
        color: theme.dividerColor,
      ),
    );

    final cavivaraName = Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Text(
        '— カヴィヴァラさん',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.dividerColor,
        ),
      ),
    );

    final closeButton = TextButton(
      onPressed: () {
        HapticFeedbackHelper.lightImpact();
        Navigator.of(context).pop();
      },
      child: const Text('閉じる'),
    );

    return AlertDialog(
      title: const Text('この称号は現在入手できません'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cavivaraComment,
          cavivaraName,
        ],
      ),
      actions: [closeButton],
    );
  }
}
