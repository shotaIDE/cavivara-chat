# キーボード表示時の最下部スクロール維持

## 概要

トーク画面で最下部にスクロールした状態でソフトキーボードを表示したとき、最後のメッセージと返信サジェストが見えなくなる問題を解消する。

## 問題

Flutter の `Scaffold` は `resizeToAvoidBottomInset: true`（デフォルト）により、キーボードが表示されるとボディ領域を縮小する。しかし `ListView` のスクロール位置（ピクセルオフセット）は自動調整されないため、ビューポートが小さくなっても末尾アイテムが画面外に押し出されたままになる。

## 解決策

`_ChatMessageListState.build()` 内で `viewInsets.bottom` の変化を検知し、値が増加した（キーボードが出現した）かつユーザーが最下部にいた場合に、次のフレームで最下部へアニメーションスクロールする。

### `viewInsets.bottom` の取得元に関する注意

当初は `_ChatMessageListState.build()` 内で `MediaQuery.of(context).viewInsets.bottom` を直接参照していたが、この値は**常に 0** となり検知が機能しなかった。

`_ChatMessageList` は `Scaffold` の `body` 内に配置されている。`Scaffold` は `resizeToAvoidBottomInset: true`（デフォルト）のとき、ボディをキーボード分だけ縮小したうえで、ボディへ渡す `MediaQuery` から `viewInsets.bottom` を取り除く（`MediaQuery.removeViewInsets`）。そのため `body` 内では `viewInsets.bottom` が 0 になる。

対策として、`Scaffold` より上位の `_HomeScreenState.build()` で `MediaQuery.of(context).viewInsets.bottom`（キーボード分を含む値）を取得し、`_ChatMessageList` に `viewInsetBottom` として渡す。上位コンテキストで `MediaQuery` を参照することで、キーボード開閉時に `_HomeScreenState` → `_ChatMessageList` が再ビルドされ、検知も毎フレーム更新される。

### 実装詳細

```dart
// _HomeScreenState.build() 内（Scaffold より上位）
final viewInsetBottom = MediaQuery.of(context).viewInsets.bottom;
// ...
_ChatMessageList(
  // ...
  viewInsetBottom: viewInsetBottom,
);
```

```dart
// _ChatMessageList にプロパティ追加
final double viewInsetBottom;

// _ChatMessageListState のフィールド
double _previousViewInsetBottom = 0;

// build() 内で検知・スクロール
final currentViewInsetBottom = widget.viewInsetBottom;
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

- `client/lib/ui/feature/home/home_screen.dart`（`_HomeScreenState`・`_ChatMessageList`・`_ChatMessageListState`）
