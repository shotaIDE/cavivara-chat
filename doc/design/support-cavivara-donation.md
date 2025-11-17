# カヴィヴァラ応援課金機能 技術設計書

## 目的

ユーザーがカヴィヴァラを金銭的に応援できる課金機能の技術的な設計概要を示す。応援するとヴィヴァポイント(VP)が付与され、累計ポイントに応じて称号が獲得できる。機能追加を伴わない純粋なサポートとして実装する。

## アーキテクチャ

### レイヤー構成

本機能は以下の 4 層アーキテクチャで実装する:

1. **UI Layer** - ユーザーインターフェース

   - 設定画面(SettingsScreen)への応援メニュー追加
   - 応援画面(SupportCavivaraScreen)
   - 応援完了ダイアログ

2. **Repository Layer** - データ永続化

   - VivaPointRepository: ヴィヴァポイントの読み込み・保存
   - SupportTitleRepository: 称号の読み込み・計算

3. **Service Layer** - 外部サービス連携

   - InAppPurchaseService: in_app_purchase プラグインのラッパー

4. **Data Layer** - ストレージ
   - SharedPreferences: ヴィヴァポイントと称号をローカル保存

データフローは、UI Layer → Repository Layer → Service Layer/Data Layer の順で、Riverpod の状態管理により連携する。

## 主要コンポーネント

### 1. SupportPlan(ドメインモデル)

**配置**: `client/lib/data/model/support_plan.dart`

**役割**: 応援プランを表す enum とデータ構造

**内容**:

```dart
enum SupportPlan {
  small,   // ちょっと応援: ¥120, 1VP
  medium,  // しっかり応援: ¥370, 4VP
  large,   // めっちゃ応援: ¥610, 8VP
}
```

**関連クラス**:

```dart
@freezed
class SupportPlanDetail with _$SupportPlanDetail {
  const factory SupportPlanDetail({
    required SupportPlan plan,
    required String productId,      // App Store/Google Play の商品ID
    required int vivaPoint,         // 獲得VP
    required String thankYouMessage, // 感謝メッセージ
  }) = _SupportPlanDetail;
}
```

**特徴**:

- UI に依存しない純粋なドメインモデル
- 金額は App Store/Google Play の商品設定で管理
- Freezed を使用した不変データ構造

### 2. SupportTitle(称号モデル)

**配置**: `client/lib/data/model/support_title.dart`

**役割**: 累計 VP に応じた称号を表す enum

**内容**:

```dart
enum SupportTitle {
  none,           // 未応援: 0VP
  beginner,       // 応援ビギナー: 1VP
  supporter,      // 応援サポーター: 5VP
  expert,         // 応援エキスパート: 10VP
  master,         // 応援マスター: 20VP
  legend,         // 応援レジェンド: 50VP
  grandMaster,    // 応援グランドマスター: 100VP
}
```

### 3. SupportPlanExtension(UI 拡張)

**配置**: `client/lib/ui/component/support_plan_extension.dart`

**役割**: SupportPlan に UI 関連の機能を拡張

**提供機能**:

- `displayName`: UI 表示用の日本語名を返す
  - small → "ちょっと応援"
  - medium → "しっかり応援"
  - large → "めっちゃ応援"
- `icon`: 各プランのアイコンを返す
  - small → Icons.favorite_border
  - medium → Icons.favorite
  - large → Icons.volunteer_activism

**設計意図**:

- 関心の分離: データモデルと UI ロジックを分離
- テスタビリティ: モデル層のテストが UI 非依存

### 4. SupportTitleExtension(UI 拡張)

**配置**: `client/lib/ui/component/support_title_extension.dart`

**役割**: SupportTitle に UI 関連の機能を拡張

**提供機能**:

- `displayName`: UI 表示用の称号名を返す
- `requiredVivaPoint`: この称号に必要な累計 VP を返す
- `nextTitle`: 次の称号を返す(最高称号の場合は null)

### 5. VivaPointRepository(永続化)

**配置**: `client/lib/data/repository/viva_point_repository.dart`

**役割**: ヴィヴァポイントの読み込みと加算・保存

**主要機能**:

- `build()`: SharedPreferences から累計 VP を読み込み、デフォルトは 0
- `add(int point)`: 指定された VP を加算して保存

