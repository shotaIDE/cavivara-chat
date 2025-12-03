---
name: Feature Mobile Development
about: Template for new mobile feature development
title: "[Feature-Mobile] US-2: ヴィヴァポイントを貯めて称号を獲得したい"
labels: ["feature", "mobile"]
assignees: ""
---

## Overview

ユーザーストーリー2「ヴィヴァポイントを貯めて称号を獲得したい」の実装。
応援課金時にヴィヴァポイント(VP)を付与し、累計VPに応じて7段階の称号を表示する機能を実装する。

**親Epic**: [Epic] カヴィヴァラ応援課金機能 (`doc/epic/support-cavivara-donation.md`)

**ユーザーストーリー**:
As a カヴィヴァラユーザー, I want 応援でVPを貯めて称号を獲得する so that 自分の貢献度を可視化し達成感を得られる

**受入基準**:
- 応援課金をするとヴィヴァポイントが付与される
- 金額が多いプランほど比例以上にお得なポイントが獲得できる
- 累計VPに応じて称号が付与される(7段階)
- 設定画面に現在の称号が表示される
- 応援画面に累計VP、現在の称号、次の称号までの進捗が表示される
- VPと称号データはローカルに保存される
- 応援履歴は内部的に記録されるが、ユーザーには表示されない

## Implementation

### TDD開発フロー

1. **テストファースト**: 各機能の実装前に、期待する動作を定義するテストを先に作成
2. **レッドフェーズ**: テストが失敗することを確認（まだ実装していないため）
3. **グリーンフェーズ**: テストをパスする最小限の実装
4. **リファクタリング**: コードの品質向上とコーディング規約への準拠確認

### 新規作成

#### 1. 称号モデルの定義

**ファイル**: `client/lib/data/model/supporter_title.dart`

```dart
enum SupporterTitle {
  newbie,        // 駆け出しヴィヴァサポーター (0-9VP)
  beginner,      // 初心ヴィヴァサポーター (10-29VP)
  intermediate,  // 一人前ヴィヴァサポーター (30-69VP)
  advanced,      // ベテランヴィヴァサポーター (70-149VP)
  expert,        // 熟練ヴィヴァサポーター (150-299VP)
  master,        // 達人ヴィヴァサポーター (300-499VP)
  legend,        // 伝説のヴィヴァサポーター (500VP~)
}
```

**目的**: 累計VPに応じた7段階の称号を定義

**テスト**: 不要（単純なenum定義のため）

#### 2. 称号拡張機能

**ファイル**: `client/lib/ui/component/supporter_title_extension.dart`

```dart
extension SupporterTitleExtension on SupporterTitle {
  String get displayName; // 称号の表示名
  String get description; // 称号の説明文
  int get requiredVP;     // 必要最低VP
  IconData get icon;      // 称号アイコン
  Color get color;        // 称号の色
}
```

**実装内容**:
- `displayName`: 「駆け出しヴィヴァサポーター」など
- `description`: 称号の説明（例: 「応援を始めたばかりのサポーター」）
- `requiredVP`: 各称号に必要な最低VP（0, 10, 30, 70, 150, 300, 500）
- `icon`: 称号に応じたアイコン（例: Icons.star, Icons.star_half, Icons.stars）
- `color`: 称号のグレードに応じた色（ブロンズ、シルバー、ゴールドなど）

**参考実装**: `client/lib/ui/component/support_plan_extension.dart`

**テスト**: `test/ui/component/supporter_title_extension_test.dart`
- requiredVPが昇順であること（境界値ロジックのテスト）

#### 3. 称号算出ロジック

**ファイル**: `client/lib/data/repository/viva_point_repository.dart`（既存ファイルに追加）

```dart
// 追加するメソッド
class VivaPointRepository {
  // 既存メソッドはそのまま...

  /// 累計VPから現在の称号を算出
  SupporterTitle getCurrentTitle(int totalVP);

  /// 次の称号を取得（最上位の場合はnull）
  SupporterTitle? getNextTitle(int totalVP);

  /// 次の称号までに必要なVP数を取得（最上位の場合は0）
  int getVPToNextTitle(int totalVP);
}
```

