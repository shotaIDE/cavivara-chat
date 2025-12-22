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

### Task 1: Response Schema の変更（返答サジェスト対応の基盤整備）

AI の返答と同時に返答サジェストを受け取れるように Response Schema を変更する。この段階では受け取ったサジェストを利用せず、内部的な構造変更のみを行う。

- `AiResponse` モデルの実装
- `AiChatService` の Response Schema 対応
- `HomePresenter` の Response Schema 対応
- ユニットテスト・統合テストの実装

### Task 2: 返答サジェスト機能の実装

Task 1 で整備した `AiResponse` の `suggestedReplies` を利用して、画面に返答サジェストボタンを表示する機能を実装する。

- `SuggestedReply` モデルの実装
- `SuggestionCacheRepository` の実装
- `SuggestedReplyButton` Component の実装
- `SuggestedReplyList` Component の実装
- `HomePresenter` の返答サジェスト対応
- `HomeScreen` の UI 更新
- ユニットテスト・ウィジェットテスト・統合テストの実装

### Task 3: ドキュメント整備

実装した機能の技術仕様と要件を文書化する。

- 技術設計ドキュメントの作成（`doc/design/suggested-replies-feature.md`）
- 要件定義ドキュメントの更新（`doc/requirement/chat-feature.md`）
