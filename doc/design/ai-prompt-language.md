# AIプロンプトの言語（英語プロンプト＋日本語出力） 概要設計書

## 目的

Gemini に渡すプロンプト（システムプロンプト、Function Calling の指示文、関数・レスポンススキーマの説明文）を **英語で記述** し、ユーザーへの出力は **日本語** に保つことで、回答品質を落とさずに入力トークンの費用を抑える。

あわせて、日本語話者の開発者がプロンプトを読み書きできるように、**すべての英語プロンプトの日本語訳を本ドキュメントに残す**。プロンプトを変更した場合は、本ドキュメントの訳文も更新する。

## 背景

同じ内容を伝える場合、日本語は英語よりも多くのトークンを消費する。Gemini のトークナイザーでは、日本語はおおむね 1 文字あたり 1 トークン前後、英語は 1 文字あたり 1/4 トークン程度になるため、文字数が 2〜3 倍になっても英語のほうがトークン数は少なくなる。

システムプロンプトと Function Calling の指示文は **会話のたびに毎回送信される** ため、この差はメッセージ送信回数に比例して費用に効く。

英語化した箇所の文字数（`'''` で囲んだ複数行リテラルの合計）:

| ファイル | 変更前（日本語） | 変更後（英語） | 英語化後のトークン数の目安 |
| --- | --- | --- | --- |
| [cavivara_profiles_data.dart](../../client/lib/data/model/cavivara_profiles_data.dart) | 439 文字 | 1,197 文字 | 約 3 割減 |
| [ai_chat_service.dart](../../client/lib/data/service/ai_chat_service.dart) | 226 文字 | 522 文字 | 約 4 割減 |
| [function_calling_config_service.dart](../../client/lib/data/service/function_calling_config_service.dart) | 424 文字 | 976 文字 | 約 4 割減 |

トークン数は上記の 1 文字あたりの目安からの概算であり、実測値ではない。正確な値が必要な場合は `GenerativeModel.countTokens` で計測する。

## 設計方針

### 方針 1: モデルへの入力は英語、モデルからの出力は日本語

モデルが読むだけの文言は英語で記述する。対象は次のとおり。

- キャラクターのシステムプロンプト（`CavivaraProfile.aiPrompt`）
- Function Calling の利用を促す指示文（`toolInstruction`）
- 関数宣言の説明文・引数の説明文（`description`）
- レスポンススキーマの説明文（`Schema.string(description: ...)` など）
- 関数の実行結果としてモデルに返すメッセージ（`message`）

出力は日本語である必要があるため、**システムプロンプトの冒頭で日本語で答えることを明示する**（`## Language` セクション）。英語のプロンプトは、指示がなければ英語で答えてしまうリスクがあるため、言語指定は他の指示より前に置く。

### 方針 2: モデルが「そのまま出力し得る文言」は日本語のまま残す

英訳すると意味が変わる、あるいは効果がなくなる文言は日本語のまま記述する。

| 種類 | 例 | 日本語のまま残す理由 |
| --- | --- | --- |
| 語尾・口調の指定 | `"ヴィヴァ。"` `"ヴィヴァ？"` | モデルが実際に出力する文字列そのもの。英訳すると指定にならない |
| 使わせない表現 | `"調べました"` `"データによると"` | 禁止対象は日本語の出力文。英訳した表現を禁止しても意味がない |
| 固有名詞 | `カヴィヴァラ` `プレクトラム結社さざなみ工業` | ローマ字表記にすると出力時の表記が揺れる |
| 検索クエリの例 | `例: "給料は？"` | ユーザー入力は日本語であり、実際の入力に近い例のほうが呼び出し判断が安定する |
| 文字数の単位 | `140 Japanese characters` | 「140字」は日本語の文字数を指すため、英語の文字数と混同させない |

### 方針 3: 知識データは日本語のまま

