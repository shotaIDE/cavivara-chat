# 回答モード切り替え機能（結社マスターモード／雑談マスターモード）概要設計書

## 目的

カヴィヴァラの回答モードを「結社マスターモード（Function Calling を利用し、結社の演奏会情報などを回答する）」と「雑談マスターモード（返信サジェストを付与して雑談する）」から選択できる機能の技術的な設計概要を示す。

Gemini API は Function Calling とレスポンススキーマ（構造化出力）を同一リクエストで併用できないため、これら 2 つの回答方式は排他的に切り替える必要がある。

## アーキテクチャ

### レイヤー構成

本機能は以下の層で実装する：

1. **UI Layer** - ユーザーインターフェース
   - チャット画面タイトル下のモードインジケーター（HomeScreen 内）
   - モード選択ダイアログ（ChatModeSelectionDialog）

2. **Presenter Layer** - 状態管理・判定ロジック
   - `ChatMessages`（送信時のモード解決）
   - `ResolvedChatMode`（自動選択モードでの会話中の判定結果保持）

3. **Repository Layer** - データ永続化
   - `ChatModeSelectionRepository`

4. **Service Layer** - Gemini API 呼び出し
   - `AiChatService`（モードに応じたモデル設定の切り替え）
   - `CavivaraKnowledgeBase`（自動選択判定のための知識ベース参照）

5. **Data Layer** - ストレージ
   - SharedPreferences

## 主要コンポーネント

### 1. ChatMode（ドメインモデル）

**配置**: `client/lib/data/model/chat_mode.dart`

**役割**: 実際にAIへの問い合わせで使用する回答モードを表す enum

**内容**:

- `plectrumSocietyMaster`: Function Calling でプレクトラム結社の知識を参照して回答するモード
- `chitChatMaster`: 返信サジェストを付与して雑談する回答をするモード

### 2. ChatModeSelection（ドメインモデル）

**配置**: `client/lib/data/model/chat_mode_selection.dart`

**役割**: ユーザーが選択した「モードの決め方」を表す sealed freezed クラス

**内容**:

- `ChatModeSelection.auto()`: 会話内容に応じて自動的に `ChatMode` を判定する
- `ChatModeSelection.fixed(ChatMode mode)`: 常に指定した `ChatMode` を使用する

### 3. ChatModeExtension（UI 拡張）

**配置**: `client/lib/ui/component/chat_mode_extension.dart`

**役割**: `ChatMode` に表示名・短いラベル・説明文などの UI 関連プロパティを付与する

### 4. ChatModeSelectionRepository（永続化）

**配置**: `client/lib/data/repository/chat_mode_selection_repository.dart`

**役割**: モード選択設定の読み込みと保存

- `build()`: SharedPreferences から設定を読み込み、未設定の場合は自動選択をデフォルトとする
- `save(selection)`: 選択された `ChatModeSelection` を SharedPreferences に保存（`auto` または `ChatMode.name`）

### 5. ResolvedChatMode（会話中の判定結果保持）

**配置**: `client/lib/ui/feature/home/home_presenter.dart`

**役割**: 自動選択モードにおいて、会話中の最初のメッセージで判定した `ChatMode` を、チャットをクリアするまで保持する

Gemini API 側の制約上、同一会話中でレスポンススキーマと Function Calling を切り替えることはできないため、自動選択モードであっても会話単位でモードを固定する必要がある。

### 6. CavivaraKnowledgeBase.hasRelevantKnowledge（自動選択の判定材料）

**配置**: `client/lib/data/service/cavivara_knowledge_service.dart`

**役割**: 入力文言が結社の知識ベースのキーワードに合致するかどうかを判定する。既存の Function Calling 用知識エントリ（`_entries`）のキーワード一致ロジックを再利用し、自動選択モードでの初回メッセージの判定に使用する。

### 7. AiChatService のモード対応

**配置**: `client/lib/data/service/ai_chat_service.dart`

**変更内容**:

- `sendMessageStream` / `_getModel` / `_createOrReuseChatSession` / `_processResponseStream` / `_handleFunctionCall` に `ChatMode mode` パラメーターを追加
- `_getModel`: `mode` に応じて `responseSchema`（雑談マスターモード）または `tools`（結社マスターモード）のどちらか一方のみを `GenerativeModel` に設定する
- `_processResponseStream`: `plectrumSocietyMaster` の場合はプレーンテキストのレスポンスをチャンクごとにそのまま送出し、`chitChatMaster` の場合は従来通り JSON をバッファしてパースする
- チャットセッションのキャッシュキーに `mode` を含め、同じ `systemPrompt` でもモードごとに別セッションとして扱う

### 8. チャット画面のモードインジケーター・選択ダイアログ

**配置**: `client/lib/ui/feature/home/home_screen.dart`, `client/lib/ui/component/chat_mode_selection_dialog.dart`

**内容**:

- チャット画面タイトル（カヴィヴァラの表示名）の下に、現在の回答モードを示す小さなラベルを表示
- ラベルをタップすると `ChatModeSelectionDialog` を表示し、「自動選択」「結社マスターモード」「雑談マスターモード」を `RadioListTile` で選択できる
- 選択を保存すると、自動選択の判定結果（`ResolvedChatMode`）をリセットし、次のメッセージから改めて判定できるようにする

## データフロー

### メッセージ送信時

1. `ChatModeSelectionRepository` から現在の選択（自動選択または固定モード）を取得
2. 固定モードの場合はそのモードを使用
3. 自動選択の場合、`ResolvedChatMode` に判定済みの値があればそれを使用し、なければ `CavivaraKnowledgeBase.hasRelevantKnowledge` で文言を判定し、結果を `ResolvedChatMode` に保持
4. 解決した `ChatMode` を `AiChatService.sendMessageStream` に渡す

### チャットクリア時

1. メッセージ一覧をクリア
2. `ResolvedChatMode` をリセット（次回会話の初回メッセージで再判定できるようにする）
3. `AiChatService.clearChatSession` で全 `ChatMode` 分のセッションキャッシュをクリア

## 関連ドキュメント

- [チャット吹き出しデザイン切り替え機能 概要設計書](switch-design.md) - モード選択ダイアログの実装パターンの参考
- [AIからの返答後に次の質問候補をボタン表示する機能](../epic/ai-suggested-replies.md) - 雑談マスターモードで使用する返信サジェストの実装
- [AIプロンプトの言語（英語プロンプト＋日本語出力）概要設計書](ai-prompt-language.md) - モードごとに追記するプロンプトの記述言語と、日本語訳
- [SharedPreferences 使用時の設計方法](../how-to-design-when-using-shared-preferences.md)