**実装内容**:
- `getCurrentTitle`: VPの範囲から称号を決定
- `getNextTitle`: 現在より1つ上の称号を返す（最上位の場合null）
- `getVPToNextTitle`: 次の称号に必要なVP数を計算

**テスト**: `test/data/repository/viva_point_repository_test.dart`（既存ファイルに追加）
- VP=0で駆け出しヴィヴァサポーター
- VP=10で初心ヴィヴァサポーター
- VP=500以上で伝説のヴィヴァサポーター
- 境界値テスト（9VP, 10VP, 29VP, 30VPなど）
- 次の称号とVP差の計算が正しいこと
- 最上位称号の場合、nextTitleがnull、VPToNextTitleが0

#### 4. 応援履歴モデル

**ファイル**: `client/lib/data/model/support_history.dart`

```dart
@freezed
class SupportHistory with _$SupportHistory {
  const factory SupportHistory({
    required DateTime timestamp,     // 応援日時
    required SupportPlan plan,       // 応援プラン
    required int earnedVP,           // 獲得VP
    required int totalVPAfter,       // 応援後の累計VP
  }) = _SupportHistory;

  factory SupportHistory.fromJson(Map<String, dynamic> json)
    => _$SupportHistoryFromJson(json);
}
```

**目的**: 内部的な応援履歴の記録（ユーザーには非表示）

**テスト**: 不要（Freezedによる単純なデータクラスのため）

#### 5. 応援履歴リポジトリ

**ファイル**: `client/lib/data/repository/support_history_repository.dart`

```dart
@riverpod
class SupportHistoryRepository extends _$SupportHistoryRepository {
  @override
  Future<List<SupportHistory>> build();

  /// 履歴を追加
  Future<void> addHistory(SupportHistory history);

  /// 履歴をクリア（デバッグ用）
  Future<void> clear();
}
```

**実装内容**:
- PreferenceServiceを使用してJSON形式でローカル保存
- PreferenceKeyに`supportHistoryList`を追加
- 履歴は時系列順に保存（最新が先頭）
- 取得・追加・クリアのCRUD操作を提供

**参考実装**: `client/lib/data/repository/viva_point_repository.dart`

**テスト**: `test/data/repository/support_history_repository_test.dart`
- 履歴の追加と取得が正しく動作すること
- 複数履歴が時系列順に保存されること
- クリア処理が正しく動作すること
- 初回起動時は空リストを返すこと

#### 6. 応援画面のPresenter

**ファイル**: `client/lib/ui/feature/settings/support_cavivara_presenter.dart`

```dart
@riverpod
class SupportCavivaraPresenter extends _$SupportCavivaraPresenter {
  @override
  Future<void> build();

  /// 累計VP取得
  int getTotalVP();

  /// 現在の称号取得
  SupporterTitle getCurrentTitle();

  /// 次の称号取得
  SupporterTitle? getNextTitle();

  /// 次の称号までのVP数取得
  int getVPToNextTitle();

  /// 次の称号までの進捗率取得（0.0-1.0）
  double getProgressToNextTitle();

  /// 応援処理（プラン選択 → 課金 → VP加算 → 履歴記録）
  Future<void> supportCavivara(SupportPlan plan);
}
```

**実装内容**:
- VivaPointRepositoryとSupportHistoryRepositoryを連携
- InAppPurchaseServiceで課金処理
- 課金成功時にVP加算と履歴記録
- エラーハンドリング（PurchaseExceptionの処理）

**テスト**: `test/ui/feature/settings/support_cavivara_presenter_test.dart`
- VPと称号の取得が正しいこと
- 進捗率計算が正しいこと（0.0-1.0の範囲）
- 最上位称号の場合、進捗率が1.0であること
- 課金成功時のVP加算が正しいこと
- 課金キャンセル時にVP加算されないこと
- エラー時の挙動が正しいこと

#### 7. 称号表示ウィジェット

**ファイル**: `client/lib/ui/feature/settings/supporter_title_badge.dart`

