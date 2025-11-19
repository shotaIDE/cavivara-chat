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

```dart
extension SupportPlanExtension on SupportPlan {
  String get displayName {
    switch (this) {
      case SupportPlan.small:
        return 'ちょっと応援';
      case SupportPlan.medium:
        return 'しっかり応援';
      case SupportPlan.large:
        return 'めっちゃ応援';
    }
  }

  IconData get icon {
    switch (this) {
      case SupportPlan.small:
        return Icons.favorite_border;
      case SupportPlan.medium:
        return Icons.favorite;
      case SupportPlan.large:
        return Icons.volunteer_activism;
    }
  }

  int get vivaPoint {
    switch (this) {
      case SupportPlan.small:
        return 1;
      case SupportPlan.medium:
        return 4;
      case SupportPlan.large:
        return 8;
    }
  }

  String get thankYouMessage {
    switch (this) {
      case SupportPlan.small:
        return '頑張って!';
      case SupportPlan.medium:
        return 'いつもありがとう!';
      case SupportPlan.large:
        return 'これからも応援するヴィヴァ!';
    }
  }

  String get productId {
    switch (this) {
      case SupportPlan.small:
        return 'jp.cavivara.talk.support.small';
      case SupportPlan.medium:
        return 'jp.cavivara.talk.support.medium';
      case SupportPlan.large:
        return 'jp.cavivara.talk.support.large';
    }
  }
}
```

**設計意図**:

- 関心の分離: データモデルと UI ロジックを分離
- テスタビリティ: モデル層のテストが UI 非依存
- 依存関係の明確化: data/model は Flutter UI に依存しない
- 再利用性: 同じモデルを異なる UI 実装で使用可能

### 4. SupportTitleExtension(UI 拡張)

**配置**: `client/lib/ui/component/support_title_extension.dart`

**役割**: SupportTitle に UI 関連の機能を拡張

**提供機能**:

```dart
extension SupportTitleExtension on SupportTitle {
  String get displayName {
    switch (this) {
      case SupportTitle.none:
        return '';
      case SupportTitle.beginner:
        return '応援ビギナー';
      case SupportTitle.supporter:
        return '応援サポーター';
      case SupportTitle.expert:
        return '応援エキスパート';
      case SupportTitle.master:
        return '応援マスター';
      case SupportTitle.legend:
        return '応援レジェンド';
      case SupportTitle.grandMaster:
        return '応援グランドマスター';
    }
  }

  int get requiredVivaPoint {
    switch (this) {
      case SupportTitle.none:
        return 0;
      case SupportTitle.beginner:
        return 1;
      case SupportTitle.supporter:
        return 5;
      case SupportTitle.expert:
        return 10;
      case SupportTitle.master:
        return 20;
      case SupportTitle.legend:
        return 50;
      case SupportTitle.grandMaster:
        return 100;
    }
  }

  SupportTitle? get nextTitle {
    switch (this) {
      case SupportTitle.none:
        return SupportTitle.beginner;
      case SupportTitle.beginner:
        return SupportTitle.supporter;
      case SupportTitle.supporter:
        return SupportTitle.expert;
      case SupportTitle.expert:
        return SupportTitle.master;
      case SupportTitle.master:
        return SupportTitle.legend;
      case SupportTitle.legend:
        return SupportTitle.grandMaster;
      case SupportTitle.grandMaster:
        return null;
    }
  }
}
```

**設計意図**:

- 称号の判定ロジックを一元管理
- UI からビジネスロジックを分離
- テスタビリティの向上

### 5. VivaPointRepository(永続化)

**配置**: `client/lib/data/repository/viva_point_repository.dart`

**役割**: ヴィヴァポイントの読み込みと加算・保存

**主要機能**:

- `build()`: SharedPreferences から累計 VP を読み込み、デフォルトは 0
- `add(int point)`: 指定された VP を加算して保存

**実装例**:

```dart
@riverpod
class VivaPointRepository extends _$VivaPointRepository {
  @override
  Future<int> build() async {
    final preferenceService = ref.read(preferenceServiceProvider);
    final value = await preferenceService.getInt(
      PreferenceKey.totalVivaPoint,
    );

    return value ?? 0;
  }

  Future<void> add(int point) async {
    final currentPoint = state.valueOrNull ?? 0;
    final newPoint = currentPoint + point;

    final preferenceService = ref.read(preferenceServiceProvider);
    await preferenceService.setInt(
      PreferenceKey.totalVivaPoint,
      value: newPoint,
    );

    if (!ref.mounted) {
      return;
    }
    state = AsyncValue.data(newPoint);
  }
}
```

