# メッセージ送信時の最下部スクロール

## 概要

トーク画面でスクロール位置が最下部でない状態からメッセージを送信したとき、送信した自分のメッセージとカヴィヴァラさんのローディング中メッセージが見えるように最下部へ自動スクロールする。

## 問題

既存の自動スクロール処理は `_isAtBottom`（直近100px以内）が `true` の場合にのみ動作する設計だった。そのため、ユーザーが過去のメッセージを遡ってスクロールした状態でメッセージを送信すると、送信したメッセージもローディング中のAIメッセージも画面外に留まったままになっていた。

## 解決策

`_HomeScreenState._onMessageSent()` にスクロール処理を実装し、`_sendMessage()` および `_ChatMessageListState._sendSuggestion()` から呼び出す。`_isAtBottom` の状態にかかわらず、メッセージ送信時は常に最下部へアニメーションスクロールする。

### 実装詳細

```dart
void _onMessageSent() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
    );
  });
}
```

`_sendMessage()` に `_onMessageSent()` の呼び出しを追加：

```dart
void _sendMessage() {
  final message = _messageController.text.trim();
  if (message.isNotEmpty) {
    HapticFeedbackHelper.onMessageSent();
    ref.read(chatMessagesProvider.notifier).sendMessage(message);
    _messageController.clear();
    _onMessageSent();  // ← 追加
  }
}
```

### タイミングについて

`sendMessage()` 内ではユーザーメッセージとAIの思考中メッセージの両方が `await` に到達する前に同期的に state へ追加される（`home_presenter.dart` の行 49 と 74）。

そのため `addPostFrameCallback` が発火する次フレームでは、両メッセージがすでにリストに存在する。`maxScrollExtent` もその時点で両メッセージを含めた値となるため、1回のスクロールで送信メッセージとローディング中メッセージの両方を表示できる。

### 既存の自動スクロールとの関係

このスクロール後、`_onScroll` リスナーが発火して `_isAtBottom` が `true` に更新される。これにより、AIからの返信ストリーミング中の既存の自動スクロール（`_isAtBottom` が `true` の場合のみ動作）も引き続き正常に機能する。

## 対象ファイル

- `client/lib/ui/feature/home/home_screen.dart`（`_HomeScreenState`）