```dart
class SupporterTitleBadge extends StatelessWidget {
  final SupporterTitle title;
  final bool showDescription; // 説明文の表示有無

  @override
  Widget build(BuildContext context);
}
```

**実装内容**:
- 称号アイコン、名前、説明を表示
- Material Designに準拠したバッジデザイン
- 称号の色を反映

**テスト**: `test/ui/feature/settings/supporter_title_badge_test.dart`（ウィジェットテスト）
- showDescriptionフラグで説明文の表示が切り替わること（条件分岐のテスト）

#### 8. VP進捗表示ウィジェット

**ファイル**: `client/lib/ui/feature/settings/vp_progress_widget.dart`

```dart
class VPProgressWidget extends StatelessWidget {
  final int currentVP;
  final SupporterTitle currentTitle;
  final SupporterTitle? nextTitle;
  final int vpToNext;
  final double progress; // 0.0-1.0

  @override
  Widget build(BuildContext context);
}
```

**実装内容**:
- 累計VP表示
- 現在の称号バッジ
- 次の称号への進捗バー（LinearProgressIndicator）
- 「次の称号まであとXXVP」のテキスト
- 最上位称号の場合は「最高称号獲得！」のメッセージ

**テスト**: `test/ui/feature/settings/vp_progress_widget_test.dart`（ウィジェットテスト）
- 最上位称号の場合、特別なメッセージが表示されること（条件分岐のテスト）

#### 9. プラン選択カード

**ファイル**: `client/lib/ui/feature/settings/support_plan_card.dart`

```dart
class SupportPlanCard extends StatelessWidget {
  final SupportPlan plan;
  final String? priceString; // 商品情報から取得した価格
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context);
}
```

**実装内容**:
- プラン名、アイコン、価格、獲得VPを表示
- タップ可能なCard
- Material Designのelevation効果
- 獲得VPを目立たせる（例: 「+4VP」）

**参考実装**: `client/lib/ui/feature/pro/upgrade_to_pro_screen.dart`（`_FeatureItem`）

**テスト**: `test/ui/feature/settings/support_plan_card_test.dart`（ウィジェットテスト）
- タップイベントが発火すること（インタラクションのテスト）

#### 10. 感謝ダイアログ

**ファイル**: `client/lib/ui/feature/settings/thank_you_dialog.dart`

```dart
class ThankYouDialog extends StatelessWidget {
  final SupportPlan plan;
  final int earnedVP;
  final SupporterTitle? newTitle; // 新しい称号（昇格した場合のみ）

  static Future<void> show(
    BuildContext context, {
    required SupportPlan plan,
    required int earnedVP,
    SupporterTitle? newTitle,
  });

  @override
  Widget build(BuildContext context);
}
```

**実装内容**:
- カヴィヴァラのアバター画像
- プランに応じた感謝メッセージ（SupportPlanExtension.thankYouMessage）
- 獲得VP表示
- 称号昇格時は新称号のバッジと「おめでとう！」メッセージ
- 「閉じる」ボタン

**参考実装**:
- `client/lib/ui/component/clear_chat_confirmation_dialog.dart`
- `client/lib/ui/component/cavivara_avatar.dart`

**テスト**: `test/ui/feature/settings/thank_you_dialog_test.dart`（ウィジェットテスト）
- 称号昇格時に新称号が表示されること（条件分岐のテスト）

### 更新対象

#### 1. 応援画面の実装

**ファイル**: `client/lib/ui/feature/settings/support_cavivara_screen.dart`

**更新内容**:
- `StatelessWidget` → `ConsumerWidget`に変更
- Presenterを使用して状態管理
- 画面レイアウトの実装:
  1. VP進捗表示セクション
  2. 応援プランカードのリスト（3つ）
  3. 注意書き（「応援課金では機能は追加されません」など）
- 商品情報の非同期取得と表示
- 課金処理のエラーハンドリング
- 感謝ダイアログの表示