**実装方式**:

- Riverpod の @riverpod アノテーション
- AsyncValue で非同期状態を管理
- int 値を SharedPreferences に保存

### 6. SupportTitleRepository(計算)

**配置**: `client/lib/data/repository/support_title_repository.dart`

**役割**: 累計 VP から現在の称号と次の称号までの進捗を計算

**主要機能**:

- `build()`: VivaPointRepository を watch し、称号情報を計算
- `currentTitle`: 現在の称号を返す
- `nextTitle`: 次の称号を返す
- `pointsToNextTitle`: 次の称号まで必要な VP を返す
- `progressToNextTitle`: 次の称号までの進捗(0.0〜1.0)を返す

**実装方式**:

- Riverpod の @riverpod アノテーション
- VivaPointRepository に依存
- 計算ロジックのみで永続化は行わない

### 7. InAppPurchaseService(サービス層)

**配置**: `client/lib/data/service/in_app_purchase_service.dart`

**役割**: in_app_purchase プラグインのラッパー

**主要機能**:

- `initialize()`: InAppPurchase.instance の初期化
- `isAvailable()`: 課金機能の利用可否を確認
- `queryProductDetails(Set<String> productIds)`: 商品情報を取得
- `buyConsumable(ProductDetails product)`: 消費型商品を購入
- `purchaseStream`: 購入イベントのストリーム

**実装方式**:

- Riverpod の @riverpod アノテーション
- in_app_purchase パッケージを使用
- エラーハンドリング(PurchaseException)

**エラー処理**:

- ユーザーキャンセル: 静かに処理終了
- ネットワークエラー: ユーザーにエラーダイアログ表示
- 商品情報取得失敗: ユーザーにエラーダイアログ表示

### 8. PreferenceKey 拡張

**配置**: `client/lib/data/model/preference_key.dart`

**変更内容**: enum に `totalVivaPoint` を追加

**保存形式**:

- キー: "totalVivaPoint"
- 値: 累計 VP の int 値

### 9. SupportCavivaraScreen(UI)

**配置**: `client/lib/ui/feature/settings/support_cavivara_screen.dart`

**役割**: 応援画面の表示

**構成要素**:

1. **ヘッダーセクション**

   - カヴィヴァラアイコン
   - 説明文("カヴィヴァラを応援してくれてありがとうヴィヴァ!")
   - 応援金の使い道

2. **ポイント・称号表示セクション**

   - 累計ヴィヴァポイント表示
   - 現在の称号表示
   - 次の称号までの進捗バー
   - 次の称号まで必要な VP 表示

3. **応援プラン選択セクション**

   - 3 つのプランをカードで表示
   - 各プランに獲得 VP を表示
   - タップで購入処理開始

4. **注意書きセクション**
   - "応援課金では機能は追加されません"
   - "アプリの基本機能は引き続き無料でご利用いただけます"

**状態管理**:

- VivaPointRepository を watch
- SupportTitleRepository を watch
- InAppPurchaseService で商品情報取得・購入処理

### 10. 設定画面の更新

**配置**: `client/lib/ui/feature/settings/settings_screen.dart`

**追加内容**:

- "💝 カヴィヴァラを応援" ListTile を追加
  - アイコン: 💝(絵文字)
  - サブタイトルに累計 VP と現在の称号を表示(未応援時は表示なし)
  - タップで SupportCavivaraScreen に遷移

### 11. 応援完了ダイアログ

**配置**: `client/lib/ui/feature/settings/support_thank_you_dialog.dart`

**役割**: 応援完了時の感謝メッセージ表示

**構成要素**:

- カヴィヴァラアイコン
- 感謝メッセージ("応援ありがとうヴィヴァ!")
- プランに応じたメッセージ
- 獲得した VP 表示
- 閉じるボタン

## データフロー

### アプリ起動時

1. VivaPointRepository が build される
2. SharedPreferences から累計 VP を読み込み
3. SupportTitleRepository が VivaPointRepository を watch
4. 累計 VP から現在の称号と進捗を計算
5. 設定画面で称号情報を表示

### 応援画面表示時

