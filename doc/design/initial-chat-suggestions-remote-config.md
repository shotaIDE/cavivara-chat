<!-- cspell:ignore mocktail -->

# 会話開始時のサジェストの Remote Config 制御 概要設計書

## 目的

チャット画面で会話開始時に表示される「質問してみましょう」のサジェスト（アクションリスト）の内容を、アプリのリリースなしに Firebase Remote Config から更新できるようにする。

現状、サジェストの候補は [home_screen.dart](../../client/lib/ui/feature/home/home_screen.dart) の `_ChatSuggestionsState._allSuggestions` に 20 件ハードコードされており、文言の追加・修正・季節ごとの入れ替えのたびにアプリのリリースが必要になっている。

サジェストは「ユーザーがアプリで最初に触れる導線」であり、文言によってタップ率が大きく変わる。試行錯誤のサイクルをストア審査に縛られずに回せるようにすることが本対応の狙いである。

## 設計方針

先行して同じ仕組みを導入した [Function Calling の Remote Config 制御](function-calling-remote-config.md) と同じ構成に揃える。設定の取得・パース・フォールバックの流れ、例外の切り分け、反映タイミングの考え方はすべて共通である。以下では、この機能に固有の判断のみを記述する。

### 方針 1: 「文言」は Remote Config、「アイコンの実体」はアプリ

サジェストは「カードに表示する文言（＝タップ時に送信されるメッセージ）」と「カードに表示するアイコン」の組で構成される。

このうちアイコンは、Flutter のビルド時に**実際に参照している `Icons` のみを残すツリーシェイク**（`--tree-shake-icons`）が行われるため、Remote Config から任意のアイコンを指定することはできない。指定できたとしても、フォントに含まれないコードポイントは豆腐（□）になる。

そのため、アイコンは Function Calling の `handler` と同じく **アプリがあらかじめ用意した識別子からの選択のみ** を許す。識別子と `IconData` の対応表は [initial_chat_suggestion_icon_extension.dart](../../client/lib/ui/component/initial_chat_suggestion_icon_extension.dart) に持ち、新しいアイコンを増やす場合はアプリのリリースが必要になる。

一方で、**未知の識別子が指定されてもサジェストごと除外はしない**。この点は Function Calling の `handler` と扱いが異なる。未知の `handler` の関数は呼ばれても何も返せないため提示する意味がないが、アイコンは装飾であり、識別子を解釈できなくても「文言を送信する」というサジェスト本来の役割は果たせる。アイコンの綴り間違いだけで用意した文言が表示されなくなるほうが運用上の損失が大きいため、既定のアイコン（`chat`）に読み替えて表示する。

### 方針 2: 1 つの JSON パラメーターに集約する

文言・アイコン・表示件数は互いに整合していないと成立しない（例: 表示件数だけ増やしても候補が足りない）。パラメーターを分けると公開順によって不整合な組み合わせが端末に届き得るため、**1 つの JSON 型パラメーターにまとめ、常に一括で公開する**。

### 方針 3: フォールバックで、壊れた設定でも導線を維持する

サジェストが表示されないと、初めてアプリを開いたユーザーは何を送ればよいか分からないまま画面を離れかねない。Remote Config の運用ミス（JSON の構文エラー、必須項目の欠落）でこの導線が失われないよう、次の優先順で値を解決する。

1. Remote Config から取得・有効化済みの値
2. （1 が未設定・パース不能・スキーマ非対応の場合、および Firebase が初期化されておらず値を取得できない場合）アプリに埋め込んだ組み込みデフォルト設定

組み込みデフォルト設定には、**現在ハードコードされている 20 件をそのまま移植する**。Function Calling では「更新頻度の高い演奏会情報は組み込みデフォルトに含めない」としたが、サジェストの文言は特定の日付に依存せず、古くなっても「会話のきっかけ」としては成立し続ける。Remote Config 未設定の環境（ローカル開発、Firebase 初期化失敗時、エミュレーター Suite）で従来と同じ体験になることを優先する。

### 方針 4: 候補と表示件数を分け、表示するサジェストはアプリが選ぶ

Remote Config には**候補の全リスト**と**一度に表示する件数**を持たせ、そこから実際に表示する分をランダムに選ぶ処理はアプリ側に残す。これは Remote Config 導入前の挙動（20 件から 3 件をランダム表示）をそのまま引き継ぐものである。

「どの 3 件を出すか」までを Remote Config で固定しないのは、毎回同じカードが並ぶとアプリを開き直す動機が薄れるためである。候補を多めに登録し、そこから毎回違う組み合わせを見せるほうが、文言の当たり外れも把握しやすい。

