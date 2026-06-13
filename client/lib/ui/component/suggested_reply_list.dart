import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/ui/component/suggested_reply_button.dart';
import 'package:house_worker/ui/feature/home/home_presenter.dart';

/// サジェストボタンのリストを横スクロール表示するWidget
///
/// 初回サジェストと同様に、サジェストが現れてから少し遅延した後、
/// フェードインで表示する。
class SuggestedReplyList extends ConsumerStatefulWidget {
  const SuggestedReplyList({
    super.key,
    required this.onSuggestionTap,
  });

  final ValueChanged<String> onSuggestionTap;

  @override
  ConsumerState<SuggestedReplyList> createState() => _SuggestedReplyListState();
}

class _SuggestedReplyListState extends ConsumerState<SuggestedReplyList>
    with SingleTickerProviderStateMixin {
  /// 初回サジェストと同様に、サジェスト出現から表示開始までの遅延時間。
  static const _displayDelay = Duration(seconds: 1);

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  Timer? _displayTimer;

  /// 直近のビルドでサジェストが空だったかどうか。
  /// 空 ↔ 非空の遷移を検知して遅延表示を制御する。
  bool _wasEmpty = true;

  /// 遅延が明けてフェードインの対象になっているかどうか。
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onSuggestionsAppeared() {
    _displayTimer?.cancel();
    _isVisible = false;
    _animationController.reset();
    _displayTimer = Timer(_displayDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isVisible = true;
      });
      _animationController.forward(from: 0);
    });
  }

  void _onSuggestionsCleared() {
    _displayTimer?.cancel();
    _displayTimer = null;
    _isVisible = false;
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(suggestedRepliesProvider);
    final isEmpty = suggestions.isEmpty;

    // 空 ↔ 非空の遷移時のみ、表示状態を更新する。
    if (isEmpty != _wasEmpty) {
      _wasEmpty = isEmpty;
      if (isEmpty) {
        _onSuggestionsCleared();
      } else {
        _onSuggestionsAppeared();
      }
    }

    if (isEmpty || !_isVisible) {
      return const SizedBox.shrink();
    }

    // 横スクロール可能なボタンリストを構築
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(
            left: 16 + MediaQuery.of(context).viewPadding.left,
            right: 16 + MediaQuery.of(context).viewPadding.right,
          ),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return SuggestedReplyButton(
              text: suggestion,
              onTap: () => widget.onSuggestionTap(suggestion),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemCount: suggestions.length,
        ),
      ),
    );
  }
}
