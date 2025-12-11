# コーディングスタイルと規約

## 一般的なスタイル規則

### ネストの削減
- 常に早期リターン (early return) を使用してネストを減らす
- `if` 文のネストを最小限に抑える

### 例外処理
- `try`-`catch` 文は例外が発生する可能性のある処理のみを囲む
- スコープは可能な限り最小に保つ
- 戻り値の変数は `try`-`catch` スコープの外で定義する

```dart
// 正しい例
final CustomerInfo customerInfo;
try {
  customerInfo = await Purchases.purchasePackage(product.package);
} catch (e) {
  throw PurchaseException();
}
return customerInfo.entitlements;
```

### 未使用引数の扱い
- 使用しない関数引数は明示的に `_` と命名する

```dart
onTap: (_) {  // 未使用の引数は明示的に "_" とする
  // ...
},
```

### コードの整理
- 未使用のコードは即座に削除する
- コードの一貫性を保つ
- 類似の機能を持つ処理は同じフローで実装する

### コメント
- コメントは日本語で記述する
- コードの意図や目的を明確にする必要がある場合のみコメントを追加
- コード自体が明確な場合はコメントを避ける
- 特に重要な注意点や落とし穴は理由を含めて詳細に記述する

### 命名規則
- 変数名は目的と内容を明確に示すものにする
- 一時変数でも意味のある名前を使用する
- 同じ型のデータを扱う変数には一貫した命名パターンを使用する

## Flutter 固有の規則

### クラス定義
- クラスを不変にできる場合は `const` コンストラクタを使用する

### ドメインモデル
- ドメインモデルは明確に分離し、適切なファイルに配置する
- `freezed` を使用して不変のドメインモデルを定義する
- `sealed class` を使用する場合も `freezed` を使用する

### 関数型プログラミング
- コレクション操作には関数型メソッドを使用する
  - 例: `map`, `where`, `fold`, `expand`
- 複雑なデータ変換は複数のステップに分割して可読性を向上させる
- コレクションを変換する際は、新しい変換済みコレクションを返す処理を使用する
  - 例: `collection` パッケージの `sortedBy`

### Riverpod による状態管理
- 状態管理には `Riverpod` を使用する
- プロバイダーは `@riverpod` アノテーションを使用してコード生成で定義する
- 複数の非同期プロバイダーを扱う場合:
  - すべてのプロバイダーを先に `watch` する
  - 後から `await` する（状態リセットを防ぐため）

```dart
@riverpod
Future<String> currentUser(Ref ref) async {
  final data1Future = ref.watch(provider1.future);
  final data2Future = ref.watch(provider2.future);

  final data1 = await data1Future;
  final data2 = await data2Future;

  // 後続の処理
}
```

### エラー処理
- 非同期処理のエラーは適切にキャッチし、ユーザーに通知する
- Boolean 値や汎用的な例外ではなく、カスタム例外クラスを使用する
- 詳細なエラー情報が不要な場合は、メンバー変数を持たないシンプルな例外クラスを定義する

```dart
// 定義
class DeleteWorkLogException implements Exception {
  const DeleteWorkLogException();
}

// 使用
throw const DeleteWorkLogException();
```

### UI 構築
- UI 要素の表示/非表示は専用の状態管理クラスで管理する
  - 例: `HouseWorkVisibilities`
- 状態変更ロジックは Presenter に実装する
- 表示状態に基づくデータフィルタリングは Provider で実行する
- コンテンツ量が多い可能性がある場合は `SingleChildScrollView` を使用する
- デバイスのセーフエリアを考慮したパディングを追加する
  - 例: `EdgeInsets.only(left: 16 + MediaQuery.of(context).viewPadding.left, ...)`
- 可読性向上のためにウィジェットをクラスに分割する

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(),
        _Content(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Header');
  }
}
```

- ウィジェットの組み立ては 2 ステップで行う:
  1. ウィジェットをローカル変数に格納
  2. マージンを付けて組み立て

```dart
Widget build(BuildContext context) {
  // ステップ 1: ウィジェットをローカル変数に格納
  const firstText = Text('1st');
  const secondText = Text('2nd');

  // ステップ 2: マージンを付けて組み立て
  return Column(
    children: const [
      firstText,
      Padding(
        padding: EdgeInsets.only(top: 16),
        child: secondText,
      ),
    ],
  );
}
```

### テーマとスタイル
- テーマで定義された色を使用する
  - 例: `Theme.of(context).colorScheme.primary`
- テキストテーマで定義されたスタイルを使用する
  - 例: `Theme.of(context).textTheme.headline6`

### アクセシビリティ
- 操作可能な領域にツールチップを追加する
- UI に表示する文字列はウィジェット構築プロセス中に定義する

### 画面ナビゲーション
- 画面の `MaterialPageRoute` を静的フィールドで定義する
- 画面遷移時は静的フィールドと `Navigator` を使用する

```dart
class SomeScreen extends StatelessWidget {
  const SomeScreen({super.key});

