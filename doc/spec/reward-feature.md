# Reward 機能仕様書

## 概要

受信チャット文字数に応じて称号を獲得できる機能。現在 2 つの称号（1000 文字でアルバイト、10000 文字でリーダー）が存在。

## 主要コンポーネント

### CavivaraReward ([cavivara_reward.dart](../../../client/lib/ui/feature/stats/cavivara_reward.dart))

称号の定義を管理する列挙型。各称号は以下のプロパティを持つ:
- `threshold`: 達成に必要な受信文字数
- `displayName`: UIに表示される称号名
- `conditionDescription`: 達成条件の説明文

主要メソッド:
- `isAchieved(int receivedStringCount)`: 指定された文字数で達成済みかを判定
- `static highestAchieved(int receivedStringCount)`: 指定された文字数で達成可能な最高位の称号を取得

### HasEarnedXxxRewardRepository

各称号の獲得状態を SharedPreferences で永続化するリポジトリ。現在の実装:
- [HasEarnedPartTimerRewardRepository](../../../client/lib/data/repository/has_earned_part_timer_reward_repository.dart)
- [HasEarnedPartTimeLeaderRewardRepository](../../../client/lib/data/repository/has_earned_part_time_leader_reward_repository.dart)

各リポジトリは以下のメソッドを提供:
- `markAsEarned()`: 獲得をマークし、状態を永続化
- `resetForDebug()`: デバッグ用のリセット機能

### AwardReceivedChatString ([home_presenter.dart:210](../../../client/lib/ui/feature/home/home_presenter.dart#L210))

称号獲得通知のロジックを管理するプロバイダー。受信文字数の変更を監視し、新規獲得時に通知を表示する。

主要メソッド:
- `_handleReceivedChatStringCountUpdate()`: 受信文字数の更新時に称号達成判定を実行
- `_checkIfRewardEarned()`: 指定された称号が既に獲得済みかをチェック
- `_markRewardAsEarned()`: 新規獲得時に対応するリポジトリに状態を保存

### HeadsUpNotification ([heads_up_notification_presenter.dart](../../../client/lib/ui/component/heads_up_notification_presenter.dart))

称号獲得時に画面上部に表示される通知UIの状態管理。5秒後に自動的に非表示になる。

状態:
- `hidden`: 通知非表示
- `visible(CavivaraReward)`: 指定された称号の通知を表示中
- `firstMessageBonus(earnedVP, newTitleName)`: 初回メッセージボーナスの通知を表示中
- `dailyLoginBonus(earnedVP)`: ログインボーナスの通知を表示中

### UserStatisticsScreen ([user_statistics_screen.dart](../../../client/lib/ui/feature/stats/user_statistics_screen.dart))

業績画面。統計情報と称号一覧を表示。新規獲得時は `highlightedReward` で該当称号をハイライト表示。

表示内容:
- 送信チャット文字数
- 受信チャット文字数
- 全称号の一覧（達成状態、残り必要文字数を含む）

## データフロー

### チャット受信時

