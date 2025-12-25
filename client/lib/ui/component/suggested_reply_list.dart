import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/ui/component/suggested_reply_button.dart';
import 'package:house_worker/ui/feature/home/home_presenter.dart';

/// サジェストボタンのリストを横スクロール表示するWidget
class SuggestedReplyList extends ConsumerWidget {
  const SuggestedReplyList({
    super.key,
    required this.cavivaraId,
    required this.onSuggestionTap,
  });

  final String cavivaraId;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(suggestedRepliesProvider(cavivaraId));

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // 横スクロール可能なボタンリストを構築
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return SuggestedReplyButton(
            text: suggestion,
            onTap: () => onSuggestionTap(suggestion),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemCount: suggestions.length,
      ),
    );
  }
}
