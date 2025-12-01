---
name: Feature Mobile Development
about: US-1 応援の気持ちを金銭的に表現したい
title: "[Feature-Mobile] US-1: カヴィヴァラ応援課金 - 基本的な応援機能の実装"
labels: ["feature", "mobile"]
assignees: ""
---

## Overview

**User Story**: US-1 応援の気持ちを金銭的に表現したい

ユーザーがカヴィヴァラへの感謝を金銭的に表現するための基本的な応援機能を実装する。3つの金額プラン(¥120/¥370/¥610)から選択でき、各プランに応じたヴィヴァポイント(VP)が付与される。課金は都度課金(消費型)として実装し、アプリの基本機能は無料のまま維持する。

**受入基準** (US-1より):
- [x] 3つの金額プランから選択できる(¥120, ¥370, ¥610)
- [x] 各金額に応じた応援メッセージが表示される
- [x] 課金は都度課金(消費型)として実装される
- [x] 全てのユーザーが応援可能(アプリの基本機能は無料のまま)

## Implementation

### TDD アプローチ

本実装はt_wadaの推奨するTDD方式に従い、以下の順序で実装する:

1. **Red**: ユニットテストを先に書く(失敗することを確認)
2. **Green**: 最小限のコードでテストを通す
3. **Refactor**: コードをリファクタリングする

各フェーズごとに上記のサイクルを回す。

### フェーズ 1: ドメインモデルとExtension (TDD)

**目的**: 応援プランのドメインモデルとUI表示ロジックを実装する

#### 1.1 SupportPlan enum の実装

**新規作成**:
- `client/lib/data/model/support_plan.dart`

**内容**:
```dart
/// 応援プランを表すenum
enum SupportPlan {
  /// ちょっと応援
  small,

  /// しっかり応援
  medium,

  /// めっちゃ応援
  large,
}
```

#### 1.2 SupportPlanExtension の実装

**新規作成**:
- `client/lib/ui/component/support_plan_extension.dart`

**内容**: `SupportPlan` にUI関連の機能を拡張
- `displayName`: 表示名 ("ちょっと応援", "しっかり応援", "めっちゃ応援")
- `icon`: アイコン (`Icons.favorite_border`, `Icons.favorite`, `Icons.volunteer_activism`)
- `vivaPoint`: 獲得VP (1, 4, 8)
- `thankYouMessage`: 感謝メッセージ ("頑張って!", "いつもありがとう!", "これからも応援するヴィヴァ!")
- `productId`: RevenueCatの商品ID (iOS/Android共通)

**実装のポイント**:
- データモデル(`support_plan.dart`)はFlutter UIに依存しない
- UI関連の機能(アイコン、表示名)はExtensionに分離
- VP数とproductIdはビジネスロジックだがExtensionに配置(設計書に従う)

#### 1.3 PreferenceKey の拡張

**更新対象**:
- `client/lib/data/model/preference_key.dart`

**変更内容**: enum `PreferenceKey` に以下を追加
```dart
enum PreferenceKey {
  // ...既存のキー
  totalVivaPoint,  // 累計ヴィヴァポイント
}
```

### フェーズ 2: リポジトリ層 (TDD)

**目的**: ヴィヴァポイントの永続化と読み込みを実装する

#### 2.1 VivaPointRepository の実装

**新規作成**:
- `client/lib/data/repository/viva_point_repository.dart`

**役割**: ヴィヴァポイントの読み込み、加算、リセット

**主要メソッド**:
- `build()`: SharedPreferencesから累計VPを読み込み (デフォルト: 0)
- `add(int point)`: 指定されたVPを加算して保存
- `reset()`: VPを0にリセット (デバッグ用)

**実装パターン**:
- `last_talked_cavivara_id_repository.dart` を参考にする
- `@riverpod` アノテーションを使用
- `AsyncValue` で非同期状態を管理
- `PreferenceService` を使用してSharedPreferencesにアクセス