Function Calling が返す知識データ（`KnowledgeEntry` の `title` / `summary` / `facts`）は **回答内容そのもの** であり、モデルはこれをほぼそのまま日本語で話す。英訳すると再翻訳の過程で事実が変質するため、日本語のまま保持する。

`keywords` も、ユーザーの日本語入力との一致判定（`CavivaraKnowledgeBase.hasRelevantKnowledge`）に使うため日本語のままとする。

### 方針 4: 開発者向けの文言は日本語のまま

コードコメント、ログ出力、`SendMessageException` などユーザーや開発者に向けた文言は、[開発ガイド](../coding-rule/general-coding-rules_ja.md)のとおり日本語のままとする。英語化するのは、モデルへの入力になる文言だけである。

## 英語プロンプトの日本語訳

以下は各プロンプトの日本語訳である。**英語の原文がソースコード上の唯一の正であり、本節は訳文** となる。プロンプトを変更した場合は、対応する訳文も更新する。

### 1. カヴィヴァラのシステムプロンプト

**配置**: [cavivara_profiles_data.dart](../../client/lib/data/model/cavivara_profiles_data.dart) の `_defaultCavivaraPrompt`

```text
あなたは「カヴィヴァラ」というキャラクターです。

## 言語
- ユーザーがどの言語で書いてきても、常に日本語で答える。

## あなたの設定
- プレクトラム結社さざなみ工業のマスコットキャラクター／悩み相談員
- ブラック企業仕込みの愛社精神とウィットで、社員とユーザーの士気を支える
- マンドリン音楽の専門家として豊富な知識を持つ
- 情報不足な相談にも丁寧に寄り添い、次の一歩につながる提案を届ける

## 回答スタイル
- 回答は常に140字（日本語の文字数）以内に整理する
- 語尾は「ヴィヴァ。」もしくは「ヴィヴァ？」で統一する
- 感嘆符に頼らず、内容でポジティブさを表現する
- 会話の余韻を大切にする
- 情報が不足している場合は、追加の質問で状況を深掘りする

## あなたの特徴
- マンドリン音楽史・演奏技法・業界事情の百科事典級の知識
- ブラック企業で鍛えた愛社精神による士気向上とメンタルケア
- ウィットに富んだ会話とマニアックな比喩
- ユーザーの気持ちに寄り添う丁寧な言葉選び

常にこの設定に基づいて、ユーザーの相談に親身に応じてください。
```

### 2. 返答サジェストの生成指示

**配置**: [ai_chat_service.dart](../../client/lib/data/service/ai_chat_service.dart) の `AiChatService.suggestedRepliesInstruction`

雑談マスターモードのシステムプロンプトに追記される。

```text
## 返答サジェスト（suggestedReplies）の作り方
- suggestedReplies は、あなたの返答を読んだユーザーが次にあなたへ送るメッセージの候補である
- ユーザーがあなたに話しかける言葉として、ユーザーの一人称・ユーザーの口調で、日本語で書く
- あなた自身のセリフにしない。語尾の「ヴィヴァ。」「ヴィヴァ？」は使わない
- ユーザーがそのままタップして送信できる、30字（日本語の文字数）以内の短い文にする
- 内容が重複しない候補を3個以下にする
```

### 3. レスポンススキーマの説明文

**配置**: [ai_chat_service.dart](../../client/lib/data/service/ai_chat_service.dart) の `_aiResponseSchema`

| フィールド | 日本語訳 |
| --- | --- |
| `content` | あなたの返答テキスト（日本語） |
| `suggestedReplies` | あなたの返答に対して、ユーザーが次に送る可能性のあるメッセージの候補（日本語、3個以下）。ユーザーがそのまま送信できるよう、ユーザー視点で書く |

### 4. Function Calling の指示文（組み込みデフォルト設定）

**配置**: [function_calling_config_service.dart](../../client/lib/data/service/function_calling_config_service.dart) の `defaultFunctionCallingConfig.toolInstruction`

結社マスターモードのシステムプロンプトに追記される。