  static const name = 'AnalysisScreen';

  static MaterialPageRoute<SomeScreen> route() =>
      MaterialPageRoute<SomeScreen>(
        builder: (_) => const SomeScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  Widget build(BuildContext context) {
    // 画面構築処理
  }
}

// 遷移時
Navigator.of(context).push(SomeScreen.route);
```

### ユニットテスト
- モックには `mocktail` を使用する
- テストケース間で同じダミー定数を使用する場合:
  - `group` 関数の先頭
  - `main` 関数の先頭
  - `setUp` 関数
  のいずれかで定義して共通化する

### テスト方針（重要）

**テストを書くべきもの**:
- ✅ **ビジネスロジック**: 計算処理、データ変換、判定ロジックなど
- ✅ **条件分岐**: if/else、switch文、三項演算子などの分岐処理
- ✅ **エラーハンドリング**: try-catch、例外スロー、エラー状態の処理
- ✅ **ユーザーインタラクション**: タップ、スワイプ、入力などのイベント処理
- ✅ **状態遷移**: 画面遷移、ナビゲーション、状態の変化
- ✅ **境界値テスト**: 範囲判定、閾値判定などの境界条件

**テストを書くべきでないもの（無駄なテスト）**:
- ❌ **単純なenum定義**: ロジックのないenumの列挙
- ❌ **Freezedによる自動生成データクラス**: `@freezed`で生成されるモデル
- ❌ **単純なgetter/setter**: ロジックのないプロパティアクセス
- ❌ **静的な表示内容**: 固定文字列、アイコン、色などの単純な表示
- ❌ **Extensionの単純なマッピング**: switch文で固定値を返すだけのExtension
- ❌ **コード生成されたファイル**: `*.g.dart`、`*.freezed.dart`など

**ウィジェットテストの範囲**:
- 条件分岐による表示切り替え（例: フラグによる表示/非表示）
- ユーザーインタラクション（例: ボタンタップでコールバック発火）
- エラー状態の表示（例: ローディング、エラーメッセージ）
- ナビゲーション（例: 画面遷移が正しく発火）

**テストカバレッジの目標**:
- ロジックを含むコード: 80%以上
- 単純な表示コード: カバレッジ不要
- 全体としては、意味のあるテストのみを書き、カバレッジ数値に固執しない

### 運用
- 実装時に想定していなかった例外やエラーが実行時に発生した場合、Crashlytics 経由でレポートを送信する処理を実装する

## アーキテクチャパターン

### ディレクトリ構造
```
client/lib/
├── data/              # データ層
│   ├── definition/    # 共通定義
│   ├── model/         # ドメインモデル（UI非依存）
│   ├── repository/    # リポジトリ（データの保持・取得を抽象化）
│   └── service/       # サービス（OS・Firebase との接続）
├── ui/                # UI 層
│   ├── component/     # 共通 UI コンポーネント
│   └── feature/       # 画面と画面ロジック（カテゴリ別サブフォルダ）
└── main.dart          # エントリーポイント
```

### レイヤー分離
- **data 層**: OS、Firebase、データストレージとのやり取り
- **ui 層**: 画面描画と表示ロジック
- ドメインモデルは UI に依存しない純粋なデータ構造
- リポジトリは具体的な保存先を抽象化する

## リント設定
- `pedantic_mono` パッケージを使用
- 生成されたファイル（`*.freezed.dart`, `*.g.dart`）は解析から除外
- `custom_lint` プラグインを有効化（Riverpod lint など）

## トラブルシューティングポリシー
以下の優先順位で解決策を採用する:

1. 公式ドキュメントとガイドラインに従った解決策を適用
2. 公式 issue で将来的な対応が計画されている場合は、その対応を待つ
3. 公式 issue で示された解決策を適用
4. Stack Overflow などのコミュニティで示された解決策を適用