## Remote Config I/F 仕様

### パラメーター

| 項目 | 値 |
| --- | --- |
| パラメーターキー | `initialChatSuggestionsConfig` |
| データ型 | JSON |
| 既定値（Remote Config 側） | 設定しない（アプリ側の組み込みデフォルトにフォールバックさせる） |
| 想定サイズ | 数 KB 以内 |

キー名は既存の `minimumBuildNumber` / `showDebugFeatureOnProdRelease` / `functionCallingConfig` と同じ camelCase に揃える。AI の返答後に表示されるサジェスト（`SuggestedReplies`、モデルが生成する）と区別できるよう、`initial` を冠する。

### JSON スキーマ

#### ルート

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `schemaVersion` | int | ○ | この JSON の構造バージョン。現行は `1` |
| `displayCount` | int | - | 一度に表示する件数。1 以上。既定値 `3`。候補数がこれに満たない場合は候補すべてを表示する |
| `suggestions` | array\<Suggestion\> | ○ | 表示候補のリスト。空配列を指定すると、サジェスト自体を非表示にできる |

#### Suggestion

| フィールド | 型 | 必須 | 説明 |
| --- | --- | --- | --- |
| `label` | string | ○ | カードに表示する文言。タップするとこの文言がそのままメッセージとして送信される |
| `icon` | string | - | カードに表示するアイコンの識別子。[アイコンの識別子](#アイコンの識別子)から選ぶ。未指定・未対応の場合は `chat` |
| `enabled` | bool | - | `false` の場合は候補に含めない。既定値 `true` |

`label` は表示文言と送信内容を兼ねる。Remote Config 導入前も同じ扱いであり、カードに書いてある内容がそのまま送られるほうがユーザーにとって予測しやすいため、表示用と送信用を分けることはしない。

#### アイコンの識別子

`InitialChatSuggestionIcon` の enum 値と 1 対 1 で対応する。

| 分類 | 識別子 |
| --- | --- |
| 既定 | `chat` |
| 音楽・マンドリン | `queueMusic` / `musicNote` / `libraryMusic` / `piano` / `album` / `headphones` / `event` / `group` / `people` / `build` |
| 一般 | `restaurantMenu` / `flightTakeoff` / `fitnessCenter` / `book` / `lightbulb` / `wbSunny` / `movie` / `language` / `coffee` / `work` / `school` / `pets` / `celebration` / `savings` / `favorite` / `help` |

対応する `IconData` は [initial_chat_suggestion_icon_extension.dart](../../client/lib/ui/component/initial_chat_suggestion_icon_extension.dart) を参照。

### 設定例

```json
{
  "schemaVersion": 1,
  "displayCount": 3,
  "suggestions": [
    {
      "icon": "queueMusic",
      "label": "マンドリンの演奏会の選曲会議で何を出すか迷っているヴィヴァ"
    },
    {
      "icon": "group",
      "label": "プレクトラム結社の最新の演奏会について教えて"
    },
    {
      "icon": "musicNote",
      "label": "マンドリンの練習方法を教えてヴィヴァ"
    },
    {
      "icon": "celebration",
      "label": "第11回定期演奏会の聴きどころを教えて",
      "enabled": false
    },
    {
      "icon": "restaurantMenu",
      "label": "今晩の夜ご飯のレシピを考えて"
    }
  ]
}
```

`enabled` を `false` にしたサジェストは、定義を残したまま表示から外せる。演奏会の告知のように期間限定で出したい文言を、時期が来たら有効化する運用ができる。

### バリデーションと不正値の扱い

パースは「安全側に倒すが、直せる範囲は直す」方針とし、粒度ごとに扱いを変える。

| 検出内容 | 扱い |
| --- | --- |
| JSON として不正 | 設定全体を破棄し、組み込みデフォルトを使用（Crashlytics へ報告） |
| `schemaVersion` がアプリの対応上限より大きい | 設定全体を破棄し、組み込みデフォルトを使用（未知の構造を部分解釈すると意図しない文言を表示するため。Crashlytics へは報告しない） |
| `schemaVersion` が欠落、または `suggestions` が欠落 | 設定全体を破棄し、組み込みデフォルトを使用（Crashlytics へ報告） |
| `displayCount` が整数でない、または 1 未満 | 既定値 `3` に読み替える（警告ログ）。表示件数だけの誤りで候補すべてを捨てる必要はないため |
| 個別の `Suggestion` がオブジェクトでない・`label` が欠落または空白のみ | そのサジェストのみ除外（警告ログ） |
| 未知の `icon` | **除外せず**、既定のアイコン（`chat`）に読み替える（警告ログ）。[方針 1](#方針-1-文言は-remote-configアイコンの実体はアプリ) を参照 |
| `label` の重複 | 先に定義されたものを採用し、後続を除外（警告ログ）。同じ文言のカードが並ぶと選択肢が実質的に減るため |
| 除外の結果 `suggestions` が空になった、または最初から空配列 | サジェストを表示しない（見出しごと非表示にする） |

「設定全体を破棄」に該当するケースは運用ミスであり実行時に想定しない状態なので、コーディングルールに従い Crashlytics へレポートする（`ErrorReportService` を使用）。一方、要素単位の除外・読み替えは Remote Config とアプリバージョンの世代差でも起こり得るため、ログのみとする。

### バージョニング方針

- `schemaVersion` はアプリ側に「対応する最大バージョン」定数を持たせ、それを超える値は受け付けない。
- 後方互換な追加（新しい任意フィールド、新しい `icon` 種別）では `schemaVersion` を上げない。未知のフィールドは無視し、未知の `icon` は既定のアイコンに読み替えることで、旧バージョンのアプリでも安全に動作する。
- 既存フィールドの意味変更や必須化など、後方互換でない変更を行う場合のみ `schemaVersion` を上げる。この場合、旧バージョンのアプリは組み込みデフォルトにフォールバックしてしまうため、Remote Config の**条件（アプリバージョン）でパラメーター値を出し分け**、旧バージョン向けには旧スキーマの値を配信する。

## アプリ側アーキテクチャ

### レイヤー構成

```
UI Layer (HomeScreen の _ChatSuggestions)
└── Presenter Layer (InitialChatSuggestions … 候補から表示分を抽選)
    └── Service Layer
        ├── InitialChatSuggestionsConfigService … JSON のパース・検証・フォールバック
        └── RemoteConfigService                 … Remote Config からの生値取得
```

Remote Config の値は既存実装と同様に Service 層で扱う（既存の `minimumBuildNumber` / `functionCallingConfig` と同じ配置）。SharedPreferences のような Repository は設けない。Remote Config 自体がキャッシュを持ち、アプリからは読み取り専用であるため、永続化の抽象化を挟む必要がないためである。

### 主要コンポーネント

#### 1. InitialChatSuggestionsConfig（ドメインモデル）

**配置**: [initial_chat_suggestions_config.dart](../../client/lib/data/model/initial_chat_suggestions_config.dart)

`freezed` で定義する。`json_serializable` による `fromJson` は生成しない。生成されるパース処理は必須キーが欠けていると `TypeError`（`Exception` ではない）を投げるため、要素単位で不正を検出して除外する本設計の検証方針とは相性が悪い。

- `InitialChatSuggestionsConfig`: `schemaVersion` / `displayCount` / `suggestions`
- `InitialChatSuggestion`: `label` / `icon`
  - `enabled` はモデルには持たせず、解釈時に無効なサジェストを除外する
- `InitialChatSuggestionIcon`: enum。未知の値は enum に落とさず、既定値 `chat` に読み替える

`label` は Remote Config から配信されるデータであり、アプリが持つ固定の表示文字列ではないためモデルに含める。一方、見出しの「質問してみましょう」のような固定文言はコーディングルールに従いウィジェット側に置く。

設定を解釈できなかったことを表す例外は、[initial_chat_suggestions_config_exception.dart](../../client/lib/data/model/initial_chat_suggestions_config_exception.dart) に `freezed` の sealed クラスとして定義する。構造バージョン超過（`unsupportedSchemaVersion`）とそれ以外（`malformed`）を型で区別し、Crashlytics へ報告するかどうかの判断に使う。

`FunctionCallingConfigException` と構造は同じだが共通化はしない。両者は独立して増改築され得る（片方だけに新しい失敗の種類が増える）ため、共通の親を持たせると、どちらの機能でも起こり得ない失敗を `switch` で扱う必要が出てくる。

#### 2. initialChatSuggestionsConfigJson（Remote Config アクセサー）

**配置**: [remote_config_service.dart](../../client/lib/data/service/remote_config_service.dart)（既存ファイルに追加）

`FirebaseRemoteConfig.instance.getString('initialChatSuggestionsConfig')` を返すだけのプロバイダー。`getString` は未設定時に空文字を返すため、空文字の場合は組み込みデフォルト設定を使用する。

`FirebaseRemoteConfig` への直接アクセスをこのファイルに閉じ、後続のパース処理をテスト時にプロバイダーのオーバーライドで差し替えられるようにする。

Firebase が初期化されていない場合（初期化に失敗した場合や、ウィジェットテストの実行時）は `FirebaseRemoteConfig.instance` が `FirebaseException` を投げるため、`functionCallingConfigJson` と同様に捕捉して空文字を返す。サジェストが出ないだけでチャット画面自体が開けなくなることを避ける。

#### 3. InitialChatSuggestionsConfigService（パース・検証・フォールバック）

**配置**: [initial_chat_suggestions_config_service.dart](../../client/lib/data/service/initial_chat_suggestions_config_service.dart)

- `@riverpod InitialChatSuggestionsConfig initialChatSuggestionsConfig(Ref ref)`
  - `initialChatSuggestionsConfigJsonProvider` を `watch` し、パース・検証を行った結果を返す
  - 失敗時は組み込みデフォルト設定を返し、`malformed` の場合のみ `ErrorReportService` へ報告する
- 組み込みデフォルト設定は同ファイルに `const` で定義する（Remote Config 導入前の 20 件）
- 検証ロジックは `parseInitialChatSuggestionsConfig`（`@visibleForTesting`）として切り出し、単体テストしやすくする

#### 4. InitialChatSuggestions（表示分の抽選）

**配置**: [home_presenter.dart](../../client/lib/ui/feature/home/home_presenter.dart)

```dart
@riverpod
List<InitialChatSuggestion> initialChatSuggestions(Ref ref) {
  final config = ref.watch(initialChatSuggestionsConfigProvider);

  final shuffled = List.of(config.suggestions)..shuffle(Random());

  return List.unmodifiable(shuffled.take(config.displayCount));
}
```

抽選をウィジェットの `initState` ではなくプロバイダーに置くのは、コーディングルール（表示するデータのフィルタリングはプロバイダー内で行う）に合わせるためと、抽選結果を単体テストで検証できるようにするためである。

抽選結果はプロバイダーが破棄されるまで保持されるため、画面の再構築ではカードの並びが変わらない。会話が始まってサジェストが非表示になると監視元がいなくなり、`autoDispose` によってプロバイダーが破棄される。そのため、会話をクリアして再びサジェストが表示される際は改めて抽選される。これは Remote Config 導入前（ウィジェットの `initState` ごとに抽選）と同じ挙動である。

#### 5. \_ChatSuggestions の設定駆動化

**配置**: [home_screen.dart](../../client/lib/ui/feature/home/home_screen.dart)（既存を変更）

- ハードコードされた `_allSuggestions` と `_displayCount` を削除する
- `StatefulWidget` から `ConsumerStatefulWidget` に変更し、`build` で `initialChatSuggestionsProvider` を `watch` する
  - `initState` での `read` ではなく `build` での `watch` とすることで、ウィジェットが表示されている間プロバイダーが生存し、抽選結果が保たれる
- サジェストが 0 件の場合は `SizedBox.shrink()` を返し、「質問してみましょう」の見出しごと表示しない
- アイコンは `InitialChatSuggestionIconExtension` で `IconData` に解決する
- フェードインのアニメーションとカードのレイアウト（`_SuggestionCard`）は変更しない

### 反映タイミング

既存実装（[root_app.dart](../../client/lib/ui/root_app.dart) の `updatedRemoteConfigKeysProvider` リスナーと [root_presenter.dart](../../client/lib/ui/root_presenter.dart) の `ensureActivateFetchedRemoteConfigs`）と同じ「次回起動時に反映」戦略に従う。

1. 起動時に `ensureActivateFetchedRemoteConfigs()` でフェッチ済みの値を有効化する
2. `appInitialRoute` の解決より後にチャット画面が構築され、`initialChatSuggestionsConfigProvider` が初めて読まれるため、その起動セッションでは有効化済みの値が使われる
3. 実行中に配信された更新は `onConfigUpdated` で受け取るがその場では反映せず、次回起動時に有効化する

サジェストは Function Calling の `tools` と違ってセッションに固定される値ではないため、実行中に切り替えても破綻はしない。それでも起動単位で固定するのは、**表示中にカードの内容が差し替わるとユーザーの操作対象が入れ替わってしまう**ためと、Remote Config の扱いをアプリ全体で 1 つの戦略に統一しておくほうが、値ごとの反映タイミングを追わずに済むためである。

## 非対応事項

以下は本設計の対象外とする。将来必要になった時点で `schemaVersion` を上げて拡張する。

- **新しいアイコンを Remote Config だけで追加すること**: ツリーシェイクの都合上、アプリ側に対応表の追加が必要
- **見出し（「質問してみましょう」）の変更**: 固定の UI 文言としてウィジェット側に置く
- **表示文言と送信内容を分けること**: カードの表示と送信メッセージは同一とする
- **サジェストの重み付け・優先度・出現順の制御**: 候補からの抽選は一様ランダムのみ
- **ユーザーごとのパーソナライズ**: [最初のアクションリストを個人に向けてカスタマイズする](../epic/initial-action-list-customization.md) で扱う。本対応は「全ユーザー共通の候補をリリースなしで差し替える」ところまでを担う
- **回答モードごとのサジェストの出し分け**: 会話開始前はモードが確定していないため持たせない

## テスト方針

**配置**: [initial_chat_suggestions_config_service_test.dart](../../client/test/data/service/initial_chat_suggestions_config_service_test.dart), [home_presenter_test.dart](../../client/test/ui/feature/home/home_presenter_test.dart)

- `InitialChatSuggestionsConfigService`
  - 正常な JSON をパースできる
  - 空文字・不正な JSON・`schemaVersion` 超過で組み込みデフォルトにフォールバックする（`malformed` のみ Crashlytics へ報告する）
  - `displayCount` の未指定・不正値で既定値になる
  - `label` の欠落・空白のみ・オブジェクトでない要素・`enabled: false`・`label` の重複が除外され、他の要素は残る
  - 未知の `icon` はサジェストを残したまま既定のアイコンに読み替えられる
  - `suggestions` が空配列の場合に空のまま解釈される
- `InitialChatSuggestions`
  - 表示件数の分だけ候補から選ばれ、同じ候補が重複しない
  - 候補が表示件数に満たない場合は候補すべてが返る
  - 候補が空の場合は空のリストが返る
  - 繰り返し読み出しても同じ並びが返る

Remote Config の生値は `initialChatSuggestionsConfigJsonProvider` のオーバーライドで、抽選のテストは `initialChatSuggestionsConfigProvider` のオーバーライドで差し替え、`FirebaseRemoteConfig` の初期化を必要としないようにする。設定を解釈できなかった場合は Crashlytics へ報告するため、`errorReportServiceProvider` もモックに差し替える。モックは `mocktail` を使用する。

サジェストが 0 件のときに見出しごと非表示になることは、`HomeScreen` 全体の構築が必要で単体テストからの検証コストが高いため、実機での動作確認とコードレビューで担保する。

## 運用手順

### 設定を更新する

1. Firebase コンソール → Remote Config → `initialChatSuggestionsConfig` を JSON エディターで編集する
2. 公開前に、JSON が[スキーマ](#json-スキーマ)を満たしているか確認する（`schemaVersion` の値、`label` が空でないか、`icon` が[識別子の一覧](#アイコンの識別子)にあるか）
3. dev 環境の Firebase プロジェクトで公開し、実機でチャット画面を開いてサジェストが期待どおり表示されることを確認する
4. prod 環境の Firebase プロジェクトで公開する

dev / prod は別の Firebase プロジェクトであるため、環境の出し分けに Remote Config の条件は使わない。

### 注意点

- 反映は次回起動時であるため、公開直後に実機で確認する場合はアプリを再起動する
- `label` はそのままユーザーの発話としてモデルに送られる。カヴィヴァラさんの口調（「〜ヴィヴァ」）を混ぜる場合も、**ユーザーが言いそうな文言**にする
- 結社の公式情報を尋ねる文言（例: 演奏会の開催日）を追加する場合は、[Function Calling の設定](function-calling-remote-config.md)側に対応する知識エントリーがあるかを確認する。エントリーがないと「分かりません」と返る
- 候補が `displayCount` と同数だと毎回同じカードが並ぶ。抽選による新鮮さを保つには、候補を表示件数より十分多く登録する
- `suggestions` を空配列にするとサジェストが完全に消える。初めて開いたユーザーが何を送ればよいか分からなくなるため、恒久的な非表示は避ける
- アイコンは装飾のため、未知の識別子を指定してもエラーにはならず既定のアイコンで表示される。意図したアイコンが出ない場合は識別子の綴りを確認する
- 後方互換でないスキーマ変更を行う場合は、アプリバージョンの条件でパラメーター値を出し分ける（[バージョニング方針](#バージョニング方針)参照）

## 関連ドキュメント

- [Function Calling の Remote Config 制御 概要設計書](function-calling-remote-config.md) - 同じ構成で先行導入した Remote Config 制御
- [[Epic] 最初のアクションリストを個人に向けてカスタマイズする](../epic/initial-action-list-customization.md) - 本対応の先にあるパーソナライズ構想
- [Firebase Remote Config のパラメーターと条件](https://firebase.google.com/docs/remote-config/parameters)
- [Remote Config の値の読み込み戦略](https://firebase.google.com/docs/remote-config/loading#strategy_3_load_new_values_for_next_startup)