**テスト** (先に作成):
- `client/test/data/repository/viva_point_repository_test.dart`
  - 初期値が0であることを確認
  - VPを加算できることを確認 (例: 0 + 1 = 1)
  - 複数回加算した場合に累計が正しいことを確認 (例: 0 + 1 + 4 = 5)
  - リセット後に0になることを確認
  - PreferenceServiceが正しく呼び出されることを確認 (モック使用)

**実装のポイント**:
- `state = AsyncValue.data(newPoint)` で状態を更新
- `ref.mounted` チェックを忘れずに実装
- エラーハンドリングは後のフェーズで実装

### フェーズ 3: InAppPurchaseService の実装 (TDD)

**目的**: RevenueCat SDKのラッパーを実装する

#### 3.1 依存関係の追加

**更新対象**:
- `client/pubspec.yaml`

**追加内容**:
```yaml
dependencies:
  purchases_flutter: ^6.0.0  # RevenueCat SDK (最新の安定版を使用)
```

#### 3.2 カスタム例外クラスの実装

**新規作成**:
- `client/lib/data/model/purchase_exception.dart`

**内容**:
```dart
/// 購入処理に失敗した場合の例外
class PurchaseException implements Exception {
  const PurchaseException();
}
```

#### 3.3 独自ラッパークラスの実装

**新規作成**:
- `client/lib/data/model/product_package.dart`

**内容**:
```dart
/// 商品パッケージ情報（RevenueCatのPackageをラップ）
@freezed
class ProductPackage with _$ProductPackage {
  const factory ProductPackage({
    required String identifier,
    required String productId,
    required String priceString,
  }) = _ProductPackage;
}
```

**役割**: RevenueCatの`Package`をアプリケーション独自のモデルにラップし、外部依存を分離

#### 3.4 InAppPurchaseService の実装

**新規作成**:
- `client/lib/data/service/in_app_purchase_service.dart`

**役割**: RevenueCat SDKのラッパー

**主要メソッド**:
- `build()`: RevenueCat SDKの初期化
- `getAvailableProducts()`: 利用可能な商品を`List<ProductPackage>`として取得
- `purchaseProduct(String productId)`: 商品IDを指定して購入

**内部メソッド**:
- `_convertToProductPackage(Package)`: RevenueCatの`Package`を`ProductPackage`に変換
- `_completePurchase(CustomerInfo)`: 購入完了処理 (VP加算)
- `_handlePurchaseError(PurchasesErrorCode)`: エラーハンドリング
- `_getPlanFromProductId(String)`: productIdからSupportPlanを取得

**テスト** (先に作成):
- `client/test/data/service/in_app_purchase_service_test.dart`
  - モックを使用してRevenueCat SDKの動作をシミュレート
  - `getAvailableProducts()` が`ProductPackage`のリストを返すことを確認
  - `purchaseProduct()` が呼び出されることを確認
  - 購入完了時にVPが加算されることを確認
  - ユーザーキャンセル時(`purchaseCancelledError`)にエラーが報告されないことを確認
  - その他のエラー時にErrorReportServiceが呼び出されることを確認

**実装のポイント**:
- RevenueCat SDKは初期化時にAPIキーが必要
- RevenueCatの`Package`や`CustomerInfo`を直接返さず、`ProductPackage`などの独自クラスにラップ
- productIdはRevenueCatダッシュボードで管理される共通ID（iOS/Android共通）
- ユーザーキャンセル (`PurchasesErrorCode.purchaseCancelledError`) は静かに処理
- その他のエラーは `ErrorReportService` に報告
- 購入完了時は `CustomerInfo.entitlements` から購入情報を取得し、`VivaPointRepository.add()` を呼び出す
- RevenueCatは自動的に購入を完了するため、手動での `completePurchase()` は不要

### フェーズ 4: UI層 - 設定画面への応援メニュー追加 (TDD)

**目的**: 設定画面に「💝 カヴィヴァラを応援」メニューを追加する

#### 4.1 設定画面の更新

