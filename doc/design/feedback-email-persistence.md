# 返信用メールアドレスの保持

## 概要

「ご意見・ご要望」画面（`SubmitFeedbackScreen`）で入力した返信用メールアドレスを端末に保持し、次回以降の画面表示時に自動で復元する。あわせて、保持した内容をユーザー自身が消去できるようにクリアボタンを表示する。

## 要件

- 送信せずに画面を離れた場合も、入力した返信用メールアドレスを保持する。
- 送信した場合も、入力した返信用メールアドレスを保持する。
- 入力中は入力欄にクリアボタンを表示し、押下すると入力内容と保持した内容の両方を消去する。

## アーキテクチャ

### レイヤー構成

1. **UI Layer** - `SubmitFeedbackScreen`（初期値の復元、入力内容の保存、クリアボタン）
2. **Repository Layer** - `FeedbackEmailRepository`
3. **Data Layer** - SharedPreferences（`PreferenceKey.feedbackEmail`）

### FeedbackEmailRepository

**配置**: `client/lib/data/repository/feedback_email_repository.dart`

**役割**: 返信用メールアドレスの永続化と復元を担う。

- `build()`: 永続化された値を返す。未保存の場合は空文字を返す。
- `save(String email)`: 値を永続化し、状態に反映する。
- `clear()`: 永続化された値を削除し、状態を空文字に戻す。

## 実装詳細

### 保存のタイミング

入力欄の `onChanged` で都度保存する。送信時や画面離脱時ではなく入力のたびに保存することで、送信・未送信のどちらの経路でも、さらにアプリが強制終了した場合でも入力内容が残る。

### 初期値の復元

`_SubmitFeedbackScreenState.initState()` で `ref.listenManual(..., fireImmediately: true)` により永続化された値を購読し、最初に値が得られた一度だけ `TextEditingController` へ反映する。

保存のたびに `FeedbackEmailRepository` の状態が更新されるため、復元を一度きりに制限しないと、入力中に `TextEditingController.text` が再設定されてカーソルが末尾へ移動してしまう。これを避けるために `_hasRestoredEmail` フラグで制御する。

### クリアボタン

入力欄の `suffixIcon` として表示する。入力内容が空の場合は表示しない。

表示・非表示を入力内容に追従させるため、`ValueListenableBuilder<TextEditingValue>` で `TextEditingController` を購読して入力欄を再構築する。

押下時は `TextEditingController.clear()` による入力内容の消去と、`FeedbackEmailRepository.clear()` による永続化データの削除をあわせて行う。

## 対象ファイル

- `client/lib/data/model/preference_key.dart`（`feedbackEmail` を追加）
- `client/lib/data/repository/feedback_email_repository.dart`（新規）
- `client/lib/ui/feature/settings/submit_feedback_screen.dart`
- `client/test/data/repository/feedback_email_repository_test.dart`（新規）
- `client/test/ui/feature/settings/submit_feedback_screen_test.dart`（新規）