**実装方式**:

- Riverpod の @riverpod アノテーション
- AsyncValue で非同期状態を管理
- int 値を SharedPreferences に保存
- 既存の PreferenceService を使用して SharedPreferences にアクセス

### 6. SupportTitleRepository(計算)

**配置**: `client/lib/data/repository/support_title_repository.dart`

**役割**: 累計 VP から現在の称号と次の称号までの進捗を計算

**主要機能**:

- `build()`: VivaPointRepository を watch し、称号情報を計算
- `currentTitle`: 現在の称号を返す
- `nextTitle`: 次の称号を返す
- `pointsToNextTitle`: 次の称号まで必要な VP を返す
- `progressToNextTitle`: 次の称号までの進捗(0.0〜1.0)を返す

**実装例**:

```dart
@freezed
class SupportTitleInfo with _$SupportTitleInfo {
  const factory SupportTitleInfo({
    required SupportTitle currentTitle,
    SupportTitle? nextTitle,
    required int pointsToNextTitle,
    required double progressToNextTitle,
  }) = _SupportTitleInfo;
}

@riverpod
Future<SupportTitleInfo> supportTitleInfo(Ref ref) async {
  final totalVivaPoint = await ref.watch(vivaPointRepositoryProvider.future);

  // 現在の称号を計算
  SupportTitle currentTitle = SupportTitle.none;
  for (final title in SupportTitle.values.reversed) {
    if (totalVivaPoint >= title.requiredVivaPoint) {
      currentTitle = title;
      break;
    }
  }

  // 次の称号を取得
  final nextTitle = currentTitle.nextTitle;

  // 次の称号まで必要なポイントを計算
  final pointsToNextTitle = nextTitle != null
      ? nextTitle.requiredVivaPoint - totalVivaPoint
      : 0;

  // 進捗を計算
  final progressToNextTitle = nextTitle != null
      ? (totalVivaPoint - currentTitle.requiredVivaPoint) /
          (nextTitle.requiredVivaPoint - currentTitle.requiredVivaPoint)
      : 1.0;

  return SupportTitleInfo(
    currentTitle: currentTitle,
    nextTitle: nextTitle,
    pointsToNextTitle: pointsToNextTitle,
    progressToNextTitle: progressToNextTitle,
  );
}
```

**実装方式**:

- Riverpod の @riverpod アノテーション
- VivaPointRepository に依存
- 計算ロジックのみで永続化は行わない
- Freezed を使用して称号情報をまとめたデータクラスを返す

### 7. InAppPurchaseService(サービス層)

**配置**: `client/lib/data/service/in_app_purchase_service.dart`

**役割**: in_app_purchase プラグインのラッパー

**主要機能**:

- `initialize()`: InAppPurchase.instance の初期化
- `isAvailable()`: 課金機能の利用可否を確認
- `queryProductDetails(Set<String> productIds)`: 商品情報を取得
- `buyConsumable(ProductDetails product)`: 消費型商品を購入
- `purchaseStream`: 購入イベントのストリーム

**実装例**:

```dart
@riverpod
class InAppPurchaseService extends _$InAppPurchaseService {
  late final InAppPurchase _inAppPurchase;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  @override
  Future<void> build() async {
    _inAppPurchase = InAppPurchase.instance;

    // 購入ストリームのリスナーを設定
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: _onPurchaseError,
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });
  }

  Future<bool> isAvailable() async {
    return await _inAppPurchase.isAvailable();
  }

  Future<List<ProductDetails>> queryProductDetails(
    Set<String> productIds,
  ) async {
    final response = await _inAppPurchase.queryProductDetails(productIds);

    if (response.error != null) {
      throw ProductQueryException();
    }

    if (response.productDetails.isEmpty) {
      throw ProductNotFoundException();
    }

    return response.productDetails;
  }

  Future<void> buyConsumable(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // 購入完了処理
        _completePurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // エラー処理
        _handlePurchaseError(purchaseDetails);
      }

      // 購入処理を完了としてマーク
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  void _onPurchaseError(Object error) {
    // エラーログを送信
    ref.read(errorReportServiceProvider).report(error);
  }

  Future<void> _completePurchase(PurchaseDetails purchaseDetails) async {
    // VPを加算
    final plan = _getPlanFromProductId(purchaseDetails.productID);
    if (plan != null) {
      await ref
          .read(vivaPointRepositoryProvider.notifier)
          .add(plan.vivaPoint);
    }
  }

  void _handlePurchaseError(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.error?.code == 'user_cancelled') {
      // ユーザーキャンセルは静かに処理
      return;
    }

    // その他のエラーは報告
    ref.read(errorReportServiceProvider).report(purchaseDetails.error);
  }

  SupportPlan? _getPlanFromProductId(String productId) {
    for (final plan in SupportPlan.values) {
      if (plan.productId == productId) {
        return plan;
      }
    }
    return null;
  }
}
```