**レイアウト構成**:
```
Scaffold
├─ AppBar「カヴィヴァラを応援」
└─ SingleChildScrollView
   └─ Padding
      ├─ VPProgressWidget（累計VP・称号・進捗）
      ├─ SizedBox（スペーサー）
      ├─ Text「応援プランを選択」
      ├─ SupportPlanCard（small）
      ├─ SupportPlanCard（medium）
      ├─ SupportPlanCard（large）
      ├─ Divider
      └─ 注意書きテキスト群
```

**参考実装**:
- `client/lib/ui/feature/pro/upgrade_to_pro_screen.dart`（課金画面の例）
- `client/lib/ui/feature/settings/debug_screen.dart`（設定サブ画面の例）

**テスト**: `test/ui/feature/settings/support_cavivara_screen_test.dart`（ウィジェットテスト）
- 商品情報取得エラー時の表示が正しいこと（エラーハンドリングのテスト）

#### 2. 設定画面への称号表示追加

**ファイル**: `client/lib/ui/feature/settings/settings_screen.dart`

**更新内容**:
- ユーザー情報セクションに称号バッジを追加
- または、新規セクション「応援ステータス」を追加して称号を表示

**更新箇所**:
```dart
// 「ユーザー情報」セクション内、ユーザー情報タイルの下に追加
const SectionHeader(title: 'ユーザー情報'),
_buildUserInfoTile(context, userProfile, ref),
const _SupporterTitleDisplayTile(), // 新規追加
const Divider(),
```

**新規ウィジェット**: `_SupporterTitleDisplayTile`
- 累計VPと現在の称号を表示
- タップで応援画面に遷移
- Trailing iconは`_MoveScreenTrailingIcon()`を使用

**テスト**: 既存のテストに追加
- 称号表示タイルのタップで応援画面に遷移できること（ナビゲーションのテスト）

#### 3. PreferenceKeyの追加

**ファイル**: `client/lib/data/model/preference_key.dart`

**更新内容**:
```dart
enum PreferenceKey {
  // 既存項目...
  totalVivaPoint,
  supportHistoryList, // 新規追加
}
```

**テスト**: 不要（enumへの項目追加のみ）

#### 4. InAppPurchaseServiceの購入メソッド修正

**ファイル**: `client/lib/data/service/in_app_purchase_service.dart`

**更新内容**:
- `purchaseProduct`メソッドの戻り値を`Future<void>`から`Future<CustomerInfo>`に変更
- 購入完了時に`CustomerInfo`を返すようにする（VP加算などの後続処理のため）
- または、新規メソッド`Future<CustomerInfo> purchaseProductWithResult(String productId)`を追加

**注意**:
- このファイルは現在スタブ実装なので、RevenueCat統合時に正式実装
- テストはモックを使用

**テスト**: `test/data/service/in_app_purchase_service_test.dart`
- 購入成功時にCustomerInfoが返されること（モック）
- キャンセル時にPurchaseException.cancelledがスローされること
- エラー時にPurchaseException.uncategorizedがスローされること

## 型定義とインターフェース

### SupporterTitle（称号）

```dart
enum SupporterTitle {
  newbie,        // 0-9VP
  beginner,      // 10-29VP
  intermediate,  // 30-69VP
  advanced,      // 70-149VP
  expert,        // 150-299VP
  master,        // 300-499VP
  legend,        // 500VP~
}
```

### SupportHistory（応援履歴）

```dart
@freezed
class SupportHistory with _$SupportHistory {
  const factory SupportHistory({
    required DateTime timestamp,
    required SupportPlan plan,
    required int earnedVP,
    required int totalVPAfter,
  }) = _SupportHistory;
}
```

### SupportCavivaraPresenter（プレゼンター）

```dart
@riverpod
class SupportCavivaraPresenter extends _$SupportCavivaraPresenter {
  int getTotalVP();
  SupporterTitle getCurrentTitle();
  SupporterTitle? getNextTitle();
  int getVPToNextTitle();
  double getProgressToNextTitle();
  Future<void> supportCavivara(SupportPlan plan);
}
```

### VivaPointRepository拡張メソッド

