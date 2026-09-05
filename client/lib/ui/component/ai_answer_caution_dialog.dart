import 'package:flutter/material.dart';
import 'package:house_worker/data/model/ai_answer_caution.dart';
import 'package:house_worker/ui/component/ai_answer_caution_extension.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';

/// カヴィヴァラさんの回答に対する注意書きを表示するダイアログ
class AiAnswerCautionDialog extends StatelessWidget {
  const AiAnswerCautionDialog({
    required this.caution,
    super.key,
  });

  final AiAnswerCaution caution;

  /// ダイアログを表示
  static Future<void> show(
    BuildContext context, {
    required AiAnswerCaution caution,
  }) {
    HapticFeedbackHelper.onDialogShow();

    return showDialog<void>(
      context: context,
      builder: (_) => AiAnswerCautionDialog(caution: caution),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('回答の正確さにご注意ください'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('カヴィヴァラさんの返答はAIによるもので、不正確な内容が含まれる場合があります。'),
          const SizedBox(height: 16),
          Text(
            '”${caution.quote}”',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).dividerColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              '— カヴィヴァラさん',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedbackHelper.lightImpact();
            Navigator.of(context).pop();
          },
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
