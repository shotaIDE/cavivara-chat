<!-- cspell:ignore hitomi mocktail -->

# Function Calling の Remote Config 制御 概要設計書

## 目的

結社マスターモード（[回答モード切り替え機能](chat-mode-selection.md)）で使用している Function Calling の内容を、アプリのリリースなしに Firebase Remote Config から更新できるようにする。

現状、以下がすべて Dart のソースコードにハードコードされているため、演奏会情報の追加・修正のたびにアプリのリリースが必要になっている。

- モデルに提供する関数宣言（[cavivara_knowledge_service.dart](../../client/lib/data/service/cavivara_knowledge_service.dart) の `_buildKnowledgeFunctionDeclaration`）
- 関数が返す知識データ（同ファイルの `_entries`）
- Function Calling の利用を促すシステムプロンプト追記（[ai_chat_service.dart](../../client/lib/data/service/ai_chat_service.dart) の `_plectrumSocietyToolInstruction`）

本設計では、このうち **アプリ側の実装追加なしに変更可能な範囲** を Remote Config に切り出す I/F を定義する。

## 設計方針

### 方針 1: 「関数の宣言・データ」は Remote Config、「関数の実行処理」はアプリ

Function Calling は、モデルが呼び出しを要求した関数をアプリ側が実際に実行する必要がある。任意の処理を Remote Config から注入することはできない（できるようにすべきでもない）ため、関数を次の 2 種類に整理する。

| 種別 | 説明 | Remote Config で変更できるもの |
| --- | --- | --- |
| データ駆動関数 | アプリに汎用の実行処理（ハンドラー）があり、応答内容が Remote Config のデータで決まる関数。例: `getPlectrumSocietyKnowledge` | 関数の有効・無効、関数名、説明文、引数定義、**応答データそのもの** |
| 組み込み関数 | 端末やアプリの状態を参照するため、宣言も実装もアプリに固定される関数。例: `getCurrentDateTime` | なし（Remote Config の対象外） |

データ駆動関数の定義には、アプリ側のどの実行処理を使うかを示す `handler` を持たせる。アプリは `handler` の識別子と実装の対応表を持ち、**未知の `handler` はその関数ごと無視する**（新しい種別の関数を追加する場合は、`handler` の実装追加＝アプリのリリースが必要になる）。

一方、組み込み関数は Remote Config の JSON には一切現れず、アプリが常に固定の宣言でモデルに提供する。`getCurrentDateTime` は引数を持たず、応答は端末時刻から機械的に決まるため、リモートから変更できるのは説明文だけになる。それだけのために設定項目とバリデーションを増やしても、運用で得られるものが「誤設定で日時が取得できなくなるリスク」に見合わない。組み込み関数は Remote Config の設定内容にかかわらず常に有効であり、結果として **モデルに提供される関数が 0 件になることはない**。

### 方針 2: 1 つの JSON パラメーターに集約する

関数宣言・知識データ・システムプロンプト追記は互いに整合していないと成立しない（例: 知識エントリーを追加したのに関数の説明文が古い）。Remote Config のパラメーターを複数に分けると、公開順によって不整合な組み合わせが端末に届き得る。

そのため、**1 つの JSON 型パラメーターにまとめ、常に一括で公開する**。パラメーター更新イベント（`onConfigUpdated`）も 1 回にまとまるため、アプリ側の扱いも単純になる。

### 方針 3: フォールバックで、壊れた設定でも会話を継続する

Remote Config は運用でのミス（JSON の構文エラー、必須項目の欠落）が起こり得る。Function Calling が壊れると結社マスターモードの回答品質が直接落ちるため、次の優先順で値を解決する。

1. Remote Config から取得・有効化済みの値
2. （1 が未設定・パース不能・スキーマ非対応の場合、および Firebase が初期化されておらず値を取得できない場合）アプリに埋め込んだ組み込みデフォルト設定

組み込みデフォルト設定には、現在ハードコードされている内容をそのまま移植する。これにより、Remote Config 未設定の環境（ローカル開発、Firebase 初期化失敗時、エミュレーター Suite）でも従来と同じ挙動になる。

データ駆動関数が 1 件も有効にならなかった場合でも、組み込み関数は常に提供されるため Function Calling そのものは機能する。この場合、結社の知識は参照できないが、`toolInstruction` の「関数で該当情報が得られなかった場合は、分からない旨を正直に伝える」という指示によって、モデルが記憶で答えてしまう事態を避けられる。

## Remote Config I/F 仕様

### パラメーター

