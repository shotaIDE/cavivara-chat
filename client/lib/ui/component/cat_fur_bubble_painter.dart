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
      baseStrokeWidth: 1.2,
      peakStrokeWidth: 1.8,
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
    required double baseStrokeWidth,
    required double peakStrokeWidth,
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
      baseStrokeWidth: baseStrokeWidth,
      peakStrokeWidth: peakStrokeWidth,
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
      baseStrokeWidth: baseStrokeWidth,
      peakStrokeWidth: peakStrokeWidth,
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
      baseStrokeWidth: baseStrokeWidth,
      peakStrokeWidth: peakStrokeWidth,
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
      baseStrokeWidth: baseStrokeWidth,
      peakStrokeWidth: peakStrokeWidth,
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
    required double baseStrokeWidth,
    required double peakStrokeWidth,
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
    var pos = cornerMargin;
    while (pos < edgeLength - cornerMargin) {
      final strandWidth = 6.0 + random.nextDouble() * 8.0;
      final peakHeight =
          minPeakHeight + random.nextDouble() * (maxPeakHeight - minPeakHeight);
      // 巻き込み方向（左右ランダム）
      final curlDirection = random.nextBool() ? 1.0 : -1.0;
      final curlAmount = 2.0 + random.nextDouble() * 3.0;

      _drawSingleFurStrand(
        canvas,
        size,
        edge: edge,
        position: pos + offset,
        strandWidth: strandWidth,
        peakHeight: peakHeight,
        curlDirection: curlDirection,
        curlAmount: curlAmount,
        color: color,
        baseStrokeWidth: baseStrokeWidth,
        peakStrokeWidth: peakStrokeWidth,
      );

      // 隣のストランドと少し重なるように配置（隙間を作らない）
      final overlap = 1.0 + random.nextDouble() * 2.0;
      pos += strandWidth - overlap;
    }
  }

  void _drawSingleFurStrand(
    Canvas canvas,
    Size size, {
    required _Edge edge,
    required double position,
    required double strandWidth,
    required double peakHeight,
    required double curlDirection,
    required double curlAmount,
    required Color color,
    required double baseStrokeWidth,
    required double peakStrokeWidth,
  }) {
    const segments = 12;
    final halfWidth = strandWidth / 2;

    // ストランドの内側を薄いグレーで塗りつぶす
    final fillPath = Path();
    for (var i = 0; i <= segments; i++) {
      final t = i / segments;
      final p = _strandPoint(
        size,
        edge: edge,
        position: position,
        halfWidth: halfWidth,
        t: t,
        peakHeight: peakHeight,
        curlDirection: curlDirection,
        curlAmount: curlAmount,
      );
      if (i == 0) {
        fillPath.moveTo(p.dx, p.dy);
      } else {
        fillPath.lineTo(p.dx, p.dy);
      }
    }
    // 辺上の基点に戻って閉じる（内側を塗るため）
    final baseEnd = _strandPoint(
      size,
      edge: edge,
      position: position,
      halfWidth: halfWidth,
      t: 1,
      peakHeight: 0,
      curlDirection: curlDirection,
      curlAmount: 0,
    );
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
    fillPath
      ..lineTo(baseEnd.dx, baseEnd.dy)
      ..lineTo(baseStart.dx, baseStart.dy)
      ..close();

    final fillPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // ストランドを短いセグメントに分割して太さを変える
    final strandPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < segments; i++) {
      final t0 = i / segments;
      final t1 = (i + 1) / segments;

      // 0→1→0 の山形パラメータ（ピークは中央）
      final tMid = (t0 + t1) / 2;
      // sin曲線で太さを変える（谷で細く、ピークで太く）
      strandPaint.strokeWidth =
          baseStrokeWidth +
          (peakStrokeWidth - baseStrokeWidth) * sin(tMid * pi);

      final p0 = _strandPoint(
        size,
        edge: edge,
        position: position,
        halfWidth: halfWidth,
        t: t0,
        peakHeight: peakHeight,
        curlDirection: curlDirection,
        curlAmount: curlAmount,
      );
      final p1 = _strandPoint(
        size,
        edge: edge,
        position: position,
        halfWidth: halfWidth,
        t: t1,
        peakHeight: peakHeight,
        curlDirection: curlDirection,
        curlAmount: curlAmount,
      );

      canvas.drawLine(p0, p1, strandPaint);
    }
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