1. ユーザーが設定画面の「カヴィヴァラを応援」をタップ
2. SupportCavivaraScreen に遷移
3. InAppPurchaseService.queryProductDetails で商品情報取得
4. 各プランの商品情報(価格など)を表示
5. 現在の累計 VP と称号、次の称号までの進捗を表示

### 応援課金実行時

1. ユーザーが応援プランをタップ
2. InAppPurchaseService.buyConsumable で購入処理開始
3. OS の購入ダイアログが表示される
4. ユーザーが購入を承認
5. purchaseStream で購入完了を検知
6. VivaPointRepository.add でプランに応じた VP を加算
7. SupportTitleRepository が自動的に再計算
8. 応援完了ダイアログを表示
9. VP と称号が更新される

### 称号獲得時

1. VP 加算により累計 VP が更新
2. SupportTitleRepository が自動的に再計算
3. 称号が変わった場合、UI が自動的に更新
4. 設定画面のサブタイトルも自動更新

## 実装手順

### フェーズ 1: データモデルとリポジトリ

1. `support_plan.dart` を作成
2. `support_title.dart` を作成
3. `preference_key.dart` に `totalVivaPoint` を追加
4. `viva_point_repository.dart` を作成
5. `support_title_repository.dart` を作成
6. `dart format` を実行
7. `dart fix --apply` を実行
8. ユニットテストを作成・実行

### フェーズ 2: サービス層

1. `pubspec.yaml` に `in_app_purchase` を追加
2. `in_app_purchase_service.dart` を作成
3. `dart format` を実行
4. `dart fix --apply` を実行
5. ユニットテスト(モック使用)を作成・実行

### フェーズ 3: UI 拡張

1. `support_plan_extension.dart` を作成
2. `support_title_extension.dart` を作成
3. `dart format` を実行
4. `dart fix --apply` を実行
5. ユニットテストを作成・実行

### フェーズ 4: 応援画面

1. `support_cavivara_screen.dart` を作成
2. `support_thank_you_dialog.dart` を作成
3. `settings_screen.dart` に応援メニューを追加
4. `dart format` を実行
5. `dart fix --apply` を実行
6. ウィジェットテストを作成

### フェーズ 5: App Store/Google Play 設定

1. App Store Connect で 3 つの消費型アイテムを登録
   - 商品 ID: `jp.cavivara.talk.support.small`
   - 商品 ID: `jp.cavivara.talk.support.medium`
   - 商品 ID: `jp.cavivara.talk.support.large`
2. Google Play Console で 3 つの消費型アイテムを登録(同じ商品 ID)
3. 各国の価格を設定
   - 日本: ¥120, ¥370, ¥610
   - アメリカ: $0.99, $2.99, $4.99
   - その他の国: 各国の通貨で同等の価格

### フェーズ 6: テストと検証

1. iOS でビルド・実行(Sandbox 環境)
2. Android でビルド・実行(テストアカウント)
3. 各プランの購入フロー確認
4. VP 加算の確認
5. 称号変更の確認
6. 永続化の確認(アプリ再起動後も累計 VP が保持されること)
7. エラーハンドリングの確認(キャンセル、ネットワークエラーなど)

## テスト戦略

### ユニットテスト

**対象**: Repository と Extension

**テストケース - VivaPointRepository**:

```dart
group('VivaPointRepository', () {
  test('初期値は0である', () async {
    // テスト実装
  });

  test('VPを加算して保存できる', () async {
    // テスト実装
  });

  test('累計VPが正しく計算される', () async {
    // テスト実装
  });
});
```

**テストケース - SupportTitleRepository**:

```dart
group('SupportTitleRepository', () {
  test('0VPの場合、称号はnoneである', () async {
    // テスト実装
  });

  test('1VPの場合、称号はbeginnerである', () async {
    // テスト実装
  });

  test('次の称号までの進捗が正しく計算される', () async {
    // テスト実装
  });

  test('最高称号の場合、nextTitleはnullである', () async {
    // テスト実装
  });
});
```

**テストケース - SupportPlanExtension**:

