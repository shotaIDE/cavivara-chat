import 'dart:math';

import 'package:flutter/material.dart';

class CatFurBubblePainter extends CustomPainter {
  const CatFurBubblePainter({
    required this.backgroundColor,
    required this.seed,
  });

  static const maxOuterExtent = 10.0;

  final Color backgroundColor;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    // 背景の角丸矩形を描画
    final bgRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bgRect, bgPaint);

    final random = Random(seed);

    // 濃いグレーのファーレイヤー
    _drawFurLayer(
      canvas,
      size,
      random: random,
      color: Colors.grey.shade600.withAlpha(180),
      strokeWidth: 1.5,
      minPeakHeight: 3,
      maxPeakHeight: 7,
      offset: 0,
    );
  }

  void _drawFurLayer(
    Canvas canvas,
    Size size, {
    required Random random,
    required Color color,
    required double strokeWidth,
    required double minPeakHeight,
    required double maxPeakHeight,
    required double offset,
  }) {
    // 上辺のファーストランド
    _drawEdgeFurStrands(
      canvas,
      size,
      random: random,
      color: color,
      strokeWidth: strokeWidth,
      minPeakHeight: minPeakHeight,
      maxPeakHeight: maxPeakHeight,
      offset: offset,
      edge: _Edge.top,
    );

    // 下辺
    _drawEdgeFurStrands(
      canvas,
      size,
      random: Random(random.nextInt(100000)),
      color: color,
      strokeWidth: strokeWidth,
      minPeakHeight: minPeakHeight,
      maxPeakHeight: maxPeakHeight,
      offset: offset,
      edge: _Edge.bottom,
    );

    // 左辺
    _drawEdgeFurStrands(
      canvas,
      size,
      random: Random(random.nextInt(100000)),
      color: color,
      strokeWidth: strokeWidth,
      minPeakHeight: minPeakHeight,
      maxPeakHeight: maxPeakHeight,
      offset: offset,
      edge: _Edge.left,
    );

    // 右辺
    _drawEdgeFurStrands(
      canvas,
      size,
      random: Random(random.nextInt(100000)),
      color: color,
      strokeWidth: strokeWidth,
      minPeakHeight: minPeakHeight,
      maxPeakHeight: maxPeakHeight,
      offset: offset,
      edge: _Edge.right,
    );
  }

  void _drawEdgeFurStrands(
    Canvas canvas,
    Size size, {
    required Random random,
    required Color color,
    required double strokeWidth,
    required double minPeakHeight,
    required double maxPeakHeight,
    required double offset,
    required _Edge edge,
  }) {
    final edgeLength = switch (edge) {
      _Edge.top || _Edge.bottom => size.width,
      _Edge.left || _Edge.right => size.height,
    };

    // 角丸部分を避けるマージン
    const cornerMargin = 14.0;
    final drawableLength = edgeLength - cornerMargin * 2;
    if (drawableLength <= 0) {
      return;
    }

    // ストランドを隙間なく敷き詰める
    // 最初のストランドの中心位置を計算（底辺の始点がcornerMarginに来るように）
    var nextStrandWidth = 6.0 + random.nextDouble() * 8.0;
    var pos = cornerMargin + nextStrandWidth / 2;
    while (pos < edgeLength - cornerMargin) {
      final strandWidth = nextStrandWidth;
      final peakHeight =
          minPeakHeight + random.nextDouble() * (maxPeakHeight - minPeakHeight);
      // 巻き込み方向（左右ランダム）
      final curlDirection = random.nextBool() ? 1.0 : -1.0;
      final curlAmount = 2.0 + random.nextDouble() * 3.0;

      final result = _drawSingleFurStrand(
        canvas,
        size,
        edge: edge,
        position: pos + offset,
        strandWidth: strandWidth,
        peakHeight: peakHeight,
        curlDirection: curlDirection,
        curlAmount: curlAmount,
        color: color,
        strokeWidth: strokeWidth,
      );

      // 次のストランドの底辺始点を、現在のストランドの底辺終点に合わせる
      nextStrandWidth = 6.0 + random.nextDouble() * 8.0;
      pos = result.end + nextStrandWidth / 2;
    }
  }

  /// 1本の毛束（ストランド）を描画する。
  ///
  /// 描画は2つのパートで構成される:
  ///
  /// 1. **塗りつぶし**:
  ///    毛束の輪郭を [Path] で構築し、内側を背景色で塗りつぶす。
  ///    [_strandPoint] で `t=0→1` のセグメント分の点を算出して
  ///    sin曲線のアーチ形状を描き、辺上の基点に戻してパスを閉じる。
  ///    これにより下に重なった毛束の線を隠し、手前に見える効果を出す。
  ///
  /// 2. **ストローク描画**:
  ///    二次ベジェ曲線で滑らかな弧を描き、[strokeWidth] の均一な太さで描画する。
  ///
  /// [_strandPoint] では以下の効果で自然な毛並みを表現する:
  /// - **along**: 辺に沿った位置（`-halfWidth` → `halfWidth`）
  /// - **height**: `sin(t * π)` で山形に外側へ突き出す高さ
  /// - **sharpCurl**: ピーク付近で辺方向にカール（[curlDirection] で左右ランダム）
  /// - **curlHeight**: ピーク付近で高さを内側に引き戻し、毛先が巻き込む効果
  ///
  /// 戻り値としてストランドの底辺の始点・終点の辺に沿った座標を返す。
  /// 呼び出し側は [_StrandBaseRange.end] を次のストランドの始点として使うことで、
  /// 隙間なく毛並みを敷き詰めることができる。
  _StrandBaseRange _drawSingleFurStrand(
    Canvas canvas,
    Size size, {
    required _Edge edge,
    required double position,
    required double strandWidth,
    required double peakHeight,
    required double curlDirection,
    required double curlAmount,
    required Color color,
    required double strokeWidth,
  }) {
    final halfWidth = strandWidth / 2;

    // 弧の始点・ピーク・終点を算出
    final start = _strandPoint(
      size,
      edge: edge,
      position: position,
      halfWidth: halfWidth,
      t: 0,
      peakHeight: peakHeight,
      curlDirection: curlDirection,
      curlAmount: curlAmount,
    );
    final peak = _strandPoint(
      size,
      edge: edge,
      position: position,
      halfWidth: halfWidth,
      t: 0.5,
      peakHeight: peakHeight,
      curlDirection: curlDirection,
      curlAmount: curlAmount,
    );
    final end = _strandPoint(
      size,
      edge: edge,
      position: position,
      halfWidth: halfWidth,
      t: 1,
      peakHeight: peakHeight,
      curlDirection: curlDirection,
      curlAmount: curlAmount,
    );

    // 二次ベジェ曲線の制御点を算出（t=0.5でpeakを通るように）
    // B(0.5) = 0.25*start + 0.5*control + 0.25*end = peak
    // control = 2*peak - 0.5*(start + end)
    final control = Offset(
      2 * peak.dx - 0.5 * (start.dx + end.dx),
      2 * peak.dy - 0.5 * (start.dy + end.dy),
    );

    // 弧の描画パス
    final arcPath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    // ストランドの内側を背景色で塗りつぶす（下に重なる毛束の線を隠す）
    final baseStart = _strandPoint(
      size,
      edge: edge,
      position: position,
      halfWidth: halfWidth,
      t: 0,
      peakHeight: 0,
      curlDirection: curlDirection,
      curlAmount: 0,
    );
    final fillPath = Path.from(arcPath)
      ..lineTo(baseStart.dx, baseStart.dy)
      ..close();

    final fillPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // ストランドの輪郭線を描画
    final strandPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(arcPath, strandPaint);

    return _StrandBaseRange(
      start: position - halfWidth,
      end: position + halfWidth,
    );
  }

  /// t: 0.0(始点) → 0.5(ピーク) → 1.0(終点) のパラメータ
  /// ピーク付近で先端がくるんと内側に巻き込む
  Offset _strandPoint(
    Size size, {
    required _Edge edge,
    required double position,
    required double halfWidth,
    required double t,
    required double peakHeight,
    required double curlDirection,
    required double curlAmount,
  }) {
    // along: 辺に沿った方向の位置（-halfWidth → 0 → halfWidth）
    final along = (t - 0.5) * 2 * halfWidth;

    // 高さ: sin曲線で0→peakHeight→0
    final height = sin(t * pi) * peakHeight;

    // 巻き込み: ピーク付近(t≈0.5)で辺方向にカールする
    // t=0.5で最大カール、t=0,1でカール0
    final curlFactor = sin(t * pi);
    // ピーク付近でさらに強いカール（t=0.4〜0.6で急激に巻く）
    final sharpCurl =
        pow(curlFactor, 3).toDouble() * curlAmount * curlDirection;

    // ピーク付近で高さを内側に引き戻す（巻き込み効果）
    final curlHeight = t > 0.4 && t < 0.6
        ? -curlAmount * 0.5 * sin((t - 0.4) / 0.2 * pi)
        : 0.0;

    switch (edge) {
      case _Edge.top:
        return Offset(
          position + along + sharpCurl,
          -height - curlHeight,
        );
      case _Edge.bottom:
        return Offset(
          position + along + sharpCurl,
          size.height + height + curlHeight,
        );
      case _Edge.left:
        return Offset(
          -height - curlHeight,
          position + along + sharpCurl,
        );
      case _Edge.right:
        return Offset(
          size.width + height + curlHeight,
          position + along + sharpCurl,
        );
    }
  }

  @override
  bool shouldRepaint(covariant CatFurBubblePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.seed != seed;
  }
}

enum _Edge { top, bottom, left, right }

/// ストランドの底辺の始点・終点の辺に沿った座標。
class _StrandBaseRange {
  const _StrandBaseRange({required this.start, required this.end});

  final double start;
  final double end;
}
