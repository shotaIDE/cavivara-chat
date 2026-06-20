# 返信サジェスト表示時の最下部スクロール維持

## 概要

トーク画面で最下部にスクロールした状態で返信サジェストが新しく表示されたとき、自動的に最下部へスクロールしてサジェストが見えるようにする。

## 問題

既存の自動スクロール処理は以下の条件で最下部へスクロールする。

- メッセージ数が増えた場合
- ストリーミングが完了した場合
- キーボードが表示された場合

しかし、返信サジェスト（`SuggestedReplyList`）は AI の返信ストリーミング完了後に 1 秒の遅延を挟んでフェードインで表示される。このタイミングには既存の自動スクロール条件が一致しないため、ユーザーが最下部にいてもサジェストが画面外に表示されたままになっていた。

## 解決策

`SuggestedReplyList` に `onSuggestionsVisible` コールバックを追加し、サジェストが表示され始めるタイミングで `_ChatMessageListState` へ通知する。通知を受けた `_ChatMessageListState` はユーザーが最下部にいる場合に最下部へスクロールする。

### 実装詳細

#### `SuggestedReplyList` への変更

`onSuggestionsVisible` コールバックを追加する。

```dart
class SuggestedReplyList extends ConsumerStatefulWidget {
  const SuggestedReplyList({
    super.key,
    required this.onSuggestionTap,
    this.onSuggestionsVisible,  // 追加
  });

  final ValueChanged<String> onSuggestionTap;

  /// サジェストが遅延後に表示され始めるタイミングで呼ばれるコールバック。
  ///
  /// `SizedBox.shrink()` からサジェストリストへの遷移タイミング（レイアウト変更前）
  /// に呼ばれるため、呼び出し元は `addPostFrameCallback` でスクロールを予約すること。
  final VoidCallback? onSuggestionsVisible;
}
```

タイマー満了時（1 秒後）に `setState(() { _isVisible = true; })` した直後にコールバックを呼ぶ。

```dart
_displayTimer = Timer(_displayDelay, () {
  if (!mounted) return;
  setState(() {
    _isVisible = true;
  });
  // SizedBox.shrink() → サジェストリストへの遷移を親に通知する。
  widget.onSuggestionsVisible?.call();
  _animationController.forward(from: 0);
});
```

#### `_ChatMessageListState` への変更

`_onSuggestionsVisible()` メソッドを追加し、`SuggestedReplyList` に渡す。

```dart
void _onSuggestionsVisible() {
  if (!_isAtBottom) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _scrollToBottom();
  });
}
```

```dart
SuggestedReplyList(
  onSuggestionTap: _sendSuggestion,
  onSuggestionsVisible: _onSuggestionsVisible,  // 追加
)
```

### タイミングについて

コールバックは `setState(() { _isVisible = true; })` の直後・`addPostFrameCallback` 登録前に呼ばれる。この時点では `SizedBox.shrink()` から 48px 高のリストへのレイアウト変更はまだ反映されていない。

`_onSuggestionsVisible()` 内で `addPostFrameCallback` を登録することで、レイアウト変更後（`maxScrollExtent` 増加後）に `_scrollToBottom()` が実行される。これにより正しい最下部位置へのスクロールが保証される。

### 既存の自動スクロールとの関係

サジェストはストリーミング完了後に表示されることが多い。ストリーミング完了時点で既存の自動スクロール（`isStreamingCompleted` 条件）が発火し、その後 1 秒の遅延を経てサジェスト表示時に本機能のスクロールが発火する。これらは独立したタイミングで動作し、二重スクロールにはならない（後者発火時はすでに最下部に到達済みのため、1px 未満の差分スクロールになる）。

## 対象ファイル

- `client/lib/ui/component/suggested_reply_list.dart`（`SuggestedReplyList`）
- `client/lib/ui/feature/home/home_screen.dart`（`_ChatMessageListState`）
