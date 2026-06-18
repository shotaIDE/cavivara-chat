# メッセージ送信時の最下部スクロール

## 概要

トーク画面でスクロール位置が最下部でない状態からメッセージを送信したとき、送信した自分のメッセージとカヴィヴァラさんのローディング中メッセージが見えるように最下部へ自動スクロールする。

## 問題

既存の自動スクロール処理は `_isAtBottom`（直近100px以内）が `true` の場合にのみ動作する設計だった。そのため、ユーザーが過去のメッセージを遡ってスクロールした状態でメッセージを送信すると、送信したメッセージもローディング中のAIメッセージも画面外に留まったままになっていた。

## 解決策

`_HomeScreenState._onMessageSent()` にスクロール処理を実装し、`_sendMessage()` および `_ChatMessageListState._sendSuggestion()` から呼び出す。最下部から離れている場合は、メッセージ送信時に最下部へアニメーションスクロールする。

なお、送信前の時点ですでに最下部付近（直近100px以内）にいる場合は、`_ChatMessageList` 側のメッセージ増加に伴う自動スクロール（同一の閾値で動作）に委ね、`_onMessageSent()` ではスクロールを予約しない。これにより、最下部で送信した際に `animateTo` が二重に走るのを防ぐ。

### 実装詳細

```dart
void _onMessageSent() {
  if (!_scrollController.hasClients) {
    return;
  }

  // 送信前の時点ですでに最下部付近にいる場合は、_ChatMessageList 側の
  // メッセージ増加に伴う自動スクロールに委ね、animateTo の二重実行を避ける。
  // この判定は新メッセージのレイアウト前（リビルド前）に同期的に行う必要がある。
  // post-frame まで遅らせると maxScrollExtent が増加し、判定が壊れるため。
  const threshold = 100.0; // _ChatMessageList の最下部判定と揃える
  final position = _scrollController.position;
  final isAtBottom = (position.maxScrollExtent - position.pixels) <= threshold;
  if (isAtBottom) {
    return;
  }

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

最下部判定（`isAtBottom`）は `addPostFrameCallback` を使わず**同期的**に行う。`_onMessageSent()` は `_sendMessage()` 内で `sendMessage()` の直後・リビルド前に呼ばれるため、この時点の `_scrollController.position` は新メッセージ追加前のレイアウトを指す。post-frame まで遅らせると新メッセージのレイアウトで `maxScrollExtent` が増加し、「送信前に最下部にいたか」の判定が壊れてしまう。

実際のスクロールは `addPostFrameCallback` で次フレームに予約する。`sendMessage()` 内ではユーザーメッセージとAIの思考中メッセージの両方が `await` に到達する前に同期的に state へ追加される（`home_presenter.dart` の行 49 と 74）。そのため次フレームでは両メッセージがすでにリストに存在し、`maxScrollExtent` も両メッセージを含めた値となるため、1回のスクロールで送信メッセージとローディング中メッセージの両方を表示できる。

### 既存の自動スクロールとの関係

- 送信前に最下部付近にいた場合は `_onMessageSent()` ではスクロールせず、`_ChatMessageList` 側のメッセージ増加に伴う自動スクロール（`_isAtBottom` が `true` の場合のみ動作）が最下部へ移動する。
- 送信前に最下部から離れていた場合は `_onMessageSent()` がスクロールする。このスクロール後、`_onScroll` リスナーが発火して `_isAtBottom` が `true` に更新される。これにより、AIからの返信ストリーミング中の既存の自動スクロールも引き続き正常に機能する。

## 対象ファイル

- `client/lib/ui/feature/home/home_screen.dart`（`_HomeScreenState`）