**実装方式**:

- Riverpod の @riverpod アノテーション
- in_app_purchase パッケージを使用
- StreamSubscription で購入イベントを監視
- ref.onDispose でリソースのクリーンアップ

**エラー処理**:

- ユーザーキャンセル: 静かに処理終了
- ネットワークエラー: ErrorReportService でログ送信
- 商品情報取得失敗: カスタム例外をスロー

**カスタム例外**:

```dart
class ProductQueryException implements Exception {
  const ProductQueryException();
}

class ProductNotFoundException implements Exception {
  const ProductNotFoundException();
}
```

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

"💝 カヴィヴァラを応援" ListTile を「アプリについて」セクションに追加

**実装例**:

```dart
Widget build(BuildContext context) {
  final titleInfo = ref.watch(supportTitleInfoProvider);

  return ListView(
    children: [
      // ...既存のセクション

      // アプリについてセクション
      ListTile(
        leading: const Text('💝'),
        title: const Text('カヴィヴァラを応援'),
        subtitle: titleInfo.when(
          data: (info) {
            if (info.currentTitle == SupportTitle.none) {
              return null;
            }
            final totalVp = ref.watch(vivaPointRepositoryProvider).valueOrNull ?? 0;
            return Text('${totalVp}VP・称号: ${info.currentTitle.displayName}');
          },
          loading: () => null,
          error: (_, __) => null,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(SupportCavivaraScreen.route());
        },
      ),

      // ...他のセクション
    ],
  );
}
```

**表示仕様**:

- **アイコン**: 💝 絵文字
- **タイトル**: "カヴィヴァラを応援"
- **サブタイトル**:
  - 未応援時(0VP): 表示なし
  - 応援済み: "5VP・称号: 応援サポーター"のように表示
- **trailing**: 右向き矢印アイコン
- **タップ動作**: SupportCavivaraScreen に遷移

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

## 設計上の重要な考慮事項

本セクションでは、設計時に特に注意を払った重要な判断とその理由を記載する。

### コンプライアンス設計

**設計判断の背景**:

App Store / Google Play の審査を通過し、アカウント停止などの重大リスクを回避するため、ガイドラインへの準拠を最優先に設計した。

**採用した設計**:

- **表現の選択**: 「寄付」「投げ銭」ではなく「応援」という表現を使用
  - **理由**: 「寄付」は審査で却下される可能性が高い。「応援」は機能追加なしの課金として許容される表現
- **機能追加なしの明示**: UI 上で「応援課金では機能は追加されません」と明記
  - **理由**: ユーザーの誤解を防ぎ、ガイドライン違反(機能制限による課金と誤認)を回避する
- **全機能無料の明示**: 「アプリの基本機能は引き続き無料でご利用いただけます」と明記
  - **理由**: 必須課金と誤認されないようにし、審査時の指摘を防ぐ
- **消費型アイテム**: 非消費型・サブスクリプションではなく消費型として実装
  - **理由**: 継続的な利益ではなく、都度の応援という性質を正確に表現する

### プライバシー設計

**設計判断の背景**:

ユーザーのプライバシーを最大限保護し、GDPR 等の法規制に確実に準拠するため、データ収集を最小限に抑える設計とした。

**採用した設計**:

- **履歴の非記録**: 個別の応援履歴(日時・金額の詳細)は記録しない
  - **理由**: プライバシーリスクを最小化し、データ管理の責任を軽減する。課金情報は機密性が高いため
- **ローカル保存のみ**: 累計 VP と称号のみをローカル(SharedPreferences)に保存
  - **理由**: サーバーに課金情報を保存することで生じるセキュリティリスク、インフラコスト、コンプライアンス要件を回避
