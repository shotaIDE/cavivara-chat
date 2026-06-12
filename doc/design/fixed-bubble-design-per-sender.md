# 送信者別の吹き出しデザイン固定化 技術設計書

## 目的

チャット（トーク）画面の吹き出しデザインを、ユーザーが選択する方式から、送信者ごとに固定する方式へ変更する。

- カヴィヴァラさん(AI)の発言: **猫毛様式 (catFur)** — 毛並みのバブル
- ユーザーおよびアプリ(システム)の発言: **社内標準様式 (corporateStandard)**

これに伴い、吹き出しデザインを切り替える設定機能を廃止する。

## 背景

従来は `ChatBubbleDesign`（社内標準/次世代/調整済/猫毛）を設定画面から選択し、全送信者の吹き出しに一律適用していた。
本変更で「カヴィヴァラさんだけ毛並み、それ以外は社内標準」という固定の表現に統一するため、ユーザー選択は不要となった。

## 変更内容

### 廃止したもの

| レイヤー | コンポーネント | 内容 |
|---------|-------------|------|
| UI | `ChatBubbleDesignSelectionDialog` | デザイン選択ダイアログを削除 |
| UI | `SettingsScreen` の「表示設定」セクション・`_ChatBubbleDesignTile` | 設定項目を削除 |
| UI | `HarmonizedBubbleClipper` | 調整済様式専用クリッパーを削除（到達不能なため） |
| Repository | `ChatBubbleDesignRepository` | 永続化リポジトリを削除 |
| Data | `PreferenceKey.chatBubbleDesign` | 永続化キーを削除 |
| Model | `ChatBubbleDesign` の `nextGeneration` / `harmonized` | 未使用となった値を削除 |

### 残したもの

- `ChatBubbleDesign` enum（`corporateStandard` と `catFur` の 2 値）
- `ChatBubbleDesignExtension.buildBubble` / `shouldWithPointer` / `displayName`
- `CatFurBubblePainter`（猫毛様式の描画）

## 表示ロジック

`HomeScreen` の各吹き出しウィジェットで、送信者に応じてデザインを固定する。

| 送信者 | ウィジェット | デザイン | ポインター |
|--------|------------|---------|-----------|
| AI | `_AiChatBubble` | `catFur` | なし |
| ユーザー | `_UserChatBubble` | `corporateStandard` | 右向きあり |
| アプリ | `_AppChatBubble` | `corporateStandard` | なし |

メッセージ間の縦余白は、毛先がはみ出す AI(猫毛様式)のみ広め(16pt)、その他は 8pt とする。

## 関連ドキュメント

- [switch-design.md](./switch-design.md): 廃止したデザイン切り替え機能の設計
- [cat-fur-bubble-design.md](./cat-fur-bubble-design.md): 猫毛様式の描画設計
- [harmonized-bubble-design.md](./harmonized-bubble-design.md): 廃止した調整済様式の設計
- [bubble-tail-removal.md](./bubble-tail-removal.md): 次世代様式（ツノ排除）の設計