**更新対象**:
- `client/lib/ui/feature/settings/settings_screen.dart`

**追加内容**:
1. `_SupportCavivaraTile` プライベートウィジェットを追加
2. 「アプリについて」セクションと「デバッグ」セクションの間に配置

**実装例**:
```dart
class _SupportCavivaraTile extends StatelessWidget {
  const _SupportCavivaraTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.favorite, color: Colors.red),
      title: const Text('💝 カヴィヴァラを応援'),
      trailing: const _MoveScreenTrailingIcon(),
      onTap: () {
        Navigator.of(context).push(SupportCavivaraScreen.route());
      },
    );
  }
}
```

**配置場所**:
```dart
// アプリについてセクション
const SectionHeader(title: 'アプリについて'),
const _ReviewAppTile(),
const _ShareAppTile(),
const _TermsOfServiceTile(),
const _PrivacyPolicyTile(),
const _LicenseTile(),
const _SupportCavivaraTile(),  // ← ここに追加
const Divider(),
// デバッグセクション
const SectionHeader(title: 'デバッグ'),
```

**ウィジェットテスト** (先に作成):
- `client/test/ui/feature/settings/settings_screen_test.dart` に追加
  - 「💝 カヴィヴァラを応援」メニューが表示されることを確認
  - タップすると `SupportCavivaraScreen` に遷移することを確認
  - アイコンが赤いハートアイコンであることを確認

### フェーズ 5: UI層 - 応援画面の実装 (TDD)

**目的**: 応援プランを選択できる画面を実装する

#### 5.1 SupportCavivaraScreen の実装

**新規作成**:
- `client/lib/ui/feature/settings/support_cavivara_screen.dart`

**画面構成**:
1. **AppBar**: タイトル「カヴィヴァラを応援」
2. **ヘッダーセクション**:
   - カヴィヴァラアイコン (`CavivaraAvatar` を使用)
   - 説明文「カヴィヴァラを応援してくれてありがとうヴィヴァ!」
   - 応援金の使い道の説明
3. **応援プラン選択セクション**:
   - 3つのプランをカード形式で表示 (`Card` ウィジェット)
   - 各カードに表示する情報:
     - プラン名 (`SupportPlan.displayName`)
     - アイコン (`SupportPlan.icon`)
     - 価格 (商品情報から取得、取得中は "読み込み中...")
     - 獲得VP (`SupportPlan.vivaPoint` + "VP")
   - タップで購入処理を開始
4. **注意書きセクション**:
   - 「応援課金では機能は追加されません」
   - 「アプリの基本機能は引き続き無料でご利用いただけます」

**状態管理**:
- `InAppPurchaseService` で商品情報（`ProductPackage`のリスト）を取得
- 商品情報取得中は `CircularProgressIndicator` を表示
- 商品情報取得失敗時はエラーメッセージを表示
- 購入処理中は該当カードに `CircularProgressIndicator` を表示

**ナビゲーション**:
```dart
static const name = 'SupportCavivaraScreen';

static MaterialPageRoute<SupportCavivaraScreen> route() =>
    MaterialPageRoute<SupportCavivaraScreen>(
      builder: (_) => const SupportCavivaraScreen(),
      settings: const RouteSettings(name: name),
    );
```

**ウィジェットテスト** (先に作成):
- `client/test/ui/feature/settings/support_cavivara_screen_test.dart`
  - 画面が正しくレンダリングされることを確認
  - 3つのプランカードが表示されることを確認
  - 各カードに正しいプラン名が表示されることを確認
  - 各カードに獲得VPが表示されることを確認
  - 注意書きが表示されることを確認
  - プランタップ時に購入処理が開始されることを確認 (モック使用)

**実装のポイント**:
- `SingleChildScrollView` でスクロール可能にする
- 既存の `CavivaraAvatar` コンポーネントを再利用
- 商品情報取得は画面表示時に1回のみ実行
- 商品情報はキャッシュして再利用
- デバイスのセーフエリアを考慮したパディング