- **サーバー送信なし**: 課金情報をサーバーに送信しない
  - **理由**: データ漏洩リスクの完全排除。通信の盗聴やサーバー侵害のリスクをゼロにする

### エラーハンドリング設計

**設計判断の背景**:

ユーザー体験を損なわず、かつ適切なエラー情報を提供し、ユーザーが自己解決できるようにするため。

**採用した設計**:

- **ユーザーキャンセル**: 静かに処理終了(エラーダイアログなし)
  - **理由**: ユーザーの意図的な操作であり、エラーではない。ダイアログを出すとネガティブな印象を与える
- **ネットワークエラー**: "ネットワーク接続を確認してください"
  - **理由**: ユーザーが対処可能な明確なメッセージ。技術的な詳細は避ける
- **商品情報取得失敗**: "商品情報の取得に失敗しました。しばらくしてから再度お試しください"
  - **理由**: 一時的なエラーである可能性を示唆し、再試行を促す。ユーザーに不安を与えない
- **購入失敗**: "購入処理に失敗しました。課金されていない場合は、もう一度お試しください"
  - **理由**: 二重課金への不安を解消する。「課金されていない場合は」という条件を明示

### 後方互換性設計

**設計判断の背景**:

既存ユーザーの体験を一切損なわず、安全に新機能を追加するため。

**採用した設計**:

- **影響の局所化**: SharedPreferences に新しいキー `totalVivaPoint` を追加するのみ
  - **理由**: 既存の保存データに一切影響を与えない。キー名の衝突リスクもなし
- **マイグレーション不要**: 初回起動時に累計 VP は 0 から開始
  - **理由**: 既存ユーザーも新規ユーザーも同じ初期状態で公平。複雑なマイグレーションロジック不要
- **UI の拡張**: 既存の設定画面に新しいメニューを追加
  - **理由**: 既存の UI 構造を壊さず、自然な拡張。既存機能の動作に影響なし

### 拡張性設計

**設計判断の背景**:

将来的な機能拡張を見据え、現時点で柔軟な設計を採用し、後から機能追加しやすくする。

**将来的な拡張案**:

- 応援履歴の詳細記録機能(オプトイン)
- 応援ランキング機能
- 応援ごとの特別メッセージ
- 季節限定の特別プラン
- 称号に応じた特別なカヴィヴァラアイコン

**拡張時の考慮事項**:

- **VP システムは維持**: 既存ユーザーのポイントは保持され続ける
- **称号システムは拡張可能**: enum に新しい称号を追加するだけで対応可能
- **応援プランは追加可能**: 新しい価格帯を追加しても既存プランに影響なし

## 制約事項

- iOS、Android 両プラットフォームで同一の機能と見た目を保証する
- 応援課金は純粋なサポートであり、機能追加は一切行わない
- App Store / Google Play のガイドラインを厳密に遵守する
- 消費型アイテムのみを使用し、非消費型・サブスクリプションは使用しない
- 個別の応援履歴(日時・金額の詳細)は記録しない
- 累計 VP と称号のみをローカルに保存する
- サーバーへの課金情報の送信は行わない

## パフォーマンス考慮事項

### リポジトリの効率的な使用

- VivaPointRepository は AsyncValue で状態を管理し、不要な再読み込みを防ぐ
- SupportTitleRepository は VivaPointRepository を watch し、VP 更新時のみ再計算
- SharedPreferences への書き込みは最小限に抑える(VP 加算時のみ)

### UI の効率的な再ビルド

- ref.watch を使用して必要な部分のみを再ビルド
- 応援画面では商品情報を一度だけ取得し、キャッシュする
- 進捗バーのアニメーションは軽量に実装

### 課金処理の非同期化

- 購入処理は非同期で実行し、UI をブロックしない
- purchaseStream を使用してバックグラウンドで購入完了を検知
- 購入完了後の VP 加算は await せず、非同期で実行

## 関連ドキュメント

- [要件定義書: カヴィヴァラ応援課金機能](../requirement/support-cavivara-donation.md)
- [in_app_purchase plugin documentation](https://pub.dev/packages/in_app_purchase)
- [App Store In-App Purchase Guidelines](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase)
- [Google Play Billing Guidelines](https://support.google.com/googleplay/android-developer/answer/140504)
- [SharedPreferences 使用時の設計方法](../how-to-design-when-using-shared-preferences.md)
