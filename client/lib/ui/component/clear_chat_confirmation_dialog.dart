import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';

part 'clear_chat_confirmation_dialog.freezed.dart';

@freezed
sealed class ClearChatDialogResult with _$ClearChatDialogResult {
  const factory ClearChatDialogResult({
    required bool confirmed,
    required bool shouldSkipConfirmation,
  }) = _ClearChatDialogResult;
}

class ClearChatConfirmationDialog extends StatefulWidget {
  const ClearChatConfirmationDialog({super.key});

  @override
  State<ClearChatConfirmationDialog> createState() =>
      _ClearChatConfirmationDialogState();
}

class _ClearChatConfirmationDialogState
    extends State<ClearChatConfirmationDialog> {
  bool _shouldSkipConfirmation = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('記憶を消去しますか？'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('カヴィヴァラさんの記憶を消去し、新しく会議を始めますか？'),
          const SizedBox(height: 16),
          Text(
            '”記憶消さないでほしいヴィヴァ”',
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
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _shouldSkipConfirmation,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) {
              HapticFeedbackHelper.onToggle();
              setState(() {
                _shouldSkipConfirmation = value ?? false;
              });
            },
            title: const Text('今後この確認を表示しない'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedbackHelper.onClearChat();
            Navigator.of(context).pop(
              ClearChatDialogResult(
                confirmed: true,
                shouldSkipConfirmation: _shouldSkipConfirmation,
              ),
            );
          },
          child: const Text('記憶を消去'),
        ),
        TextButton(
          onPressed: () {
            HapticFeedbackHelper.lightImpact();
            Navigator.of(context).pop(
              const ClearChatDialogResult(
                confirmed: false,
                shouldSkipConfirmation: false,
              ),
            );
          },
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}
