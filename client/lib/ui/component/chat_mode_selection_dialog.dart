import 'package:flutter/material.dart';
import 'package:house_worker/data/model/chat_mode.dart';
import 'package:house_worker/data/model/chat_mode_selection.dart';
import 'package:house_worker/ui/component/chat_mode_extension.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';

class ChatModeSelectionDialog extends StatefulWidget {
  const ChatModeSelectionDialog({
    required this.initialSelection,
    this.isLocked = false,
    super.key,
  });

  final ChatModeSelection initialSelection;

  /// 会話が開始済みのため、モードを変更できないかどうか。
  ///
  /// `true` のときは選択肢を操作できず、現在のモードの確認のみ行える。
  final bool isLocked;

  @override
  State<ChatModeSelectionDialog> createState() =>
      _ChatModeSelectionDialogState();
}

class _ChatModeSelectionDialogState extends State<ChatModeSelectionDialog> {
  late ChatModeSelection _selection = widget.initialSelection;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('人格の選択'),
      content: SingleChildScrollView(
        child: RadioGroup<ChatModeSelection>(
          groupValue: _selection,
          onChanged: _onOptionChanged,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isLocked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '会話が始まると、人格は変更できません。'
                    '記憶を消去すると、再び選べるようになります。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              _buildOption(
                value: const ChatModeSelection.auto(),
                title: '人格の自動選択',
                subtitle: '会話の内容にあわせて、最適な人格を自動的に選びます。',
              ),
              for (final mode in ChatMode.values)
                _buildOption(
                  value: ChatModeSelection.fixed(mode),
                  title: mode.displayName,
                  subtitle: mode.description,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedbackHelper.lightImpact();
            Navigator.of(context).pop();
          },
          child: Text(widget.isLocked ? '閉じる' : 'キャンセル'),
        ),
        if (!widget.isLocked)
          TextButton(
            onPressed: () {
              HapticFeedbackHelper.lightImpact();
              Navigator.of(context).pop(_selection);
            },
            child: const Text('決定'),
          ),
      ],
    );
  }

  void _onOptionChanged(ChatModeSelection? selected) {
    if (selected == null) {
      return;
    }
    HapticFeedbackHelper.onToggle();
    setState(() {
      _selection = selected;
    });
  }

  Widget _buildOption({
    required ChatModeSelection value,
    required String title,
    required String subtitle,
  }) {
    return RadioListTile<ChatModeSelection>(
      value: value,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      // 会話が開始済みのときは選択を変更できないようにする。
      enabled: !widget.isLocked,
    );
  }
}
