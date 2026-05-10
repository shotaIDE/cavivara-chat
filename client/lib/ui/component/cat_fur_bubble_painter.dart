import 'dart:math';

import 'package:flutter/material.dart';

class CatFurBubblePainter extends CustomPainter {
  const CatFurBubblePainter({
    required this.backgroundColor,
    required this.seed,
  });

  static const maxOuterExtent = 10.0;

  /// 前半の曲線が外側に膨らむ確率（1.0 = 100%）
  static const _firstHalfOutwardBulgeProbability = 0.7;

  /// ストランドの幅の最小値
  static const _minStrandWidth = 5.0;

  /// ストランドの幅の最大値
  static const _maxStrandWidth = 16.0;

  /// ストランドの高さ（外側への突き出し）の最小値
  static const _minPeakHeight = 1.0;

  /// ストランドの高さ（外側への突き出し）の最大値
  static const _maxPeakHeight = 3.0;

  /// 生え際（始点・終点）のY方向ランダムずれの最大値
  static const _maxBaseOffset = 2.0;

  /// 終点が始点方向に戻る最大割合（1.0 = ストランド幅全体まで戻りうる）
  static const _endReturnRatio = 0.25;

  final Color backgroundColor;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    // 背景の角丸矩形を描画
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        _maxBaseOffset,
        _maxBaseOffset,
        size.width - _maxBaseOffset,
        size.height - _maxBaseOffset,
      ),
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
      minPeakHeight: _minPeakHeight,
      maxPeakHeight: _maxPeakHeight,
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

    // 四隅のコーナーストランド（隣接する辺を滑らかに接続）
    final cornerRandom = Random(random.nextInt(100000));
    for (final corner in _Corner.values) {
      _drawCornerStrand(
        canvas,
        size,
        corner: corner,
        random: cornerRandom,
        color: color,
        strokeWidth: strokeWidth,
        minPeakHeight: minPeakHeight,
        maxPeakHeight: maxPeakHeight,
      );
    }
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
    const cornerMargin = 10.0;
    final drawableLength = edgeLength - cornerMargin * 2;
    if (drawableLength <= 0) {
      return;
    }

    // 左上→右上→右下→左下の時計回りに毛並みを揃えるため、
    // 下辺と左辺は逆方向に描画する
    final reversed = edge == _Edge.bottom || edge == _Edge.left;

    // ストランドを隙間なく敷き詰める
    var pos = reversed ? edgeLength - cornerMargin : cornerMargin;
    while (reversed ? pos > cornerMargin : pos < edgeLength - cornerMargin) {
      final strandWidth =
          _minStrandWidth +
          (1 - random.nextDouble() * random.nextDouble()) *
              (_maxStrandWidth - _minStrandWidth);
      final peakHeight =
          minPeakHeight + random.nextDouble() * (maxPeakHeight - minPeakHeight);
      final result = _drawSingleFurStrand(
        canvas,
        size,
        edge: edge,
        position: pos + offset,
        strandWidth: strandWidth,
        peakHeight: peakHeight,
        random: random,
        color: color,
        strokeWidth: strokeWidth,
        reversed: reversed,
      );

      // 次のストランドの始点を、現在のストランドの底辺終点に合わせる
      // result.end は position（= pos + offset）基準の座標なので offset を引いて戻す
      pos = result.end - offset;
    }
  }

  /// 1本の毛束（ストランド）を描画する。
  ///
  /// 描画は以下の手順で行われる:
  ///
  /// 1. 始点・頂点・終点の3点を辺上の座標として算出する。
  /// 2. 始点→頂点、頂点→終点の2本の二次ベジェ曲線で弧を描く。
  ///    各曲線の制御点は弦の中点から辺の外側方向にオフセットし、
  ///    膨らむか凹むかはランダムに決定する。
  /// 3. 弧の内側を背景色で塗りつぶし、下に重なる毛束の線を隠す。
  /// 4. 弧の輪郭線を [strokeWidth] の均一な太さで描画する。
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
    required Random random,
    required Color color,
    required double strokeWidth,
    bool reversed = false,
  }) {
    // 始点・頂点・終点を辺座標系で算出
    // reversed の場合は along 方向を反転させる
    final direction = reversed ? -1.0 : 1.0;
    final startAlong = position;
    final peakAlong = position + strandWidth * direction;
    // 終点はピーク位置から始点方向に戻る範囲でランダム配置
    final endAlong =
        peakAlong -
        random.nextDouble() * strandWidth * _endReturnRatio * direction;

    // 生え際のY座標をランダムにずらす
    final startBaseOffset = random.nextDouble() * _maxBaseOffset;
    final endBaseOffset = random.nextDouble() * _maxBaseOffset;

    final start = _edgePoint(
      size,
      edge: edge,
      along: startAlong,
      outward: -startBaseOffset,
    );
    final peak = _edgePoint(
      size,
      edge: edge,
      along: peakAlong,
      outward: peakHeight,
    );
    final end = _edgePoint(
      size,
      edge: edge,
      along: endAlong,
      outward: -endBaseOffset,
    );

    // 各曲線の膨らみ方向をランダムに決定（後半は前半と同じ方向）
    final bulgeAmount = 1.5 + random.nextDouble() * 2.5;
    final bulgeSign = random.nextDouble() < _firstHalfOutwardBulgeProbability
        ? 1.0
        : -1.0;

    // 始点→頂点の制御点（弦の中点から辺の外側方向にオフセット）
    final ctrl1 = _bulgedControlPoint(
      edge: edge,
      from: start,
      to: peak,
      bulge: bulgeAmount * bulgeSign,
    );

    // 頂点→終点の制御点
    final ctrl2 = _bulgedControlPoint(
      edge: edge,
      from: peak,
      to: end,
      bulge: bulgeAmount * bulgeSign,
    );

    // 2本のベジェ曲線で弧を構成
    final arcPath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl1.dx, ctrl1.dy, peak.dx, peak.dy)
      ..quadraticBezierTo(ctrl2.dx, ctrl2.dy, end.dx, end.dy);

    // 内側を背景色で塗りつぶす（下に重なる毛束の線を隠す）
    // 生え際の内側まで十分に塗りつぶし、背景矩形の端を覆う
    final innerEnd = _edgePoint(
      size,
      edge: edge,
      along: endAlong,
      outward: -_maxBaseOffset,
    );
    final innerStart = _edgePoint(
      size,
      edge: edge,
      along: startAlong,
      outward: -_maxBaseOffset,
    );
    final fillPath = Path.from(arcPath)
      ..lineTo(innerEnd.dx, innerEnd.dy)
      ..lineTo(innerStart.dx, innerStart.dy)
      ..close();

    final fillPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 輪郭線を描画
    final strandPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(arcPath, strandPaint);

    return _StrandBaseRange(
      start: startAlong,
      end: endAlong,
    );
  }

  /// コーナー部分に毛並みのブリッジストランドを描画し、
  /// 隣接する辺の毛並みの根本を滑らかに接続する。
  ///
  /// 時計回り（左上→右上→右下→左下）の流れに沿って、
  /// 一方の辺の端から隣の辺の端へ弧を描く。
  void _drawCornerStrand(
    Canvas canvas,
    Size size, {
    required _Corner corner,
    required Random random,
    required Color color,
    required double strokeWidth,
    required double minPeakHeight,
    required double maxPeakHeight,
  }) {
    const cornerMargin = 10.0;
    final peakHeight =
        minPeakHeight + random.nextDouble() * (maxPeakHeight - minPeakHeight);
    final diagonalPeak = peakHeight * 0.7;

    final startBaseOffset = random.nextDouble() * _maxBaseOffset;
    final endBaseOffset = random.nextDouble() * _maxBaseOffset;

    // 時計回りの流れに沿った始点・終点・制御点・内側塗りつぶし点
    final Offset start;
    final Offset end;
    final Offset control;
    final Offset innerStart;
    final Offset innerEnd;

    switch (corner) {
      // 左辺(↑) → 上辺(→)
      case _Corner.topLeft:
        start = Offset(startBaseOffset, cornerMargin);
        end = Offset(cornerMargin, endBaseOffset);
        control = Offset(-diagonalPeak, -diagonalPeak);
        innerStart = const Offset(_maxBaseOffset, cornerMargin);
        innerEnd = const Offset(cornerMargin, _maxBaseOffset);
      // 上辺(→) → 右辺(↓)
      case _Corner.topRight:
        start = Offset(size.width - cornerMargin, startBaseOffset);
        end = Offset(size.width - endBaseOffset, cornerMargin);
        control = Offset(
          size.width + diagonalPeak,
          -diagonalPeak,
        );
        innerStart = Offset(
          size.width - cornerMargin,
          _maxBaseOffset,
        );
        innerEnd = Offset(
          size.width - _maxBaseOffset,
          cornerMargin,
        );
      // 右辺(↓) → 下辺(←)
      case _Corner.bottomRight:
        start = Offset(
          size.width - startBaseOffset,
          size.height - cornerMargin,
        );
        end = Offset(
          size.width - cornerMargin,
          size.height - endBaseOffset,
        );
        control = Offset(
          size.width + diagonalPeak,
          size.height + diagonalPeak,
        );
        innerStart = Offset(
          size.width - _maxBaseOffset,
          size.height - cornerMargin,
        );
        innerEnd = Offset(
          size.width - cornerMargin,
          size.height - _maxBaseOffset,
        );
      // 下辺(←) → 左辺(↑)
      case _Corner.bottomLeft:
        start = Offset(cornerMargin, size.height - startBaseOffset);
        end = Offset(endBaseOffset, size.height - cornerMargin);
        control = Offset(
          -diagonalPeak,
          size.height + diagonalPeak,
        );
        innerStart = Offset(
          cornerMargin,
          size.height - _maxBaseOffset,
        );
        innerEnd = Offset(
          _maxBaseOffset,
          size.height - cornerMargin,
        );
    }

    final arcPath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    // 内側を背景色で塗りつぶす
    final fillPath = Path.from(arcPath)
      ..lineTo(innerEnd.dx, innerEnd.dy)
      ..lineTo(innerStart.dx, innerStart.dy)
      ..close();

    final fillPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 輪郭線を描画
    final strandPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(arcPath, strandPaint);
  }

  /// 辺上の座標を画面座標に変換する。
  ///
  /// [along] は辺に沿った位置、[outward] は辺から外側への距離。
  Offset _edgePoint(
    Size size, {
    required _Edge edge,
    required double along,
    double outward = 0,
  }) {
    switch (edge) {
      case _Edge.top:
        return Offset(along, -outward);
      case _Edge.bottom:
        return Offset(along, size.height + outward);
      case _Edge.left:
        return Offset(-outward, along);
      case _Edge.right:
        return Offset(size.width + outward, along);
    }
  }

  /// 2点を結ぶ弦の中点から、辺の外側方向に [bulge] だけオフセットした制御点を返す。
  ///
  /// [bulge] が正なら外側に膨らみ、負なら内側に凹む。
  Offset _bulgedControlPoint({
    required _Edge edge,
    required Offset from,
    required Offset to,
    required double bulge,
  }) {
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    switch (edge) {
      case _Edge.top:
        return Offset(mid.dx, mid.dy - bulge);
      case _Edge.bottom:
        return Offset(mid.dx, mid.dy + bulge);
      case _Edge.left:
        return Offset(mid.dx - bulge, mid.dy);
      case _Edge.right:
        return Offset(mid.dx + bulge, mid.dy);
    }
  }

  @override
  bool shouldRepaint(covariant CatFurBubblePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.seed != seed;
  }
}

enum _Edge { top, bottom, left, right }

enum _Corner { topLeft, topRight, bottomRight, bottomLeft }

/// ストランドの底辺の始点・終点の辺に沿った座標。
class _StrandBaseRange {
  const _StrandBaseRange({required this.start, required this.end});

  final double start;
  final double end;
}