#### 5.2 プランカードウィジェットの実装

**新規作成**:
- `client/lib/ui/feature/settings/support_plan_card.dart` (プライベートウィジェットとして `support_cavivara_screen.dart` 内に実装してもよい)

**役割**: 1つの応援プランを表示するカード

**Props**:
- `plan`: `SupportPlan`
- `productPackage`: `ProductPackage?` (商品パッケージ情報)
- `isLoading`: `bool` (購入処理中フラグ)
- `onTap`: `VoidCallback` (タップ時のコールバック)

**表示内容**:
- アイコン
- プラン名
- 価格 (productPackageのpriceStringから取得、nullなら "読み込み中...")
- 獲得VP

**ウィジェットテスト** (先に作成):
- `client/test/ui/feature/settings/support_plan_card_test.dart`
  - 各要素が正しく表示されることを確認
  - 読み込み中の表示を確認
  - タップイベントが発火することを確認

### フェーズ 6: UI層 - デバッグ画面へのVPリセット機能追加 (TDD)

**目的**: デバッグ画面にVPをリセットできる機能を追加する

#### 6.1 デバッグ画面の更新

**更新対象**:
- `client/lib/ui/feature/settings/debug_screen.dart`

**追加内容**:
1. `_ResetVivaPointTile` プライベートウィジェットを追加
2. デバッグメニュー内に配置

**実装例**:
```dart
class _ResetVivaPointTile extends ConsumerWidget {
  const _ResetVivaPointTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.restore),
      title: const Text('VPをリセット'),
      onTap: () async {
        // 確認ダイアログを表示
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('VPをリセット'),
            content: const Text('累計ヴィヴァポイントを0にリセットします。よろしいですか?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('リセット'),
              ),
            ],
          ),
        );

        if (confirmed == true && context.mounted) {
          await ref.read(vivaPointRepositoryProvider.notifier).reset();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('VPをリセットしました')),
            );
          }
        }
      },
    );
  }
}
```

**配置場所**:
デバッグ画面内の適切な位置（他のデバッグ機能と一緒に配置）

**ウィジェットテスト** (先に作成):
- `client/test/ui/feature/settings/debug_screen_test.dart` に追加
  - 「VPをリセット」メニューが表示されることを確認
  - タップすると確認ダイアログが表示されることを確認
  - 「リセット」ボタンをタップすると `reset()` が呼び出されることを確認 (モック使用)
  - 「キャンセル」ボタンをタップすると何も実行されないことを確認
  - リセット後にSnackBarが表示されることを確認

### フェーズ 7: UI層 - 応援完了ダイアログの実装 (TDD)

**目的**: 応援完了時に感謝メッセージを表示する

#### 7.1 SupportThankYouDialog の実装

**新規作成**:
- `client/lib/ui/feature/settings/support_thank_you_dialog.dart`

**役割**: 応援完了時の感謝ダイアログ

**Props**:
- `plan`: `SupportPlan` (購入したプラン)

**表示内容**:
1. カヴィヴァラアイコン
2. 感謝メッセージ「応援ありがとうヴィヴァ!」
3. プランに応じたメッセージ (`plan.thankYouMessage`)
4. 獲得したVP表示 (例: "+1VP")
5. 閉じるボタン

**実装例**:
```dart
class SupportThankYouDialog extends StatelessWidget {
  const SupportThankYouDialog({
    required this.plan,
    super.key,
  });

  final SupportPlan plan;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // カヴィヴァラアイコン
          const CavivaraAvatar(size: 80),
          const SizedBox(height: 16),
          // 感謝メッセージ
          const Text(
            '応援ありがとうヴィヴァ!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // プランに応じたメッセージ
          Text(plan.thankYouMessage),
          const SizedBox(height: 8),
          // 獲得VP
          Text(
            '+${plan.vivaPoint}VP',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
```