```dart
class VivaPointRepository extends _$VivaPointRepository {
  // 既存メソッド...
  SupporterTitle getCurrentTitle(int totalVP);
  SupporterTitle? getNextTitle(int totalVP);
  int getVPToNextTitle(int totalVP);
}
```

## Figma リンク

（デザインが用意されている場合はここに記載）

## 備考

### 実装順序（TDD）

1. **Phase 1: モデルとロジック**
   - [ ] SupporterTitle enum作成（テスト不要）
   - [ ] SupporterTitleExtension作成 + テスト（requiredVP昇順チェック）
   - [ ] VivaPointRepositoryに称号算出ロジック追加 + テスト
   - [ ] SupportHistory model作成（テスト不要）
   - [ ] SupportHistoryRepository作成 + テスト

2. **Phase 2: UIコンポーネント**
   - [ ] SupporterTitleBadge作成 + ウィジェットテスト（条件分岐のみ）
   - [ ] VPProgressWidget作成 + ウィジェットテスト（条件分岐のみ）
   - [ ] SupportPlanCard作成 + ウィジェットテスト（インタラクションのみ）
   - [ ] ThankYouDialog作成 + ウィジェットテスト（条件分岐のみ）

3. **Phase 3: Presenterと画面**
   - [ ] SupportCavivaraPresenter作成 + テスト
   - [ ] SupportCavivaraScreen実装 + ウィジェットテスト（エラーハンドリングのみ）
   - [ ] SettingsScreenに称号表示追加 + テスト（ナビゲーションのみ）

4. **Phase 4: 統合とリファクタリング**
   - [ ] E2Eフローの動作確認（手動テスト）
   - [ ] コーディング規約チェック（dart format, dart fix --apply）
   - [ ] リファクタリング
   - [ ] ドキュメント更新

### 依存関係

- **前提条件**:
  - US-1（応援プランと課金基盤）が実装済みであること
  - InAppPurchaseServiceが動作すること（スタブでも可）
  - PreferenceServiceが動作すること

- **既存実装を活用**:
  - `SupportPlan` enum（既存）
  - `SupportPlanExtension`（既存）
  - `VivaPointRepository`（既存、メソッド追加）
  - `ProductPackage` model（既存）
  - `PurchaseException` model（既存）
  - `InAppPurchaseService`（既存、メソッド修正）

### コーディング規約チェックポイント

- [ ] early returnでネストを減らす
- [ ] try-catchのスコープを最小限にする
- [ ] 未使用引数は`_`で命名
- [ ] コメントは日本語で記述
- [ ] `const`コンストラクタを使用
- [ ] `freezed`でドメインモデルを定義
- [ ] Riverpodの`@riverpod`アノテーションを使用
- [ ] 非同期Providerは先に`watch`、後で`await`
- [ ] カスタム例外クラスを使用（Boolean禁止）
- [ ] `dart format`実行済み
- [ ] `dart fix --apply`実行済み

### テストカバレッジ目標

- ユニットテスト: 80%以上
- ウィジェットテスト: 主要UIコンポーネント全て
- E2Eテスト: 別タスクで実施

### パフォーマンス考慮事項

- PreferenceServiceへのアクセスは非同期だが、頻繁な読み書きは発生しない
- 応援履歴は内部記録のみで、UIには表示しないため、パフォーマンスへの影響は最小限
- 称号計算はO(1)のswitch文で実装するため、計算コストは無視できる

### アクセシビリティ

- 称号バッジにはセマンティクス情報を付与
- 進捗バーには進捗率のテキスト説明を追加
- カラーだけでなくアイコンでも情報を伝達

### セキュリティ

- 応援履歴はローカル保存のみ（サーバーに送信しない）
- PreferenceServiceを使用した安全なローカルストレージ
- 課金処理はInAppPurchaseServiceに委譲し、適切なエラーハンドリング

### 既存機能への影響

- 設定画面にUI要素追加（後方互換性維持）
- PreferenceKeyにenum追加（既存データに影響なし）
- VivaPointRepositoryにメソッド追加（既存メソッドに影響なし）
