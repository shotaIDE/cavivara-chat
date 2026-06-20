# 返信サジェスト表示時のスクロール不要化（余白の事前確保）

## 概要

トーク画面で最下部にスクロールした状態で返信サジェストが新しく表示されるとき、
追加のスクロールなしでサジェストが見えるようにする。

カヴィヴァラの吹き出しの下に、返信サジェストとまったく同じ高さの余白をあらかじめ
確保しておき、サジェストはその余白の中にフェードインさせる。これによりフェードイン時に
レイアウトが変化せず、最下部スクロールが不要になる。

## 問題

返信サジェスト（`SuggestedReplyList`）は AI の返信ストリーミング完了後に 1 秒の遅延を
挟んでフェードインで表示される。

従来は遅延中に `SizedBox.shrink()`（高さ 0）を描画し、フェードイン時に高さ 0 → 48px へ
レイアウトが変化していた。このためサジェストが画面下端からはみ出し、表示に合わせて
最下部へスクロールし直す処理（`onSuggestionsVisible` コールバック）が必要だった。

## 解決策

遅延中（フェードイン前）に、**表示時とまったく同じ UI を非表示で描画して余白だけを
先に確保する**。サジェストはその余白の中にフェードインするため、表示前後で高さが
変化しない。

余白の高さを表示時と完全に一致させるため、専用の固定値ではなく表示時と同一の
ウィジェット（`_buildSuggestionList`）を共通利用する。

### 実装詳細

#### `SuggestedReplyList` への変更

表示用と余白確保用で同一の UI を構築するヘルパー `_buildSuggestionList` を用意し、
状態に応じてラップを切り替える。

```dart
// サジェストが存在しない場合は余白も確保しない。
if (isEmpty) {
  return const SizedBox.shrink();
}

final list = _buildSuggestionList(context, suggestions);

// 遅延中（フェードイン前）は同じ UI を非表示で描画して余白を確保する。
if (!_isVisible) {
  return Visibility(
    visible: false,
    maintainSize: true,
    maintainAnimation: true,
    maintainState: true,
    child: list,
  );
}

// 遅延後はフェードインで表示する。
return FadeTransition(
  opacity: _fadeAnimation,
  child: list,
);
```

`Visibility` の `maintainSize: true` により、描画とヒットテストのみ無効化したまま
レイアウト上のサイズ（高さ 48 + 上下余白）は維持される。

`onSuggestionsVisible` コールバックは不要になったため削除した。

#### 上下余白の扱い

サジェスト枠の上下余白（`Padding(vertical: 16)`）は `_buildSuggestionList` の内部に
含める。これにより、サジェストが存在せず `SizedBox.shrink()` を返すときには余白も
発生しない。以前は呼び出し元（`_ChatMessageListState`）側で `SuggestedReplyList` を
`Padding` で包んでいたため、サジェストが無くても上下 16px ずつ（計 32px）の余白が
残っていた。

### 既存の自動スクロールとの関係

サジェストは AI の返信ストリーミング完了時に保存される。保存された時点で `isEmpty` が
false になり、遅延中の余白（非表示の同一 UI）が描画される。同じタイミングで既存の
自動スクロール（`isStreamingCompleted` 条件）が発火するため、ユーザーが最下部にいれば
余白を含めて最下部までスクロールされる。

その後 1 秒の遅延を経てフェードインしても、すでに確保済みの余白の中に表示されるだけで
レイアウトは変化しない。よってフェードイン時の追加スクロールは不要となる。

## 対象ファイル

- `client/lib/ui/component/suggested_reply_list.dart`（`SuggestedReplyList`）
- `client/lib/ui/feature/home/home_screen.dart`（`_ChatMessageListState`）