1. AI レスポンス受信完了 → [ChatMessages.sendMessage()](../../../client/lib/ui/feature/home/home_presenter.dart#L28) が [ReceivedChatStringCountRepository](../../../client/lib/data/repository/received_chat_string_count_repository.dart) に文字数を加算
2. `AwardReceivedChatString` が `ReceivedChatStringCountRepository` の変更を監視し、`_handleReceivedChatStringCountUpdate()` を呼び出し
3. `CavivaraReward.highestAchieved()` で最高位の達成可能称号を取得
4. `_checkIfRewardEarned()` で既獲得かチェック
5. 新規獲得の場合、`_markRewardAsEarned()` で状態を永続化し、`HeadsUpNotification` で通知を表示

### ログインボーナス付与時（1日1回）

1. ログイン後にホーム画面が表示されると、[HomeScreen](../../../client/lib/ui/feature/home/home_screen.dart) の `initState()` が `AwardDailyLoginBonus` を `listenManual` で監視し、プロバイダーをビルドする
2. `AwardDailyLoginBonus.build()` が `_tryAwardDailyLoginBonus()` を実行
3. [LoginBonusGrantedDatesRepository](../../../client/lib/data/repository/login_bonus_granted_dates_repository.dart) から付与済みの日付一覧を取得し、当日（時刻を切り捨てた日付）が含まれるか判定
4. 当日がすでに含まれている場合は何もしない
5. 含まれていない場合、`VivaPointRepository` に 1 VP を加算し、当日を付与済み日付一覧に追加して `LoginBonusGrantedDatesRepository` に保存
6. `HeadsUpNotification` の `showDailyLoginBonus()` で称号獲得と同じ仕組みのアプリ内通知を表示

> 付与済み日付を配列で保持しているため、同一日付には一度しか付与されない。端末の日付を過去・未来に変更した場合でも、その日付がまだ含まれていなければ付与されうるが、同じ日付を行き来して無制限に獲得することはできない。

### 業績画面表示時

`UserStatisticsScreen` が以下の情報を取得して表示:
- `ReceivedChatStringCountRepository`: 総受信文字数
- `SentChatStringCountRepository`: 総送信文字数

各称号の達成状態は `CavivaraReward.isAchieved()` でリアルタイムに判定。

## 永続化

[PreferenceKey](../../../client/lib/data/model/preference_key.dart) を通じて SharedPreferences に保存:

- `hasEarnedPartTimerReward`: アルバイト称号の獲得状態
- `hasEarnedPartTimeLeaderReward`: リーダー称号の獲得状態
- `totalReceivedChatStringCount`: 総受信文字数（[ReceivedChatStringCountRepository](../../../client/lib/data/repository/received_chat_string_count_repository.dart) が管理）
- `totalSentChatStringCount`: 総送信文字数
- `totalVivaPoint`: 総 VP（[VivaPointRepository](../../../client/lib/data/repository/viva_point_repository.dart) が管理）
- `loginBonusGrantedDates`: ログインボーナスを付与した日付の一覧（[LoginBonusGrantedDatesRepository](../../../client/lib/data/repository/login_bonus_granted_dates_repository.dart) が管理。1日1回付与の重複防止に使用）

**注意**: 古いドキュメントで言及されていた `maxReceivedChatRewardThresholdNotified` は現在の実装では使用されていない。重複通知防止は `hasEarnedXxxReward` フラグのみで管理している。

## 新規称号追加方法

1. [CavivaraReward](../../../client/lib/ui/feature/stats/cavivara_reward.dart) に新しい enum 値を追加（`threshold`、`displayName`、`conditionDescription` を指定）
2. [PreferenceKey](../../../client/lib/data/model/preference_key.dart) に新しい獲得フラグ用のキーを追加（例: `hasEarnedNewReward`）
3. 新しい `HasEarnedXxxRewardRepository` を作成（既存のリポジトリを参考にする）
4. [AwardReceivedChatString](../../../client/lib/ui/feature/home/home_presenter.dart#L210) の `_checkIfRewardEarned()` と `_markRewardAsEarned()` に新しい称号のケースを追加
5. [UserStatisticsScreen](../../../client/lib/ui/feature/stats/user_statistics_screen.dart) は `CavivaraReward.values` を使用しているため、自動的に新しい称号が表示される

## 設計ポイント

- **重複通知防止**: `hasEarnedXxxReward` フラグで獲得済み称号を記録し、同じ称号の重複通知を防止。アプリ再起動後も状態は保持される。
- **自動的な称号検出**: `AwardReceivedChatString` が Riverpod の `ref.listen` を使用して受信文字数の変化を自動監視。新規達成時のみ通知を表示。
- **文字数カウント**: `characters` パッケージで Unicode 文字（絵文字やサロゲートペアを含む）を正確にカウント。
- **シンプルな状態管理**: 各称号の獲得状態は個別のリポジトリで管理。新規称号追加時の影響範囲を最小化。
- **UI の自動更新**: `UserStatisticsScreen` は `CavivaraReward.values` を使用しているため、enum に追加するだけで自動的に新規称号が表示される。

## 関連ファイル

### モデル・定義
- [client/lib/ui/feature/stats/cavivara_reward.dart](../../../client/lib/ui/feature/stats/cavivara_reward.dart): 称号の定義と達成判定ロジック
- [client/lib/data/model/preference_key.dart](../../../client/lib/data/model/preference_key.dart): SharedPreferences のキー定義

### リポジトリ
- [client/lib/data/repository/has_earned_part_timer_reward_repository.dart](../../../client/lib/data/repository/has_earned_part_timer_reward_repository.dart): アルバイト称号の獲得状態管理
- [client/lib/data/repository/has_earned_part_time_leader_reward_repository.dart](../../../client/lib/data/repository/has_earned_part_time_leader_reward_repository.dart): リーダー称号の獲得状態管理
- [client/lib/data/repository/received_chat_string_count_repository.dart](../../../client/lib/data/repository/received_chat_string_count_repository.dart): 総受信文字数の管理
- [client/lib/data/repository/sent_chat_string_count_repository.dart](../../../client/lib/data/repository/sent_chat_string_count_repository.dart): 総送信文字数の管理

### プレゼンテーション
- [client/lib/ui/feature/home/home_presenter.dart](../../../client/lib/ui/feature/home/home_presenter.dart): チャット送受信と称号獲得通知のロジック
- [client/lib/ui/component/heads_up_notification_presenter.dart](../../../client/lib/ui/component/heads_up_notification_presenter.dart): 通知表示の状態管理
- [client/lib/ui/feature/stats/user_statistics_screen.dart](../../../client/lib/ui/feature/stats/user_statistics_screen.dart): 業績画面UI
