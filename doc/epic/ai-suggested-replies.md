---
name: Feature Epic
about: Template for large feature development (parent issue)
title: "[Epic] AIからの返答後に次の質問候補をボタン表示する機能"
labels: ["epic"]
assignees: ""
---

## Overview

AI からの返答表示時に、ユーザーが次に送信しそうな質問や返答を予測し、画面にボタンとして表示する機能を追加する。これにより、ユーザーは提案されたボタンをタップするだけで次のメッセージを送信できるようになり、対話がよりスムーズになる。

### Background and Purpose

**背景:**

- 現在、チャット開始時には静的な質問例が表示されているが、会話が始まった後は手動でテキスト入力する必要がある
- ユーザーが次に何を聞けばよいか迷う場合がある
- モバイルデバイスでのテキスト入力は煩わしい場合がある

**解決したい課題:**

- ユーザーの対話体験を向上させ、会話を継続しやすくする
- テキスト入力の手間を減らし、よりスムーズな対話フローを実現する
- AI が文脈を理解した上で適切な次の質問を提案することで、対話の質を向上させる

### Expected Impact

- ユーザーのメッセージ送信率の向上（特に 2 往復目以降の会話継続率）
- 平均対話ターン数の増加
- テキスト入力による摩擦の軽減

### Feature Description

AI がメッセージを送信した直後に、会話の文脈を分析して次に予想される質問や返答を 3〜5 個生成し、チャット画面の下部にボタンとして表示する。ユーザーがボタンをタップすると、その内容がメッセージとして送信される。

**主要な機能要件:**

1. AI の返答完了時に、文脈に基づいて次の質問候補を自動生成
2. 生成された候補を横スクロール可能なボタンとして表示
3. ボタンタップで即座にメッセージとして送信
4. 候補生成中はローディング状態を表示
5. 生成エラー時は候補は非表示

## User Stories

- As a ユーザー, I want AI の返答後に関連する質問候補が表示される so that 次に何を聞けばよいかわかり、スムーズに会話を続けられる
- As a ユーザー, I want 候補ボタンをタップするだけでメッセージを送信できる so that テキスト入力の手間を省いて素早く返信できる
- As a ユーザー, I want 複数の質問候補から選択できる so that 自分の興味に合った方向で会話を展開できる
- As a 開発者, I want 候補生成ロジックを AI 側に持たせる so that 文脈を考慮した高品質な候補を生成できる

## Implement Issue List

このエピックは、以下の3つのタスクで構成されます。Phase 1 と Phase 2 はそれぞれ独立した一つのタスクとして実装します。

### Task 1: Response Schema の変更（返答サジェスト対応の基盤整備）

**目的**: AI の返答と同時に返答サジェストを受け取れるように Response Schema を変更する。ただし、この段階では受け取ったサジェストを利用せず、内部的な構造変更のみを行う。

**実装内容**:

#### Frontend - Data Layer

**`AiResponse` モデルの実装**
- AI からの構造化された返答を表現する Freezed モデル
- `message` (String): AI の返答メッセージ
- `suggestedReplies` (List\<String\>): 返答サジェストのリスト（3〜5 個）
- JSON デシリアライゼーション対応

**`AiChatService` の Response Schema 対応**
- `GenerationConfig` に `responseSchema` を追加
- `responseMimeType` を `application/json` に設定
- JSON Schema の定義（`message` と `suggestedReplies` フィールド）
- `sendMessageStream` の返り値を `Stream<String>` から `Stream<AiResponse>` に変更
- ストリーミング中は `suggestedReplies` を空リストとして扱う

**`HomePresenter` の Response Schema 対応**
- `sendMessage` メソッドを `AiResponse` を受け取るように修正
- `message` フィールドのみを使用してチャットメッセージを更新（既存動作を維持）
- `suggestedReplies` は一旦無視する（Task 2 で利用）

#### Testing

**`AiResponse` モデルのユニットテスト**
- JSON デシリアライゼーションの検証
- 各フィールドの値の検証

**`AiChatService` の Response Schema 対応のユニットテスト**
- Response Schema が正しく設定されているか検証
- `Stream<AiResponse>` が正しく返されるか検証
- 既存のチャット機能が動作することを確認（リグレッションテスト）

**`HomePresenter` の統合テスト**
- 既存のチャット機能が正常に動作することを確認
- `suggestedReplies` を無視して正しくメッセージが表示されるか検証

---

### Task 2: 返答サジェスト機能の実装

**目的**: Task 1 で整備した `AiResponse` の `suggestedReplies` を利用して、画面に返答サジェストボタンを表示する機能を実装する。

**実装内容**:

#### Frontend - Data Layer

**`SuggestedReply` モデルの実装**
- `id` (String): 一意の識別子
- `text` (String): 表示テキスト
- Freezed モデルとして実装

**`SuggestionCacheRepository` の実装**
- メモリ内キャッシュによる候補の一時保存
- セッションごと（`cavivaraId` ごと）のキャッシュ管理
- キャッシュのクリア機能

#### Frontend - UI Layer

**`SuggestedReplyButton` Component の実装**
- Atomic Design の organisms レベルのコンポーネント
- タップ時のフィードバックアニメーション
- アクセシビリティ対応（Semantics ウィジェット）
- カヴィヴァラのデザインに合ったスタイリング

**`SuggestedReplyList` Component の実装**
- 横スクロール可能なボタンリスト（ListView.separated）
- フェードインアニメーション
- 空状態の処理（候補がない場合は非表示）

**`HomePresenter` の返答サジェスト対応**
- `AiResponse` の `suggestedReplies` を `SuggestionCacheRepository` に保存
- 候補取得用の Provider (`currentSuggestionsProvider`) を追加
- 候補選択時のメッセージ送信ロジック
- メッセージ送信時に古い候補をクリア

**`HomeScreen` の UI 更新**
- AI 返答完了後に `SuggestedReplyList` を表示
- メッセージ入力エリアとサジェストエリアのレイアウト調整
- 画面スクロール時の候補表示の調整

#### Testing

**`SuggestedReply` モデルのユニットテスト**
- Freezed モデルの基本機能検証

**`SuggestionCacheRepository` のユニットテスト**
- 保存・取得・クリア機能の検証
- セッションごとの分離が正しく動作するか検証

**`SuggestedReplyButton` のウィジェットテスト**
- タップ動作の検証
- アクセシビリティの検証
- アニメーションの検証

**`SuggestedReplyList` のウィジェットテスト**
- 横スクロールの検証
- 空状態の検証
- アニメーションの検証

**`HomePresenter` の統合テスト**
- 返答サジェスト表示フローの End-to-End テスト
- 候補選択時のメッセージ送信が正しく動作するか検証
- モックを使用したテスト

---

### Task 3: ドキュメント整備

**目的**: 実装した機能の技術仕様と要件を文書化する。

**実装内容**:

**技術設計ドキュメントの作成**
- `doc/design/suggested-replies-feature.md` の作成
- Response Schema 仕様、データモデル、UI/UX フローの詳細
- Task 1 と Task 2 の実装詳細

**要件定義ドキュメントの更新**
- `doc/requirement/chat-feature.md` への機能追加
