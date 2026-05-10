# 猫毛様式吹き出しデザイン 技術設計書

## 目的

チャット画面の吹き出しデザインに「猫毛様式」(catFur)を追加する。吹き出しの外縁に沿って、不揃いなカール付きファーストランド（毛束）を描画する装飾的なデザインを実現する。

## 形状の特徴

- 山のピークごとに途切れた不連続な曲線
- ピークは先端がくるんと内側に巻き込むカール形状
- 山の高さ・幅・間隔が不揃い（手書き的な揺らぎ）
- 線の太さがピークでやや太く、谷でやや細い（控えめな強弱）

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

**ストランド描画のアルゴリズム**:

各辺（上・下・左・右）に対して以下を繰り返す：

1. 角丸マージン（14pt）を避けた描画可能範囲を算出
2. ランダムな間隔でストランドを配置（ギャップ 3〜13pt で途切れを表現）
3. 各ストランドは 12 セグメントに分割し、セグメントごとに異なる太さで描画

**ストランド形状パラメータ**:

| パラメータ | 値 | 説明 |
|-----------|-----|------|
| strandWidth | 6〜14pt | 毛束の幅（ランダム） |
| peakHeight | 4〜10pt | 毛束の高さ（ランダム） |
| curlDirection | ±1 | カールの向き（ランダム） |
| curlAmount | 2〜5pt | カールの大きさ（ランダム） |
| baseStrokeWidth | 2pt | 谷部分の線幅 |
| peakStrokeWidth | 2.8pt | ピーク部分の線幅 |

**カール表現**: ピーク付近（t=0.4〜0.6）で `pow(sin(t*pi), 3)` を用いて辺方向にシフトし、同時に高さを内側に引き戻すことで巻き込み効果を実現。

**線幅の変化**: `sin(t*pi)` で baseStrokeWidth（2pt）から peakStrokeWidth（2.8pt）を補間。差を小さくすることで控えめな強弱に抑えている。

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