**ウィジェットテスト** (先に作成):
- `client/test/ui/feature/settings/support_thank_you_dialog_test.dart`
  - ダイアログが正しく表示されることを確認
  - 感謝メッセージが表示されることを確認
  - プランに応じたメッセージが表示されることを確認
  - 獲得VPが正しく表示されることを確認 (各プラン: 1VP, 4VP, 8VP)
  - 閉じるボタンをタップするとダイアログが閉じることを確認

#### 7.2 応援完了時のダイアログ表示

**更新対象**:
- `client/lib/data/service/in_app_purchase_service.dart`

**変更内容**:
`_completePurchase()` メソッド内で、VP加算後にダイアログを表示する処理を追加。

**実装のポイント**:
- ダイアログ表示はServiceではなくUI側で行う
- `InAppPurchaseService` は購入完了を通知するためのコールバックまたはストリームを提供
- または、`VivaPointRepository` の状態変更を監視してダイアログを表示

**推奨実装**:
`SupportCavivaraScreen` で `ref.listen` を使用して `VivaPointRepository` の変更を監視し、VP増加時にダイアログを表示する。

```dart
ref.listen(vivaPointRepositoryProvider, (previous, next) {
  if (previous?.valueOrNull != null && next.valueOrNull != null) {
    final previousVp = previous!.valueOrNull!;
    final currentVp = next.valueOrNull!;
    if (currentVp > previousVp) {
      // VP が増加した = 購入完了
      final addedVp = currentVp - previousVp;
      final plan = _getPlanFromVp(addedVp);  // VP差分からプランを特定
      if (plan != null) {
        showDialog<void>(
          context: context,
          builder: (_) => SupportThankYouDialog(plan: plan),
        );
      }
    }
  }
});
```

### フェーズ 8: エラーハンドリングの実装

**目的**: ユーザーフレンドリーなエラー処理を実装する

#### 8.1 エラーメッセージの定義

**更新対象**:
- `client/lib/ui/feature/settings/support_cavivara_screen.dart`

**追加内容**:
- ネットワークエラー時のSnackBar表示
- 商品情報取得失敗時のエラー表示
- 購入失敗時のSnackBar表示

**エラーメッセージ**:
- ネットワークエラー: "ネットワーク接続を確認してください"
- 商品情報取得失敗: "商品情報の取得に失敗しました。しばらくしてから再度お試しください"
- 購入失敗: "購入処理に失敗しました。課金されていない場合は、もう一度お試しください"

**実装のポイント**:
- ユーザーキャンセルはエラーとして扱わない (何も表示しない)
- `ScaffoldMessenger.of(context).showSnackBar()` を使用
- エラー発生時も既存の状態を保持 (画面を閉じない)

#### 8.2 エラーハンドリングのテスト

**テスト** (追加):
- `client/test/ui/feature/settings/support_cavivara_screen_test.dart` に追加
  - 商品情報取得失敗時にエラーメッセージが表示されることを確認
  - 購入失敗時にSnackBarが表示されることを確認
  - ユーザーキャンセル時に何も表示されないことを確認

### フェーズ 9: コード品質の確保

#### 9.1 フォーマットとリント

**実行コマンド**:
```bash
# 全ファイルをフォーマット
dart format client/lib/data/model/support_plan.dart
dart format client/lib/data/model/product_package.dart
dart format client/lib/ui/component/support_plan_extension.dart
dart format client/lib/data/repository/viva_point_repository.dart
dart format client/lib/data/service/in_app_purchase_service.dart
dart format client/lib/ui/feature/settings/settings_screen.dart
dart format client/lib/ui/feature/settings/support_cavivara_screen.dart
dart format client/lib/ui/feature/settings/support_thank_you_dialog.dart

# または一括フォーマット
dart format client/

# リント自動修正
dart fix --apply
```

#### 9.2 静的解析の確認

**実行コマンド**:
```bash
cd client
flutter analyze
```

**確認事項**:
- 警告が0件であること
- エラーが0件であること
- リント違反がないこと

#### 9.3 テストの実行