```dart
group('SupportPlanExtension', () {
  test('各プランの表示名が正しい', () {
    expect(SupportPlan.small.displayName, 'ちょっと応援');
    expect(SupportPlan.medium.displayName, 'しっかり応援');
    expect(SupportPlan.large.displayName, 'めっちゃ応援');
  });

  test('各プランのアイコンが設定されている', () {
    expect(SupportPlan.small.icon, isNotNull);
    expect(SupportPlan.medium.icon, isNotNull);
    expect(SupportPlan.large.icon, isNotNull);
  });
});
```

**テストケース - SupportTitleExtension**:

```dart
group('SupportTitleExtension', () {
  test('各称号の表示名が正しい', () {
    expect(SupportTitle.none.displayName, '');
    expect(SupportTitle.beginner.displayName, '応援ビギナー');
    // ...他の称号
  });

  test('各称号の必要VPが正しい', () {
    expect(SupportTitle.none.requiredVivaPoint, 0);
    expect(SupportTitle.beginner.requiredVivaPoint, 1);
    expect(SupportTitle.supporter.requiredVivaPoint, 5);
    // ...他の称号
  });

  test('nextTitleが正しく返される', () {
    expect(SupportTitle.none.nextTitle, SupportTitle.beginner);
    expect(SupportTitle.beginner.nextTitle, SupportTitle.supporter);
    expect(SupportTitle.grandMaster.nextTitle, null);
  });
});
```

### ウィジェットテスト

**対象**: 応援画面と応援完了ダイアログ

**テスト内容**:

- 応援画面が正しくレンダリングされるか
- 3 つのプランカードが表示されるか
- 累計 VP と称号が表示されるか
- 次の称号までの進捗バーが表示されるか
- 応援完了ダイアログが正しく表示されるか

### 統合テスト(手動テスト)

**対象**: 課金フロー全体

**テストシナリオ**:

1. 設定画面を開く
2. 「カヴィヴァラを応援」をタップ
3. 応援画面が表示される
4. 商品情報が正しく表示される
5. 「ちょっと応援」をタップ
6. OS の購入ダイアログが表示される
7. 購入を承認
8. 応援完了ダイアログが表示される
9. 累計 VP が 1VP 増加する
10. 称号が「応援ビギナー」に変わる
11. アプリを再起動
12. 累計 VP と称号が保持されている

## セキュリティとコンプライアンス

### App Store / Google Play ガイドライン準拠

- ✅ 「寄付」「投げ銭」ではなく「応援」という表現を使用
- ✅ 課金なしでも全機能が利用可能であることを明示
- ✅ 機能追加がないことを明確に説明
- ✅ 消費型アイテムとして実装(非消費型・サブスクリプションではない)

### プライバシー

- ✅ 個別の応援履歴(日時・金額の詳細)は記録しない
- ✅ 累計 VP と称号のみをローカル保存
- ✅ 課金情報はローカルデバイスにのみ保存(サーバー送信なし)

### エラーハンドリング

- ユーザーキャンセル: 静かに処理終了(エラーダイアログなし)
- ネットワークエラー: "ネットワーク接続を確認してください"
- 商品情報取得失敗: "商品情報の取得に失敗しました。しばらくしてから再度お試しください"
- 購入失敗: "購入処理に失敗しました。課金されていない場合は、もう一度お試しください"

## 後方互換性

### 既存機能への影響

- ✅ 新規機能のため既存機能への影響なし
- ✅ SharedPreferences に新しいキーを追加するのみ
- ✅ 既存の設定画面に新しいメニューを追加

### マイグレーション

マイグレーション不要。初回起動時に累計 VP は 0 から開始。

## 今後の拡張性

### 将来的な拡張案

- 応援履歴の詳細記録機能(オプトイン)
- 応援ランキング機能
- 応援ごとの特別メッセージ
- 季節限定の特別プラン
- 称号に応じた特別なカヴィヴァラアイコン

### 拡張時の考慮事項

- VP システムは維持
- 称号システムは拡張可能(新しい称号の追加)
- 応援プランは追加可能(新しい価格帯)

## 関連ドキュメント

- [要件定義書: カヴィヴァラ応援課金機能](../requirement/support-cavivara-donation.md)
- [in_app_purchase plugin documentation](https://pub.dev/packages/in_app_purchase)
- [App Store In-App Purchase Guidelines](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
- [Google Play Billing Guidelines](https://support.google.com/googleplay/android-developer/answer/140504)
