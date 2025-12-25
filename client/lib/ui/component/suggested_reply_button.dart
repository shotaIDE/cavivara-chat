import 'package:flutter/material.dart';

/// 個々のサジェストボタンを表示するWidget
class SuggestedReplyButton extends StatelessWidget {
  const SuggestedReplyButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bodyText = Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    return ActionChip(
      label: bodyText,
      onPressed: onTap,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.all(8),
    );
  }
}