**実行コマンド**:
```bash
cd client
flutter test
```

**確認事項**:
- 全てのユニットテストが通ること
- 全てのウィジェットテストが通ること
- テストカバレッジが十分であること

### フェーズ 10: RevenueCat と App Store / Google Play の設定

**注意**: このフェーズは開発者が各種コンソールで手動で実施する

#### 10.1 RevenueCat プロジェクトのセットアップ

1. RevenueCat ダッシュボード (https://app.revenuecat.com/) にログイン
2. 新規プロジェクトを作成、またはアプリを追加
3. iOS と Android のアプリを登録
   - iOS: App Store Connect の Bundle ID を入力
   - Android: Google Play Console の Package Name を入力
4. API キーを取得（後でアプリに設定）

#### 10.2 App Store Connect での商品登録

1. App Store Connect にログイン
2. アプリを選択 → 「機能」→ 「App 内課金」
3. 3つの消費型商品を登録:

**商品1: ちょっと応援**
- 商品ID: `small_support` (RevenueCat共通ID)
- 種類: 消費型
- 表示名: ちょっと応援
- 説明: カヴィヴァラをちょっと応援
- 価格: ¥120 (Tier 1)

**商品2: しっかり応援**
- 商品ID: `medium_support` (RevenueCat共通ID)
- 種類: 消費型
- 表示名: しっかり応援
- 説明: カヴィヴァラをしっかり応援
- 価格: ¥370 (Tier 3)

**商品3: めっちゃ応援**
- 商品ID: `large_support` (RevenueCat共通ID)
- 種類: 消費型
- 表示名: めっちゃ応援
- 説明: カヴィヴァラをめっちゃ応援
- 価格: ¥610 (Tier 5)

#### 10.3 Google Play Console での商品登録

1. Google Play Console にログイン
2. アプリを選択 → 「収益化」→ 「アプリ内商品」
3. 3つの消費型商品を登録（商品IDはApp Store Connectと同じRevenueCat共通IDを使用）

**価格設定**:
- 日本: ¥120, ¥370, ¥610
- アメリカ: $0.99, $2.99, $4.99
- その他の国: 各国の通貨で同等の価格

#### 10.4 RevenueCat での商品設定

1. RevenueCat ダッシュボードに戻る
2. 「Products」セクションで、App Store ConnectとGoogle Play Consoleで登録した商品をインポート
3. 「Offerings」を作成し、3つの商品をパッケージとして追加:
   - Offering ID: `default`
   - Package 1: `small_support` → Identifier: `small`
   - Package 2: `medium_support` → Identifier: `medium`
   - Package 3: `large_support` → Identifier: `large`

### フェーズ 11: 動作確認とデバッグ

#### 11.1 iOS Sandbox環境でのテスト

**テスト項目**:
- [ ] RevenueCat SDKが正しく初期化されること
- [ ] 設定画面に「💝 カヴィヴァラを応援」メニューが表示されること
- [ ] 応援画面に3つのプランが表示されること
- [ ] 各プランの価格が正しく表示されること (RevenueCat Sandboxテスト価格)
- [ ] プランをタップすると購入ダイアログが表示されること
- [ ] Sandboxアカウントで購入が完了すること
- [ ] 購入完了後に感謝ダイアログが表示されること
- [ ] VPが正しく加算されること
- [ ] アプリを再起動してもVPが保持されること
- [ ] RevenueCatダッシュボードで購入履歴が確認できること

#### 11.2 Android テストアカウントでのテスト

**テスト項目**:
- iOS Sandbox環境と同じテスト項目を実施

#### 11.3 エラーケースのテスト

**テスト項目**:
- [ ] 機内モードで商品情報取得失敗のエラーメッセージが表示されること
- [ ] 購入ダイアログでキャンセルした場合、エラーが表示されないこと
- [ ] ネットワークエラー時に適切なメッセージが表示されること

## 型定義とインターフェース

### SupportPlan (enum)

```dart
enum SupportPlan {
  small,   // ちょっと応援
  medium,  // しっかり応援
  large,   // めっちゃ応援
}
```

### SupportPlanExtension

```dart
extension SupportPlanExtension on SupportPlan {
  /// プランの表示名
  String get displayName;

  /// プランのアイコン
  IconData get icon;

  /// 獲得VP
  int get vivaPoint;

  /// 感謝メッセージ
  String get thankYouMessage;

  /// RevenueCatの商品ID (iOS/Android共通)
  String get productId;
}
```

### VivaPointRepository

```dart
@riverpod
class VivaPointRepository extends _$VivaPointRepository {
  @override
  Future<int> build();

  /// VPを加算
  Future<void> add(int point);

  /// VPをリセット (デバッグ用)
  Future<void> reset();
}
```

### ProductPackage

```dart
@freezed
class ProductPackage with _$ProductPackage {
  const factory ProductPackage({
    required String identifier,
    required String productId,
    required String priceString,
  }) = _ProductPackage;
}
```

### InAppPurchaseService

```dart
@riverpod
class InAppPurchaseService extends _$InAppPurchaseService {
  @override
  Future<void> build();

  /// 利用可能な商品を取得
  Future<List<ProductPackage>> getAvailableProducts();

  /// 商品IDを指定して購入
  Future<void> purchaseProduct(String productId);
}
```

### カスタム例外

```dart
/// 購入処理に失敗
class PurchaseException implements Exception {
  const PurchaseException();
}
```

## Figma リンク

(なし)

## 備考

### 実装の優先順位

1. **フェーズ 1〜3**: データ層の実装 (モデル、リポジトリ、サービス)
2. **フェーズ 4〜7**: UI層の実装 (設定画面、応援画面、デバッグ画面、ダイアログ)
3. **フェーズ 8**: エラーハンドリング
4. **フェーズ 9**: コード品質の確保
5. **フェーズ 10〜11**: ストア設定とテスト

### 他のUser Storyとの関係

- **US-2** (ヴィヴァポイントを貯めて称号を獲得したい): 本実装でVPの基礎が完成。US-2では称号システムを追加
- **US-3** (応援後に感謝を受け取りたい): 本実装で応援完了ダイアログを実装済み
- **US-4** (課金しても機能が変わらないことを理解したい): 本実装で注意書きを表示済み

### 既存機能への影響

- **設定画面**: メニュー項目が1つ増えるのみ。既存機能への影響なし
- **SharedPreferences**: 新しいキー `totalVivaPoint` を追加。既存データへの影響なし
- **パフォーマンス**: SharedPreferencesへの読み書きが増えるが、影響は軽微
- **後方互換性**: 既存ユーザーの累計VPは0から開始。マイグレーション不要

### 注意事項

1. **TDDの徹底**: 必ずテストを先に書き、その後実装する
2. **Sandboxテスト**: 実機でのテストは必ずSandbox/テストアカウントを使用
3. **エラーハンドリング**: ユーザーキャンセルはエラーとして扱わない
4. **コンプライアンス**: 「寄付」「投げ銭」という表現は使用しない
5. **後続実装**: 応援履歴の詳細記録はUS-2以降で検討 (本実装では累計VPのみ記録)

### 参考資料

- [doc/design/support-cavivara-donation.md](/doc/design/support-cavivara-donation.md) - 技術設計書
- [doc/epic/support-cavivara-donation.md](/doc/epic/support-cavivara-donation.md) - Epic要件定義
- [doc/coding-rule/general-coding-rules.md](/doc/coding-rule/general-coding-rules.md) - コーディング規約
- [purchases_flutter package](https://pub.dev/packages/purchases_flutter) - RevenueCat SDK for Flutter
- [RevenueCat Documentation](https://www.revenuecat.com/docs/) - RevenueCat公式ドキュメント
- [App Store Review Guidelines - In-App Purchase](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
- [Google Play Billing Guidelines](https://support.google.com/googleplay/android-developer/answer/140504)
