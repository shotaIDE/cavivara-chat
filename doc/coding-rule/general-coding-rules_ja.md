# 開発ガイド

## 一般的なルール

### ドキュメンテーション

クラスアーキテクチャやディレクトリ構造に関して、新しい概念が導入された場合は、以下のドキュメントを更新する。

- [doc/rules-for-ai_japanese.md](/doc/rules-for-ai_japanese.md)
- [.clinerules](/.clinerules)
- [ARCHITECTURE.md](/ARCHITECTURE.md)

### スタイル

早期リターンを必ず使用して、ネストを減らす。

`try`-`catch` 文は、throw する可能性のある処理のみを囲み、できるだけ小さなスコープで使用する。

例:

```dart
// try-catch のスコープ外でも例外が発生する処理の戻り値を使用するため、定義を先にしておく
final CustomerInfo customerInfo;
try {
  // 例外が発生する可能性のある処理
  customerInfo = await Purchases.purchasePackage(product.package);
} catch (e) {
  throw PurchaseException();
}

// 後続処理
return customerInfo.entitlements;
```

関数引数における利用しない引数は、`_` という名前をつけて明示的に未使用であることを示しなさい。

例:

```dart
onTap: (_) { // 引数を使用しない場合、"_" として明示する
  // ...
},
```

利用されていないコードは、即時削除する。

### コードの一貫性を保つ

同様の機能を持つ処理は、同様の流れで実装する。周辺に同様の処理がすでに実装されていないかを確認し、実装されている場合はそれに従う。

- 特に、データの取得・変換・フィルタリングのフローは統一する。

### コメントの十分性を保つ

コードコメントを追加した場合は、最後に以下の観点で十分性を確認する。もし、過不足がある場合は、削除や追加を行う。

- コードの意図や目的を明確にする必要がある場合のみにコメントを追加する。コードの内容が明確な場合はコメントを避ける。
- 特に重要な注意点や落とし穴については、理由も含めて詳細に記述する。
- コメントは日本語で記述する。

### 命名の可読性を保つ

変数名はその目的や内容を明確に表す名前をつける。

一時変数においても意味のある名前をつける。

同じ種類のデータを扱う変数には、一貫した命名パターンを使用する。

### AI モデルへのプロンプトは英語で記述する

AI モデルへの入力となる文言は英語で記述する。英語のほうが、同じ指示を少ないトークン数で伝えられるためである。対象は、システムプロンプト、Function Calling の指示文、関数宣言やレスポンススキーマの説明文、関数の実行結果としてモデルに返すメッセージである。

以下は英訳すると意味がなくなるため、日本語のまま記述する。

- 語尾・使わせない表現・固有名詞など、モデルがそのまま出力する文言
- モデルがユーザーに話す知識データと、日本語のユーザー入力との一致に使うキーワード

ユーザーへの出力は日本語である必要があるため、システムプロンプトに常に日本語で答える指示を明記する。

プロンプトを変更した場合は、[doc/design/ai-prompt-language.md](/doc/design/ai-prompt-language.md) の日本語訳も更新する。

## Flutter に関するルール

### クラスの定義

クラスを実装する際、クラスを不変にできる場合は常に `const` コンストラクタを使用する。

### ドメインモデルの定義

ドメインモデルは明確に分離し、適切なファイルに配置する。

`freezed` を利用したイミュータブルなドメインモデルを定義する。`sealed class` を使用する場合も `freezed` を利用する。

### 関数型プログラミングを活用する

コレクション操作には関数型メソッドを使用する。

- 例: `map`, `where`, `fold`, `expand`

複雑なデータ変換は複数のステップに分けて可読性を高める。

コレクションの変換時は、変換された新しいコレクションが返却される処理を使用する。

- 例: `collection` パッケージの `sortedBy` など。

### 状態管理には `Riverpod` を適切に使用する

状態管理には `Riverpod` を使用する。

プロバイダーは `@riverpod` アノテーションを使用したコード生成を利用して定義する。

複数の非同期プロバイダーを扱う場合、状態リセットを防ぐために全てのプロバイダーを先に `watch` してから後で `await` する。

例:

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

### エラーハンドリングを適切に行う

非同期処理のエラーは適切にキャッチし、ユーザーに通知する。

ブール値や汎用的な例外を返す代わりに、カスタム例外クラスを使用して特定のエラー状態を表す。詳細なエラー情報が必要ない場合は、メンバー変数を持たないシンプルな例外クラスを定義する。

例:

```dart
// 定義
class DeleteWorkLogException implements Exception {
  const DeleteWorkLogException();
}

// 使用方法
throw const DeleteWorkLogException();
```

### UI を適切に構築する

UI 要素の表示・非表示状態は専用の状態管理クラスで管理する。

- 例: `HouseWorkVisibilities`

状態変更のロジックはプレゼンターに実装する。

表示・非表示の状態に基づいて、データをフィルタリングする処理はプロバイダー内で行う。

コンテンツが多くなる可能性がある場合は、`SingleChildScrollView`を使用してスクロール可能にする。

デバイスの安全領域を考慮したパディングを追加する。

- 例: `EdgeInsets.only(left: 16 + MediaQuery.of(context).viewPadding.left, ...)`

ウィジェットをクラスとして分割し、可読性を高める。

例:

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

class _Content extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Content');
  }
}
```

ウィジェットのローカル変数への格納 → 余白をつけて組み立て、の 2 ステップで処理を分ける。

例:

```dart
Widget build(BuildContext context) {
  // ウィジェットのローカル変数への格納
  const firstText = Text('1st');
  const secondText = Text('2nd');

  // 余白をつけて組み立て
  return = Column(
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

色はテーマとして定義されたもの利用する。

- 例: `Theme.of(context).colorScheme.primary`。

テキストのスタイルはテキストテーマとして定義されたものを利用する。

- 例: `Theme.of(context).textTheme.headline6`。

ユーザーが操作できる箇所にはツールチップを追加し、アクセシビリティを考慮する。

UI に表示する文字列は、ドメインモデルに含めず、ウィジェット構築の処理で定義する。

### 画面ナビゲーション

画面には静的フィールドで `MaterialPageRoute` を定義し、その画面に遷移する際には静的フィールドと`Navigator` を使用する。

例:

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
    // 画面のビルド処理
  }
}

// 遷移する際
Navigator.of(context).push(SomeScreen.route);
```

### ユニットテスト

- モックは `mocktail` を使用する。
- ダミーの定数について、テストケース間で同一のものを利用する場合は、`group`関数の先頭や`main`関数の先頭、または`setUp`関数内に定義して共通化する。

### 運用

- 実装時に想定していない Exception や Error が実行時に発生した場合は、Crashlytics でレポートを送信する処理を実装する。

## トラブルシューティング

### 方針

トラブルシューティングにおける解決策は、以下の優先順位で採用しなさい。

1. 公式のドキュメントやガイドラインに従った解決策を適用
2. 公式の Issue で将来の対応が予定されている場合は、その対応を待つ
3. 公式の Issue で示されている解決策を適用
4. Stack Overflow などのコミュニティで示されている解決策を適用
