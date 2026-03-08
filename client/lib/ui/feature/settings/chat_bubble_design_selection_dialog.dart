import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/chat_bubble_design.dart';
import 'package:house_worker/data/repository/chat_bubble_design_repository.dart';
import 'package:house_worker/ui/component/chat_bubble_design_extension.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';

class ChatBubbleDesignSelectionDialog extends ConsumerStatefulWidget {
  const ChatBubbleDesignSelectionDialog({super.key});

  @override
  ConsumerState<ChatBubbleDesignSelectionDialog> createState() =>
      _ChatBubbleDesignSelectionDialogState();
}

class _ChatBubbleDesignSelectionDialogState
    extends ConsumerState<ChatBubbleDesignSelectionDialog> {
  ChatBubbleDesign? _selectedDesign;

  @override
  void initState() {
    super.initState();
    // 初期値として現在のデザインを設定
    final currentDesign = ref.read(chatBubbleDesignRepositoryProvider).value;
    _selectedDesign = currentDesign ?? ChatBubbleDesign.corporateStandard;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('吹き出しデザイン'),
      content: RadioGroup<ChatBubbleDesign>(
        groupValue: _selectedDesign,
        onChanged: (value) {
          HapticFeedbackHelper.selectionClick();
          setState(() {
            _selectedDesign = value;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ChatBubbleDesign.values.map((design) {
            return RadioListTile<ChatBubbleDesign>(
              value: design,
              title: Text(design.displayName),
              subtitle: _DesignPreview(design: design),
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
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
          onPressed: () async {
            HapticFeedbackHelper.onSuccess();
            if (_selectedDesign != null) {
              await ref
                  .read(chatBubbleDesignRepositoryProvider.notifier)
                  .save(_selectedDesign!);
            }
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _DesignPreview extends StatelessWidget {
  const _DesignPreview({
    required this.design,
  });

  final ChatBubbleDesign design;

  @override
  Widget build(BuildContext context) {
    const dummyBox = SizedBox(
      width: 40,
      height: 16,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        spacing: 8,
        children: [
          design.buildBubble(
            context: context,
            messageType: MessageType.user,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: dummyBox,
          ),
          design.buildBubble(
            context: context,
            messageType: MessageType.ai,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHigh,
            child: dummyBox,
          ),
        ],
      ),
    );
  }
}
