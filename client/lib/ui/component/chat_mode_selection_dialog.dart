import 'package:flutter/material.dart';
import 'package:house_worker/data/model/chat_mode.dart';
import 'package:house_worker/data/model/chat_mode_selection.dart';
import 'package:house_worker/ui/component/chat_mode_extension.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';

class ChatModeSelectionDialog extends StatefulWidget {
  const ChatModeSelectionDialog({required this.initialSelection, super.key});

  final ChatModeSelection initialSelection;

  @override
  State<ChatModeSelectionDialog> createState() =>
      _ChatModeSelectionDialogState();
}

class _ChatModeSelectionDialogState extends State<ChatModeSelectionDialog> {
  late ChatModeSelection _selection = widget.initialSelection;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('回答モードの選択'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOption(
              value: const ChatModeSelection.auto(),
              title: '自動選択',
              subtitle: '会話の内容にあわせて、最適なモードを自動的に選びます。',
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
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedbackHelper.lightImpact();
            Navigator.of(context).pop();
          },
          child: const Text('キャンセル'),
        ),
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

  Widget _buildOption({
    required ChatModeSelection value,
    required String title,
    required String subtitle,
  }) {
    return RadioListTile<ChatModeSelection>(
      value: value,
      groupValue: _selection,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      onChanged: (selected) {
        if (selected == null) {
          return;
        }
        HapticFeedbackHelper.onToggle();
        setState(() {
          _selection = selected;
        });
      },
    );
  }
}