| 項目 | 値 |
| --- | --- |
| パラメーターキー | `functionCallingConfig` |
| データ型 | JSON |
| 既定値（Remote Config 側） | 設定しない（アプリ側の組み込みデフォルトにフォールバックさせる） |
| 想定サイズ | 数十 KB 以内（Remote Config のパラメーター値上限は[公式ドキュメント](https://firebase.google.com/docs/remote-config/parameters)の割り当てと制限を参照。フェッチ時間への影響を避けるため、上限に対して十分小さく保つ） |

キー名は既存の `minimumBuildNumber` / `showDebugFeatureOnProdRelease` と同じ camelCase に揃える。

### JSON スキーマ

#### ルート

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `schemaVersion` | int | ○ | この JSON の構造バージョン。現行は `1` |
| `toolInstruction` | string | - | 結社マスターモードのシステムプロンプトに追記する、Function Calling の利用を促す指示文。空行を挟んで追記されるため、先頭の改行は不要。未指定時は追記なし |
| `functions` | array\<Function\> | ○ | モデルに提供するデータ駆動関数の定義リスト。組み込み関数（`getCurrentDateTime`）は含めない |

#### Function

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `name` | string | ○ | モデルに提示する関数名。`^[a-zA-Z_][a-zA-Z0-9_]{0,63}$`。組み込み関数の名前（`getCurrentDateTime`）は予約済みで使用できない |
| `handler` | string | ○ | アプリ側の実行処理の識別子。現行は `knowledgeLookup` のみ |
| `description` | string | ○ | モデルが呼び出し判断に使う関数の説明 |
| `enabled` | bool | - | `false` の場合はモデルに提供しない。既定値 `true` |
| `parameters` | array\<Parameter\> | - | 関数の引数定義。未指定時は引数なし |
| `entries` | array\<KnowledgeEntry\> | △ | この関数が返す項目一覧。`handler` が `knowledgeLookup` の場合は必須 |

**`entries` は関数定義の中に持たせる（トップレベルで共有しない）**。`knowledgeLookup` ハンドラーの関数は複数定義できるため、項目一覧を全関数で共有すると、関数を分けても同じデータしか返せず、関数を分ける意味がなくなる。項目一覧を関数の中に置くことで、次のような分割ができる。

- `getPlectrumSocietyEventKnowledge`（演奏会・イベント情報）と `getPlectrumSocietySystemKnowledge`（給与などの制度）を別関数にし、それぞれの `description` でモデルの呼び分けを誘導する
- トピック ID の名前空間が関数ごとに独立するため、別の関数で同じ `topic` を使っても衝突しない
- 該当トピックが見つからなかった際の応答に含める `availableTopics` を、**その関数の項目一覧のみ**にできる（無関係なトピック ID をモデルに提示せずに済む）

#### Parameter

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `name` | string | ○ | 引数名 |
| `type` | string | ○ | `string` \| `integer` \| `number` \| `boolean` \| `stringArray` |
| `description` | string | ○ | 引数の説明 |
| `required` | bool | - | `false` の場合は任意引数として宣言する。既定値 `false` |
| `enumValues` | array\<string\> | - | `type` が `string` の場合のみ有効。列挙値を制限する |

`type` は `Schema.string` / `Schema.integer` / `Schema.number` / `Schema.boolean` / `Schema.array(items: Schema.string())` に 1 対 1 で対応させる。ネストしたオブジェクト型は対応しない（[非対応事項](#非対応事項)参照）。

#### KnowledgeEntry

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `topic` | string | ○ | トピック ID。関数の `topic` 引数と突き合わせる。同一関数内で一意であればよい |
| `title` | string | ○ | トピックの表示名 |
| `summary` | string | ○ | 要約。関数応答の `summary` に入る |
| `facts` | array\<string\> | ○ | 事実のリスト。関数応答の `facts` に入る。空リストは不可 |
| `keywords` | array\<string\> | - | 自然言語クエリとの一致判定、および自動選択モードの判定に使うキーワード。未指定の場合はトピックIDの指定でのみ参照される |

`keywords` は Function Calling の引数解決だけでなく、自動選択モードで結社マスターモードを選ぶ判定（`CavivaraKnowledgeBase.hasRelevantKnowledge`）にも使われる。この判定は**全関数の項目一覧を横断して**行う（「結社の知識に関係する発話か」という判定であり、どの関数で答えるかは判定時点では決める必要がないため）。Remote Config でキーワードを増やすと自動選択の挙動も変わる点を運用時に留意する。

### 設定例

Remote Config に設定する内容の例。`getCurrentDateTime` は組み込み関数のため `functions` には現れないが、`toolInstruction` からは（アプリが固定の名前で常に提供するため）参照してよい。

**組み込みデフォルト設定にはこのうち給与制度の項目のみを含める。** 定期演奏会のように開催のたびに更新される情報をアプリに埋め込むと、内容が古くなってもリリースするまで直せず、本機能の目的を損なう。組み込みデフォルト設定は「Remote Config が読めないときでも会話が成立する最小限の内容」に留め、更新頻度の高い情報は Remote Config だけで管理する。

`topic` と `query` を両方 `required` としているのは、現行のハードコードされた関数宣言が両方を必須として宣言しているためである（`Schema.object` は `optionalProperties` に挙げない引数を必須として扱う）。どちらか一方しか渡されなくてもアプリ側は解決できるため、任意に変更しても動作するが、既存の挙動を保つためデフォルト設定では必須のままとしている。

```json
{
  "schemaVersion": 1,
  "toolInstruction": "\n\n## 情報の取得ルール（厳守）\n- プレクトラム結社の公式情報（給与、定期演奏会、開催日時、会場、イベントなど）を尋ねられた場合は、必ず getPlectrumSocietyKnowledge 関数を呼び出して取得した内容のみを根拠に回答する。推測や記憶で答えてはならない。\n- 現在の日時や「今日」「今」など時点に依存する情報が必要な場合は、必ず getCurrentDateTime 関数を呼び出す。\n- 関数で該当情報が得られなかった場合は、分からない旨を正直に伝える。",
  "functions": [
    {
      "name": "getPlectrumSocietyKnowledge",
      "handler": "knowledgeLookup",
      "description": "プレクトラム結社に関する社内公式知識を取得します。",
      "parameters": [
        {
          "name": "topic",
          "type": "string",
          "description": "取得したいトピックID。",
          "required": true
        },
        {
          "name": "query",
          "type": "string",
          "description": "自然言語で記述された検索クエリ。例: \"給料は？\"",
          "required": true
        }
      ],
      "entries": [
        {
          "topic": "salary_policy",
          "title": "給与制度",
          "summary": "結社の給料は0円。毎年5%のベースアップが行われているが、元々0円のため昇給額も0円。",
          "facts": [
            "結社の給料は0円です。",
            "毎年5%のベースアップが実施されますが、もともとが0円のため昇給額も0円です。"
          ],
          "keywords": ["給料", "給与", "賃金", "報酬", "ベースアップ", "昇給", "0円"]
        },
        {
          "topic": "regular_concert_11",
          "title": "第11回定期演奏会",
          "summary": "プレクトラム結社の第11回定期演奏会は2026年9月12日(土)、メニコンANNEX HITOMIホールで開催予定。",
          "facts": [
            "イベント名: プレクトラム結社 第11回定期演奏会。",
            "開催日: 2026年9月12日(土)。",
            "会場: メニコンANNEX HITOMIホール。"
          ],
          "keywords": ["演奏会", "定期演奏会", "第11回", "11回", "2026年9月12日", "2026/9/12", "メニコン", "annex", "hitomi", "ホール"]
        }
      ]
    }
  ]
}
```

### 関数を 2 つ以上に分割する場合の設定例

項目一覧が増えて 1 関数では説明しきれなくなった場合は、Remote Config の編集だけで関数を分割できる。`description` はモデルが呼び分けの判断に使う唯一の情報であるため、担当範囲が重複しないように書く。

```json
{
  "schemaVersion": 1,
  "toolInstruction": "\n\n## 情報の取得ルール（厳守）\n- プレクトラム結社の演奏会・イベントについて尋ねられた場合は、必ず getPlectrumSocietyEventKnowledge 関数を呼び出す。\n- 結社の制度（給与、規約など）について尋ねられた場合は、必ず getPlectrumSocietySystemKnowledge 関数を呼び出す。\n- 現在の日時が必要な場合は、必ず getCurrentDateTime 関数を呼び出す。\n- いずれの関数でも該当情報が得られなかった場合は、分からない旨を正直に伝える。",
  "functions": [
    {
      "name": "getPlectrumSocietyEventKnowledge",
      "handler": "knowledgeLookup",
      "description": "プレクトラム結社の演奏会・イベントに関する公式情報（開催日、会場など）を取得します。給与などの制度については扱いません。",
      "parameters": [
        { "name": "topic", "type": "string", "description": "取得したいトピックID。" },
        { "name": "query", "type": "string", "description": "自然言語で記述された検索クエリ。" }
      ],
      "entries": [
        {
          "topic": "regular_concert_11",
          "title": "第11回定期演奏会",
          "summary": "プレクトラム結社の第11回定期演奏会は2026年9月12日(土)、メニコンANNEX HITOMIホールで開催予定。",
          "facts": ["開催日: 2026年9月12日(土)。", "会場: メニコンANNEX HITOMIホール。"],
          "keywords": ["演奏会", "定期演奏会", "第11回"]
        }
      ]
    },
    {
      "name": "getPlectrumSocietySystemKnowledge",
      "handler": "knowledgeLookup",
      "description": "プレクトラム結社の制度（給与、規約など）に関する公式情報を取得します。演奏会の開催情報については扱いません。",
      "parameters": [
        { "name": "topic", "type": "string", "description": "取得したいトピックID。" },
        { "name": "query", "type": "string", "description": "自然言語で記述された検索クエリ。" }
      ],
      "entries": [
        {
          "topic": "salary_policy",
          "title": "給与制度",
          "summary": "結社の給料は0円。毎年5%のベースアップが行われているが、元々0円のため昇給額も0円。",
          "facts": ["結社の給料は0円です。"],
          "keywords": ["給料", "給与", "ベースアップ"]
        }
      ]
    }
  ]
}
```

### バリデーションと不正値の扱い

パースは「安全側に倒すが、直せる範囲は直す」方針とし、粒度ごとに扱いを変える。

| 検出内容 | 扱い |
| --- | --- |
| JSON として不正 | 設定全体を破棄し、組み込みデフォルトを使用（Crashlytics へ報告） |
| `schemaVersion` がアプリの対応上限より大きい | 設定全体を破棄し、組み込みデフォルトを使用（未知の構造を部分解釈すると誤った関数宣言をモデルに渡すため） |
| `schemaVersion` が欠落、または `functions` が欠落 | 設定全体を破棄し、組み込みデフォルトを使用（Crashlytics へ報告） |
| 個別の `Function` の必須項目欠落・`name` の形式違反・未知の `handler`・未知の `type` | その関数のみ除外（警告ログ）。他の関数と知識データは有効なまま使用する |
| `name` が組み込み関数の名前と衝突している | その関数のみ除外（警告ログ）。組み込み関数の宣言を優先する |
| `name` の重複 | 先に定義された関数を採用し、後続を除外（警告ログ） |
| `handler` が `knowledgeLookup` なのに `entries` が欠落または空 | その関数のみ除外（警告ログ）。呼ばれても何も返せない関数をモデルに提示しないため |
| 個別の `KnowledgeEntry` の必須項目欠落 | そのエントリーのみ除外（警告ログ）。除外の結果その関数の `entries` が空になった場合は、その関数も除外する |
| 同一関数内での `topic` の重複 | 先に定義されたエントリーを採用し、後続を除外（警告ログ）。**別の関数との間の重複は許容する**（トピック ID の名前空間は関数ごとに独立しているため） |
| 除外の結果 `functions` が空になった | データ駆動関数なしとして扱う。組み込み関数は引き続き提供されるため、`tools` が空になることはない |

「設定全体を破棄」に該当するケースは運用ミスであり実行時に想定しない状態なので、コーディングルールに従い Crashlytics へレポートする（`ErrorReportService` を使用）。一方、要素単位の除外は Remote Config とアプリバージョンの世代差でも起こり得るため、ログのみとする。

### バージョニング方針

- `schemaVersion` はアプリ側に「対応する最大バージョン」定数を持たせ、それを超える値は受け付けない。
- 後方互換な追加（新しい任意フィールド、新しい `handler` 種別、新しい `type` 種別）では `schemaVersion` を上げない。未知のフィールドは無視し、未知の `handler` / `type` は当該関数を除外することで、旧バージョンのアプリでも安全に動作する。
- 既存フィールドの意味変更や必須化など、後方互換でない変更を行う場合のみ `schemaVersion` を上げる。この場合、旧バージョンのアプリは組み込みデフォルトにフォールバックしてしまうため、Remote Config の**条件（アプリバージョン）でパラメーター値を出し分け**、旧バージョン向けには旧スキーマの値を配信する。

## アプリ側アーキテクチャ

### レイヤー構成

```
UI Layer (HomeScreen)
└── Presenter Layer (ChatMessages / ResolvedChatMode)
    └── Service Layer
        ├── AiChatService          … toolInstruction をシステムプロンプトに付与
        ├── CavivaraKnowledgeBase  … 関数宣言の生成・関数の実行
        ├── FunctionCallingConfigService … JSON のパース・検証・フォールバック
        └── RemoteConfigService    … Remote Config からの生値取得
```

Remote Config の値は既存実装と同様に Service 層で扱う（既存の `minimumBuildNumber` などと同じ配置）。SharedPreferences のような Repository は設けない。Remote Config 自体がキャッシュを持ち、アプリからは読み取り専用であるため、永続化の抽象化を挟む必要がないためである。

### 主要コンポーネント

#### 1. FunctionCallingToolConfig（ドメインモデル）

**配置**: `client/lib/data/model/function_calling_config.dart`

`freezed` で定義する。`json_serializable` による `fromJson` は生成しない。生成されるパース処理は必須キーが欠けていると `TypeError`（`Exception` ではない）を投げるため、要素単位で不正を検出して除外する本設計の検証方針とは相性が悪い。JSON の解釈は [FunctionCallingConfigService](#3-functioncallingconfigserviceパース検証フォールバック) の明示的な検証処理で行う。

- `FunctionCallingToolConfig`: `schemaVersion` / `toolInstruction` / `functions`
  - `firebase_ai` にも `FunctionCallingConfig`（関数呼び出しモードの設定）があり衝突するため、クラス名を `FunctionCallingToolConfig` とする
- `FunctionCallingFunction`: `name` / `handler` / `description` / `parameters` / `entries`
  - `enabled` はモデルには持たせず、解釈時に無効な関数を除外する
- `FunctionCallingParameter`: `name` / `type` / `description` / `isRequired` / `enumValues`
  - `required` は Dart の予約語のため、フィールド名は `isRequired` とする
- `KnowledgeEntry`: `topic` / `title` / `summary` / `facts` / `keywords`（現行の `_KnowledgeEntry` を公開モデルへ移動し、`matches` によるキーワード一致判定も引き継ぐ）
- `FunctionCallingHandler` / `FunctionCallingParameterType`: enum。未知の値は enum に落とさず、当該関数を除外する。`FunctionCallingHandler` は現行 `knowledgeLookup` のみを持つ（組み込み関数はこの enum に含めない）
- `currentDateTimeFunctionName` / `builtInFunctionNames`: 組み込み関数の名前。予約名の判定と、実行時の振り分けの両方で参照する

UI に表示する文字列は含めない（コーディングルールに従う）。

設定を解釈できなかったことを表す例外は、`client/lib/data/model/function_calling_config_exception.dart` に `freezed` の sealed クラスとして定義する。構造バージョン超過（`unsupportedSchemaVersion`）とそれ以外（`malformed`）を型で区別し、Crashlytics へ報告するかどうかの判断に使う。

#### 2. functionCallingConfigJson（Remote Config アクセサー）

**配置**: `client/lib/data/service/remote_config_service.dart`（既存ファイルに追加）

```dart
@riverpod
String functionCallingConfigJson(Ref ref) {
  try {
    return FirebaseRemoteConfig.instance.getString('functionCallingConfig');
  } on Exception catch (e) {
    _logger.warning('Remote Config から Function Calling の設定を取得できませんでした', e);

    return '';
  }
}
```

`getString` は未設定時に空文字を返すため、空文字の場合は組み込みデフォルト設定を使用する。

`FirebaseRemoteConfig` への直接アクセスをこのファイルに閉じ、後続のパース処理をテスト時にプロバイダーのオーバーライドで差し替えられるようにする。

Firebase が初期化されていない場合（初期化に失敗した場合や、単体テストの実行時）は `FirebaseRemoteConfig.instance` が `FirebaseException` を投げるため、捕捉して空文字を返す。既存の `minimumBuildNumber` などのアクセサーには例外処理がないが、この設定は**チャットの応答経路（自動選択モードの判定を含む）から参照される**ため、例外がそのまま伝播するとチャット自体が利用できなくなる。Firebase の初期化に失敗してもアプリを続行する [main.dart](../../client/lib/main.dart) の方針に合わせ、組み込みデフォルト設定へフォールバックする。

#### 3. FunctionCallingConfigService（パース・検証・フォールバック）

**配置**: `client/lib/data/service/function_calling_config_service.dart`

- `@riverpod FunctionCallingToolConfig functionCallingConfig(Ref ref)`
  - `functionCallingConfigJsonProvider` を `watch` し、パース・検証を行った結果を返す
  - 失敗時は組み込みデフォルト設定を返し、`malformed` の場合のみ `ErrorReportService` へ報告する
- 組み込みデフォルト設定は同ファイルに `const` で定義する（[設定例](#設定例)と同じ内容）
- 検証ロジックは `parseFunctionCallingConfig`（`@visibleForTesting`）として切り出し、単体テストしやすくする

#### 4. CavivaraKnowledgeBase の設定駆動化

**配置**: `client/lib/data/service/cavivara_knowledge_service.dart`（既存を変更）

- `CavivaraKnowledgeBase({required FunctionCallingToolConfig config})` とし、プロバイダーで `functionCallingConfigProvider` を `watch` して生成する
- `tools`: **組み込み関数の宣言＋ `config.functions`** から `FunctionDeclaration` を組み立て、1 つの `Tool.functionDeclarations` にまとめる。組み込み関数を必ず含むため空にはならない
  - 組み込み関数と同名の関数は宣言からも除き、同じ関数名が二重に宣言されないようにする（Remote Config 経由では解釈時に除外済みだが、設定を直接組み立てた場合にも一貫した宣言になるようにする）
  - 組み込み関数の宣言（`getCurrentDateTime` の名前・説明・引数なし）は現行の `_buildCurrentDateTimeFunctionDeclaration` をそのまま維持する
- `execute`: 関数名がまず組み込み関数のものかを判定し、該当すれば組み込み実装を実行する。該当しなければ **関数名で `config.functions` を引き、見つかった関数定義の `handler` と `entries` を使って** 実行処理へ振り分ける。組み込み関数の判定を先に行うことで、Remote Config 側が同名の関数を定義していても組み込み実装が使われる
  - 組み込み（`getCurrentDateTime`）: 現行と同じく `DateTime.now()` を返す
  - `knowledgeLookup`: **その関数定義の `entries`** に対して現行と同じトピック解決（`topic` 完全一致 → `query` のキーワード一致）を行う。関数が 2 つ以上ある場合、参照する項目一覧は呼ばれた関数のものに限定される
  - 該当トピックが見つからなかった場合に返す `availableTopics` も、その関数の `entries` のトピックのみとする
- `hasRelevantKnowledge`: 参照先を `_entries` から **全関数の `entries` を横断したもの** に変更する。自動選択モードの判定では「結社の知識に関係する発話か」だけを見るため、関数の区別は不要である
- 未知の関数名を要求された場合の応答（`found: false` と利用可能な関数名の提示）は現行の挙動を維持し、`availableFunctions` は組み込み関数と設定の関数を合わせて動的に組み立てる
- 関数定義の検索を毎回リスト走査で行わないよう、コンストラクターで関数名をキーとした `Map` を構築しておく

#### 5. AiChatService の toolInstruction 対応

**配置**: `client/lib/data/service/ai_chat_service.dart`（既存を変更）

- `_plectrumSocietyToolInstruction` の定数を削除し、`knowledgeBase` 経由（または `functionCallingConfigProvider` から注入）で取得した `toolInstruction` を使用する
- `toolInstruction` が空の場合はシステムプロンプトに何も追記しない
- `_getModel` の `tools` の設定（結社マスターモードのみ `knowledgeBase.tools` を渡す）は現行のまま変更しない。`tools` が空になるケースがないため、`null` 渡しの分岐は不要である

#### 6. AiChatService の並行 Function Calling 対応

**配置**: `client/lib/data/service/ai_chat_service.dart`（既存を変更）

Gemini は 1 レスポンスで複数の `functionCall` を返すことがある（並行 Function Calling）。現行の `_processResponseStream` は次の構造になっており、この場合に応答が壊れる。

```dart
// 現行の実装（問題あり）
for (final functionCall in functionCalls) {
  await _handleFunctionCall(...);  // 関数応答を1件送り、その中で _processResponseStream を再帰
}
```

1 件目の関数応答だけをモデルに返して応答ストリームを最後まで処理してしまうため、モデルはその時点で最終テキストを生成し、`controller` にテキストが流れる。その後 2 件目の関数応答が送られ、モデルが再度テキストを生成するため、**同じ問いへの回答が 2 回 `controller` に流れる**。`ChatMessages.sendMessage` のチャンク結合処理（前方一致なら置換、そうでなければ連結）では 2 回目の回答が 1 回目に連結されるため、同じ内容が繰り返された不自然なメッセージになる。関数呼び出しの深度カウントも枝ごとに独立して増える。

そのため、次のように **チャンク内の全 `functionCall` を実行し、結果を 1 通のメッセージにまとめて返す** 構造へ変更する。

```dart
// 変更後
final functionResponses = <FunctionResponse>[];
for (final functionCall in functionCalls) {
  final payload = await knowledgeBase.execute(
    functionName: functionCall.name,
    arguments: functionCall.args,
  );
  functionResponses.add(FunctionResponse(functionCall.name, payload));
}

await _processResponseStream(
  chatSession: chatSession,
  responseStream: chatSession.sendMessageStream(
    Content.functionResponses(functionResponses),
  ),
  controller: controller,
  mode: mode,
  functionCallDepth: functionCallDepth + 1,
);
```

`Content.functionResponses(Iterable<FunctionResponse>)` は firebase_ai が提供しており、SDK 自身の自動 Function Calling 実装（`chat.dart`）も全関数の結果を 1 つの `Content` にまとめて送信している。これに合わせることで、`functionCallDepth` も「1 ターン = 1 加算」として意図どおりに機能する。

並行 Function Calling は、1 つのチャンクに複数の `functionCall` が含まれる場合と、複数のチャンクに分かれて届く場合の両方があり得る。そのため関数呼び出しは応答ストリーム全体から収集し、ストリームの完了後にまとめて実行する。

また、**関数呼び出しを検出した以降のチャンクのテキストは送出しない**。関数呼び出しを要求する応答では最終的な回答は関数の結果を返した後に生成されるため、この段階のテキスト（「調べますね」のような前置き）を送出すると、最終的な回答とは別のテキストとして UI に残ってしまう。`ChatMessages.sendMessage` のチャンク結合処理は前方一致しないチャンクを連結するため、前置きに最終回答が連結された不自然なメッセージになる。

個別の関数の実行が失敗した場合は、**その関数の応答にエラー内容を詰めて、他の関数の結果と一緒に返す**。1 件の失敗でターン全体を打ち切ると、成功した関数の結果も捨てることになり、モデルは何も情報を得られないまま会話が止まる。失敗した関数の応答は `{'found': false, 'message': ...}` の形とし、`toolInstruction` の「該当情報が得られなかった場合は分からない旨を伝える」指示に乗せる。あわせて Crashlytics へレポートする。

なお、この不具合は Remote Config 対応以前から `getPlectrumSocietyKnowledge` と `getCurrentDateTime` の 2 つが宣言されているため発生し得る（例:「次の演奏会まであと何日？」で両方が同時に呼ばれるケース）。Remote Config で関数を増やせるようにすると発生頻度が上がるため、本対応と合わせて修正する。

### 反映タイミング

既存実装（[root_app.dart](../../client/lib/ui/root_app.dart) の `updatedRemoteConfigKeysProvider` リスナーと [root_presenter.dart](../../client/lib/ui/root_presenter.dart) の `ensureActivateFetchedRemoteConfigs`）と同じ「次回起動時に反映」戦略に従う。

1. 起動時に `ensureActivateFetchedRemoteConfigs()` でフェッチ済みの値を有効化する
2. `appInitialRoute` の解決より後に `functionCallingConfigProvider` が初めて読まれるため、その起動セッションでは有効化済みの値が使われる
3. 実行中に配信された更新は `onConfigUpdated` で受け取るがその場では反映せず、次回起動時に有効化する

**アプリ実行中に設定を切り替えない**のは意図的な設計である。`AiChatService` は `systemPrompt` と `ChatMode` をキーに `ChatSession` をキャッシュしており、セッション生成時の `tools` はセッションの寿命にわたって固定される。会話の途中で関数宣言が変わると、モデルに提示済みの関数と実際に実行できる関数が食い違い得るため、起動単位で固定する方が安全である。

## 非対応事項

以下は本設計の対象外とする。将来必要になった時点で `schemaVersion` を上げて拡張する。

- **新しい種別の関数を Remote Config だけで追加すること**: 実行処理（`handler`）はアプリの実装が必要
- **組み込み関数（`getCurrentDateTime`）の宣言の変更**: 名前・説明・引数はアプリに固定する。変更にはアプリのリリースが必要
- **ネストしたオブジェクト型・配列オブジェクト型の引数**: 引数はプリミティブと文字列配列のみ
- **雑談マスターモードの Response Schema の制御**: Function Calling とレスポンススキーマは併用できず、Response Schema の変更はアプリ側のパース処理（`AiResponse`）と密結合しているため、Remote Config では扱わない
- **モードごとの関数の出し分け**: 現状 Function Calling を使うのは結社マスターモードのみであるため、モードによる絞り込みは持たせない

## テスト方針

**配置**: `client/test/data/service/function_calling_config_service_test.dart`, `client/test/data/service/cavivara_knowledge_service_test.dart`

- `FunctionCallingConfigService`
  - 正常な JSON をパースできる
  - 空文字・不正な JSON・`schemaVersion` 超過で組み込みデフォルトにフォールバックする
  - 必須項目欠落・未知の `handler` / `type`・名前重複・組み込み関数との名前衝突の関数が除外され、他の要素は残る
  - `handler` が `knowledgeLookup` で `entries` が空の関数が除外される
  - 同一関数内の `topic` 重複は除外され、別関数間の `topic` 重複は許容される
  - `functions` が空になった場合に空の関数リストになる
- `CavivaraKnowledgeBase`
  - 設定から期待する `FunctionDeclaration` が生成される（関数名・引数の必須／任意）
  - 設定の `functions` が空でも `tools` に組み込み関数の宣言が含まれる
  - `execute` が組み込み関数と `handler` に応じて振り分けられる
  - 設定が組み込み関数と同名の関数を定義していても、組み込み実装が実行される
  - **関数が 2 つ以上ある場合、各関数が自身の `entries` のみを参照する**（一方の関数のトピック ID を他方に渡しても `found: false` になり、`availableTopics` に他方のトピックが含まれない）
  - `hasRelevantKnowledge` が全関数の `entries` を横断して判定される
  - 未知の関数名に対して `found: false` の応答を返す
Remote Config の生値は `functionCallingConfigJsonProvider` のオーバーライドで差し替え、`FirebaseRemoteConfig` の初期化を必要としないようにする。設定を解釈できなかった場合は Crashlytics へ報告するため、`errorReportServiceProvider` もモックに差し替える。モックは `mocktail` を使用する。

`AiChatService` の以下の挙動は、`GenerativeModel` および `ChatSession` の生成に `FirebaseAI` の初期化が必要で、単体テストからは検証できない。実機での動作確認、およびコードレビューで担保する。

- `toolInstruction` がシステムプロンプトに付与される（空の場合は追記されない）
- 複数の `functionCall` が返った場合に、全関数を実行して 1 通の `Content.functionResponses` で返し、応答テキストが重複して流れない
- 複数関数のうち 1 つが失敗しても、残りの関数の結果とエラー内容が一緒に返る
- `functionCallDepth` が 1 ターンあたり 1 だけ増える

## 運用手順

### 設定を更新する

1. Firebase コンソール → Remote Config → `functionCallingConfig` を JSON エディターで編集する
2. 公開前に、JSON が[スキーマ](#json-スキーマ)を満たしているか確認する（`schemaVersion` の値、関数名の形式、`handler` がアプリの対応済み識別子か、組み込み関数の名前と衝突していないか）
3. dev 環境の Firebase プロジェクトで公開し、実機で会話を行って Function Calling が期待どおり働くことを確認する
4. prod 環境の Firebase プロジェクトで公開する

dev / prod は別の Firebase プロジェクトであるため、環境の出し分けに Remote Config の条件は使わない。

### 注意点

- `getCurrentDateTime` は組み込み関数のため Remote Config からは無効化も変更もできない。`functions` に同名の関数を定義しても無視される
- 関数を 2 つ以上に分割する場合、モデルが呼び分けの判断に使えるのは `description` だけである。担当範囲が曖昧だと誤った関数を呼び、`found: false` が返って「分からない」と回答してしまう。`description` には**扱う範囲と扱わない範囲の両方**を書き、必要に応じて `toolInstruction` でも呼び分けを明示する
- 項目一覧（`entries`）は関数ごとに独立しているため、関数を分割する際は既存の項目をどちらの関数に移すかを漏れなく決める。どの関数にも属さなくなった項目は参照されなくなる
- 知識エントリーの `keywords` は自動選択モードの判定にも使われるため、汎用的すぎる語（「今日」「予定」など）を追加すると、雑談のつもりの発話でも結社マスターモードに切り替わるようになる
- 反映は次回起動時であるため、公開直後に実機で確認する場合はアプリを再起動する
- 後方互換でないスキーマ変更を行う場合は、アプリバージョンの条件でパラメーター値を出し分ける（[バージョニング方針](#バージョニング方針)参照）

## 関連ドキュメント

- [回答モード切り替え機能（結社マスターモード／雑談マスターモード）概要設計書](chat-mode-selection.md) - Function Calling を使用する結社マスターモードの設計
- [SharedPreferences を利用する際の設計ガイド](../how-to-design-when-using-shared-preferences.md) - Provider / Notifier の設計パターン
- [Firebase Remote Config のパラメーターと条件](https://firebase.google.com/docs/remote-config/parameters)
- [Remote Config の値の読み込み戦略](https://firebase.google.com/docs/remote-config/loading#strategy_3_load_new_values_for_next_startup)
