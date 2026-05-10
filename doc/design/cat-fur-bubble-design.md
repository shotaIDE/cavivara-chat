# 猫毛様式吹き出しデザイン 技術設計書

## 目的

チャット画面の吹き出しデザインに「猫毛様式」(catFur)を追加する。吹き出しの外縁に沿って、不揃いな毛束（ストランド）を描画する装飾的なデザインを実現する。

## 形状の特徴

- 各ストランドは2本の二次ベジェ曲線（始点→頂点、頂点→終点）で構成
- 各曲線の膨らみ方向（外側/内側）はランダムに決定（前半・後半は同じ方向）
- 前半の曲線は70%の確率で外側に膨らむ
- 後半の終点はピーク位置から始点方向に戻った非対称な位置に配置
- 毛束の幅・高さが不揃い（手書き的な揺らぎ）
- 線の太さは均一（1.5pt）

## アーキテクチャ

既存のデザイン切り替え機能を拡張する形で実装する。

| レイヤー | コンポーネント | 変更内容 |
|---------|-------------|---------|
| Data | ChatBubbleDesign enum | `catFur` 値を追加 |
| UI | CatFurBubblePainter【新規】 | CustomPainter で毛束を描画 |
| UI | ChatBubbleDesignExtension | `catFur` ケースを追加 |
| Repository | ChatBubbleDesignRepository | 変更なし（enum.name で自動対応） |

## 主要コンポーネント

### 1. CatFurBubblePainter（CustomPainter）【新規作成】

**配置**: `client/lib/ui/component/cat_fur_bubble_painter.dart`

**コンストラクタ**:

```dart
CatFurBubblePainter({
  required Color backgroundColor,
  required int seed,  // 乱数シード（吹き出しごとに異なる形状を生成）
})
```

**描画処理の構成**:

1. **背景描画**: 角丸矩形（radius 12）を塗りつぶし
2. **ファーレイヤー描画**: 濃いグレー（`grey.shade600`, alpha 180）で各辺にストランドを配置

**ストランド配置のアルゴリズム**:

各辺（上・下・左・右）に対して以下を繰り返す：

1. 角丸マージン（10pt）を避けた描画可能範囲を算出
2. 始点位置（`pos`）を `cornerMargin` から開始
3. ストランドを描画し、戻り値の `end`（後半曲線の終点位置）を次のストランドの始点とする
4. 辺の終端まで繰り返し

**ストランド形状パラメータ（定数）**:

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| `_minStrandWidth` | 5pt | 毛束の幅の最小値 |
| `_maxStrandWidth` | 16pt | 毛束の幅の最大値 |
| `_minPeakHeight` | 3pt | 毛束の高さの最小値 |
| `_maxPeakHeight` | 6pt | 毛束の高さの最大値 |
| `strokeWidth` | 1.5pt | 線の太さ（均一） |
| `_firstHalfOutwardBulgeProbability` | 0.7 | 前半曲線が外側に膨らむ確率 |

**ストランド幅の分布**: `1 - rand1 * rand2`（2つの独立した乱数の積を反転）により、最大値に近い幅が出やすい偏り分布を使用。

**1本のストランドの描画手順** (`_drawSingleFurStrand`):

1. 始点・頂点・終点の3点を辺座標系で算出
   - 始点: `position`（辺上）
   - 頂点: `position + strandWidth`（外側に `peakHeight` 分突き出す）
   - 終点: 頂点位置から始点方向に `strandWidth / 2` の範囲でランダム配置（辺上）
2. 始点→頂点、頂点→終点の2本の二次ベジェ曲線で弧を描く
   - 各曲線の制御点は弦の中点から辺の外側方向にオフセット
   - 膨らむ（正）か凹む（負）かはランダムに決定（前半・後半は同じ方向）
   - 膨らみ量: 1.5〜4.0pt
3. 弧の内側を背景色で塗りつぶし、下に重なる毛束の線を隠す
4. 弧の輪郭線を均一な太さ（1.5pt）で描画
5. `_StrandBaseRange`（始点・終点の辺に沿った座標）を返す

**座標変換ヘルパー**:

- `_edgePoint`: 辺座標系（along, outward）を画面座標に変換
- `_bulgedControlPoint`: 2点を結ぶ弦の中点から辺の外側方向にオフセットした制御点を算出

### 2. ChatBubbleDesignExtension の拡張

**変更内容**:

- `displayName`: `'猫毛様式'` を返す
- `shouldWithPointer`: `false` を返す（ツノなし）
- `buildBubble`: `CustomPaint` + `CatFurBubblePainter` で描画。`child.hashCode` を seed として使用し、吹き出しごとに異なる毛並みパターンを生成

## 既存デザインとの比較

| デザイン | 形状 | 実装方法 |
|---------|------|---------|
| 社内標準様式 | 角丸四角形（radius 8） | BoxDecoration + BorderRadius |
| 次世代様式 | 角丸四角形（radius 20/2） | BoxDecoration + BorderRadius |
| 調整済様式 | 7角形（角を削り取り） | CustomClipper + Path |
| 猫毛様式 | 角丸矩形＋毛束装飾 | CustomPainter |

## 後方互換性

- enum 値の追加のみで既存機能への影響なし
- デフォルト値（`corporateStandard`）は変更なし
- マイグレーション不要

## 関連ドキュメント

- [技術設計書: チャット吹き出しデザイン切り替え](./switch-design.md)
- [技術設計書: 調整済吹き出しデザイン](./harmonized-bubble-design.md)
