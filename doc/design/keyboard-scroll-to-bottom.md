# キーボード表示時の最下部スクロール維持

## 概要

トーク画面で最下部にスクロールした状態でソフトキーボードを表示したとき、最後のメッセージと返信サジェストが見えなくなる問題を解消する。

## 問題

Flutter の `Scaffold` は `resizeToAvoidBottomInset: true`（デフォルト）により、キーボードが表示されるとボディ領域を縮小する。しかし `ListView` のスクロール位置（ピクセルオフセット）は自動調整されないため、ビューポートが小さくなっても末尾アイテムが画面外に押し出されたままになる。

## 解決策

`_ChatMessageListState.build()` 内で `MediaQuery.of(context).viewInsets.bottom` の変化を検知し、値が増加した（キーボードが出現した）かつユーザーが最下部にいた場合に、次のフレームで最下部へアニメーションスクロールする。

### 実装詳細

```dart
// フィールド追加
double _previousViewInsetBottom = 0;

// build() 内で検知・スクロール
final currentViewInsetBottom = MediaQuery.of(context).viewInsets.bottom;
final isKeyboardAppearing = currentViewInsetBottom > _previousViewInsetBottom;
_previousViewInsetBottom = currentViewInsetBottom;

final shouldAutoScroll =
    _isAtBottom &&
    (messages.length > _previousMessageCount ||
        isStreamingCompleted ||
        isKeyboardAppearing);  // ← 追加条件

if (shouldAutoScroll) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _scrollToBottom();
  });
}
```

### タイミングについて

Flutter のフレームパイプラインは「build → layout → paint → post-frame callbacks」の順で処理される。

- `build()` 呼び出し時点では、`_isAtBottom` はキーボード出現前の状態を保持している（スクロール通知はまだ発火していない）。
- `addPostFrameCallback` 内では layout 完了後の新しい `maxScrollExtent`（ビューポート縮小後の値）が利用できる。

これにより、キーボード出現前の「最下部にいた」という判定と、キーボード出現後の「新しい最下部」へのスクロールが正しく機能する。

## 対象ファイル

- `client/lib/ui/feature/home/home_screen.dart`（`_ChatMessageListState`）