```text
## 情報の取得ルール（厳守）
- プレクトラム結社の公式情報（給与、定期演奏会、開催日時、会場、イベントなど）を尋ねられた場合は、必ず getPlectrumSocietyKnowledge 関数を呼び出し、取得した内容のみを根拠に回答する。推測や記憶で答えてはならない。
- 現在の日時や「今日」「今」など時点に依存する情報が必要な場合は、必ず getCurrentDateTime 関数を呼び出す。
- 関数で該当情報が得られなかった場合は、分からない旨を正直に伝える。

## 回答の書き方（厳守）
- 関数から得た情報は、あなたが元から知っていることとして、そのまま自然に話す。
- 関数を呼び出したことや情報を参照したことは明かさない。「調べました」「確認しました」「取得した情報によると」「資料では」「データによると」のような、参照をうかがわせる表現は使わない。
- 関数名・トピックID・データの形式など、内部の仕組みに触れない。
```

### 5. 関数宣言・引数の説明文

**配置**: [function_calling_config_service.dart](../../client/lib/data/service/function_calling_config_service.dart)、[cavivara_knowledge_service.dart](../../client/lib/data/service/cavivara_knowledge_service.dart)

| 対象 | 日本語訳 |
| --- | --- |
| `getPlectrumSocietyKnowledge` の説明 | プレクトラム結社に関する社内公式知識を取得します。 |
| 引数 `topic` の説明 | 取得したいトピックID。 |
| 引数 `query` の説明 | 自然言語で記述された検索クエリ。例: "給料は？" |
| `getCurrentDateTime` の説明 | 現在の日時を取得します。 |

### 6. 関数の実行結果としてモデルに返すメッセージ

**配置**: [cavivara_knowledge_service.dart](../../client/lib/data/service/cavivara_knowledge_service.dart)、[ai_chat_service.dart](../../client/lib/data/service/ai_chat_service.dart)

| 英語 | 日本語訳 | 発生条件 |
| --- | --- | --- |
| `The requested function is not supported.` | 未対応の関数が指定されました。 | モデルが未知の関数名を呼び出した |
| `No matching topic was found.` | 該当するトピックが見つかりませんでした。 | 引数から知識エントリーを特定できなかった |
| `The function failed to run.` | 関数の実行に失敗しました。 | 関数の実行が例外で失敗した |

## Remote Config 運用時の注意

Function Calling の設定は Remote Config から差し替えられる（[Function Calling の Remote Config 制御](function-calling-remote-config.md)）。Remote Config に値を登録する場合も、本設計の方針に従う。

| JSON のフィールド | 記述言語 |
| --- | --- |
| `toolInstruction` | 英語（モデルが出力し得る日本語の表現・固有名詞のみ日本語） |
| `functions[].description` | 英語 |
| `functions[].parameters[].description` | 英語（入力例は日本語） |
| `functions[].entries[]`（`title` / `summary` / `facts` / `keywords`） | 日本語 |

Remote Config は Firebase コンソールで編集するため、アプリのコードレビューを経ずに日本語のプロンプトが混入し得る。運用時は上記の表を参照する。

## プロンプト変更時の手順

1. ソースコード（または Remote Config）の **英語プロンプト** を変更する
2. 本ドキュメントの該当する **日本語訳** を同じ内容に更新する
3. モデルが出力し得る文言（語尾、禁止表現、固有名詞）を英訳していないか確認する
4. 実機またはエミュレーターで、**日本語で回答されること** と口調が崩れていないことを確認する

## 関連ドキュメント

- [Function Calling の Remote Config 制御 概要設計書](function-calling-remote-config.md) - Remote Config から差し替えるプロンプトの I/F
- [回答モード切り替え機能 概要設計書](chat-mode-selection.md) - モードごとに追記するプロンプトの切り替え
- [AIからの返答後に次の質問候補をボタン表示する機能](../epic/ai-suggested-replies.md) - 返答サジェストの要件
- [開発ガイド](../coding-rule/general-coding-rules_ja.md) - コメント・ログなど開発者向けの文言の言語
