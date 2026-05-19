import 'dart:math';

import 'package:flutter/material.dart';

class CatFurBubblePainter extends CustomPainter {
  CatFurBubblePainter({
    required this.backgroundColor,
    required this.seed,
    this.windAnimation,
  }) : super(repaint: windAnimation);

  static const maxOuterExtent = 10.0;

  /// 角丸部分を避けるマージン
  static const _cornerMargin = 10.0;

  /// コーナーストランドの生え際の仮想弧の中心点を、キャンバスの各角からどれだけ
  /// 内側に置くか。値を大きくするほど弧の半径が大きくなり、緩やかな角丸になる。
  /// 隣接辺の端点（角から約 `_cornerMargin` の位置にある）までの距離が弧の半径と
  /// なるため、半径 ≈ √((offset - baseOffset)² + (offset - cornerMargin)²)。
  static const _cornerArcCenterOffset = 18.0;

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

  /// 生え際（始点・終点）における辺の内側方向ずれの最大値
  /// （top/bottom辺ではY方向、left/right辺ではX方向に影響する）
  static const _maxBaseOffset = 2.0;

  /// 終点が始点方向に戻る最大割合（1.0 = ストランド幅全体まで戻りうる）
  static const _endReturnRatio = 0.25;

  /// 風によって全ての毛先がスクリーン水平方向に揃って揺れる最大変位（px）
  static const _maxWindHorizontalAmplitude = 1.2;

  /// 風によって全ての毛先がスクリーン垂直方向に揃って揺れる最大変位（px）。
  /// 水平成分との比率で風が吹いていく向きが決まる。
  static const _maxWindVerticalAmplitude = 0.5;

  /// ストランドごとに揺れ幅を ±この割合の範囲で変化させる。
  /// 方向は揃ったまま、毛束ごとに振れ幅をズラして自然な揺らぎを出す。
  static const _windAmplitudeVariation = 0.7;

  /// ストランドごとに揺れのタイミングを ±このラジアン分だけ位相シフトさせる。
  /// 全体としては揃って揺れて見える程度の小さな値（1サイクル = 2π）にする。
  static const _windPhaseVariation = 0.45;

  final Color backgroundColor;
  final int seed;

  /// 風のアニメーション。0..1 で1サイクルとして扱う。
  /// null の場合は揺れずに静止状態で描画する。
  final Animation<double>? windAnimation;

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
      ..color = backgroundColor
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
  }) {
    // 上辺のファーストランド
    final topEndpoints = _drawEdgeFurStrands(
      canvas,
      size,
      random: random,
      color: color,
      strokeWidth: strokeWidth,
      minPeakHeight: minPeakHeight,
      maxPeakHeight: maxPeakHeight,
      edge: _Edge.top,
    );

    // 下辺
    final bottomEndpoints = _drawEdgeFurStrands(
      canvas,
      size,
      random: Random(random.nextInt(100000)),
      color: color,
      strokeWidth: strokeWidth,
      minPeakHeight: minPeakHeight,
      maxPeakHeight: maxPeakHeight,
      edge: _Edge.bottom,
    );

    // 左辺
    final leftEndpoints = _drawEdgeFurStrands(
      canvas,
      size,
      random: Random(random.nextInt(100000)),
      color: color,
      strokeWidth: strokeWidth,
      minPeakHeight: minPeakHeight,
      maxPeakHeight: maxPeakHeight,
      edge: _Edge.left,
    );

    // 右辺
    final rightEndpoints = _drawEdgeFurStrands(
      canvas,
      size,
      random: Random(random.nextInt(100000)),
      color: color,
      strokeWidth: strokeWidth,
      minPeakHeight: minPeakHeight,
      maxPeakHeight: maxPeakHeight,
      edge: _Edge.right,
    );

    // 四隅のコーナーストランド（隣接する辺の端点を時計回りに繋ぐ）
    final cornerRandom = Random(random.nextInt(100000));
    final cornerConnections = <_Corner, ({Offset start, Offset end})>{
      _Corner.topLeft: (
        start: leftEndpoints.lastEnd,
        end: topEndpoints.firstStart,
      ),
      _Corner.topRight: (
        start: topEndpoints.lastEnd,
        end: rightEndpoints.firstStart,
      ),
      _Corner.bottomRight: (
        start: rightEndpoints.lastEnd,
        end: bottomEndpoints.firstStart,
      ),
      _Corner.bottomLeft: (
        start: bottomEndpoints.lastEnd,
        end: leftEndpoints.firstStart,
      ),
    };
    for (final entry in cornerConnections.entries) {
      _drawCornerFurStrands(
        canvas,
        size,
        corner: entry.key,
        edgeStart: entry.value.start,
        edgeEnd: entry.value.end,
        random: cornerRandom,
        color: color,
        strokeWidth: strokeWidth,
        minPeakHeight: minPeakHeight,
        maxPeakHeight: maxPeakHeight,
      );
    }
  }

  _EdgeEndpoints _drawEdgeFurStrands(
    Canvas canvas,
    Size size, {
    required Random random,
    required Color color,
    required double strokeWidth,
    required double minPeakHeight,
    required double maxPeakHeight,
    required _Edge edge,
  }) {
    final edgeLength = switch (edge) {
      _Edge.top || _Edge.bottom => size.width,
      _Edge.left || _Edge.right => size.height,
    };

    final drawableLength = edgeLength - _cornerMargin * 2;
    if (drawableLength <= 0) {
      // ストランドを敷ける長さがない場合は、辺の中央の点をフォールバックとして返す
      final fallback = _edgePoint(size, edge: edge, along: edgeLength / 2);
      return _EdgeEndpoints(firstStart: fallback, lastEnd: fallback);
    }

    // 左上→右上→右下→左下の時計回りに毛並みを揃えるため、
    // 下辺と左辺は逆方向に描画する
    final reversed = edge == _Edge.bottom || edge == _Edge.left;

    // ストランドを隙間なく敷き詰める
    var pos = reversed ? edgeLength - _cornerMargin : _cornerMargin;
    Offset? firstStart;
    late Offset lastEnd;
    while (reversed ? pos > _cornerMargin : pos < edgeLength - _cornerMargin) {
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
        position: pos,
        strandWidth: strandWidth,
        peakHeight: peakHeight,
        random: random,
        color: color,
        strokeWidth: strokeWidth,
        reversed: reversed,
      );

      firstStart ??= result.start;
      lastEnd = result.end;

      // 次のストランドの始点を、現在のストランドの底辺終点に合わせる
      pos = switch (edge) {
        _Edge.top || _Edge.bottom => result.end.dx,
        _Edge.left || _Edge.right => result.end.dy,
      };
    }

    return _EdgeEndpoints(firstStart: firstStart!, lastEnd: lastEnd);
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
  /// 戻り値として始点・終点のキャンバス座標を返す。
  /// 呼び出し側は終点の辺方向成分を次のストランドの始点として使うことで、
  /// 隙間なく毛並みを敷き詰めることができる。
  ({Offset start, Offset end}) _drawSingleFurStrand(
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
    final rawPeak = _edgePoint(
      size,
      edge: edge,
      along: peakAlong,
      outward: peakHeight,
    );
    // 風による毛先の揺れを加える。全ストランド共通のオフセットを使うため、
    // 全ての毛先が同じ方向に同じタイミングで揺れる。
    // 根本 (start/end) は動かさず、頂点のみを揺らすことで「毛が風に靡く」表現になる。
    final peak = rawPeak + _windOffset(rawPeak);
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
      ..color = backgroundColor
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

    return (start: start, end: end);
  }

  /// 四隅の角丸領域に、弧に沿って毛束（ストランド）を敷き詰める。
  ///
  /// [edgeStart] は前の辺の最後のストランドの終点、[edgeEnd] は次の辺の最初の
  /// ストランドの始点（いずれもキャンバス座標）。これらを通る円弧をストランドの
  /// 生え際の仮想線として扱い、辺と同じ要領で複数のストランドを敷き詰めることで、
  /// 四隅の生え際を角丸にする。
  ///
  /// 各ストランドのピークは、コーナーの内側中心点から放射状に外側へ突き出す。
  void _drawCornerFurStrands(
    Canvas canvas,
    Size size, {
    required _Corner corner,
    required Offset edgeStart,
    required Offset edgeEnd,
    required Random random,
    required Color color,
    required double strokeWidth,
    required double minPeakHeight,
    required double maxPeakHeight,
  }) {
    // 生え際の仮想弧の中心点（バブル内部）
    final Offset arcCenter;
    switch (corner) {
      case _Corner.topLeft:
        arcCenter = const Offset(
          _cornerArcCenterOffset,
          _cornerArcCenterOffset,
        );
      case _Corner.topRight:
        arcCenter = Offset(
          size.width - _cornerArcCenterOffset,
          _cornerArcCenterOffset,
        );
      case _Corner.bottomRight:
        arcCenter = Offset(
          size.width - _cornerArcCenterOffset,
          size.height - _cornerArcCenterOffset,
        );
      case _Corner.bottomLeft:
        arcCenter = Offset(
          _cornerArcCenterOffset,
          size.height - _cornerArcCenterOffset,
        );
    }

    // 始点・終点の中心からの角度
    final startAngle = atan2(
      edgeStart.dy - arcCenter.dy,
      edgeStart.dx - arcCenter.dx,
    );
    final endAngleRaw = atan2(
      edgeEnd.dy - arcCenter.dy,
      edgeEnd.dx - arcCenter.dx,
    );
    // 全コーナーで時計回り（数学的にはCCW、つまり角度を増加させる方向）に90度進む
    var totalDelta = endAngleRaw - startAngle;
    if (totalDelta <= 0) {
      totalDelta += 2 * pi;
    }

    final startRadius = (edgeStart - arcCenter).distance;
    final endRadius = (edgeEnd - arcCenter).distance;
    final baseRadius = (startRadius + endRadius) / 2;

    // 弧が極端に小さい場合（バブルが極端に小さい場合）はストランドを描画しない
    if (baseRadius <= 0) {
      return;
    }

    // ストランドを敷き詰める
    var currentAngle = startAngle;
    var currentPoint = edgeStart;

    while (true) {
      final remaining = (startAngle + totalDelta) - currentAngle;

      // 弧長基準のストランド幅 → 角度幅に変換
      final desiredArcLength =
          _minStrandWidth +
          (1 - random.nextDouble() * random.nextDouble()) *
              (_maxStrandWidth - _minStrandWidth);
      final strandAngularWidth = desiredArcLength / baseRadius;

      // 残り角度を上回りそうなら、これを最後のストランドとして edgeEnd で終わらせる
      final isLast = strandAngularWidth >= remaining * 0.7;

      final Offset strandEnd;
      final double strandEndAngle;
      final double strandPeakAngle;
      if (isLast) {
        strandEnd = edgeEnd;
        strandEndAngle = startAngle + totalDelta;
        // ピーク位置は終点寄りに少しずらす
        strandPeakAngle = currentAngle + (strandEndAngle - currentAngle) * 0.6;
      } else {
        final peakAngle = currentAngle + strandAngularWidth;
        strandEndAngle =
            peakAngle -
            random.nextDouble() * strandAngularWidth * _endReturnRatio;
        strandPeakAngle = peakAngle;
        // 終点は弧上にランダムな小さい内側オフセットを付けて配置
        final endRadialOffset = random.nextDouble() * _maxBaseOffset;
        final endR = baseRadius - endRadialOffset;
        strandEnd =
            arcCenter + Offset(cos(strandEndAngle), sin(strandEndAngle)) * endR;
      }

      // ピーク（生え際から放射状に外側へ突き出す）
      final peakHeightVal =
          minPeakHeight + random.nextDouble() * (maxPeakHeight - minPeakHeight);
      final peakR = baseRadius + peakHeightVal;
      final rawPeak =
          arcCenter +
          Offset(cos(strandPeakAngle), sin(strandPeakAngle)) * peakR;
      // 風による毛先の揺れを加える。辺のストランドと同じ全ストランド共通の
      // オフセットを使い、コーナーも他の毛と同じ方向に同じタイミングで揺れる。
      final peak = rawPeak + _windOffset(rawPeak);

      // ベジェ制御点（弦の中点から放射状に外側へオフセット）
      final bulgeAmount = 1.5 + random.nextDouble() * 2.5;
      final bulgeSign = random.nextDouble() < _firstHalfOutwardBulgeProbability
          ? 1.0
          : -1.0;
      final ctrl1 = _radiallyBulgedControlPoint(
        center: arcCenter,
        from: currentPoint,
        to: peak,
        bulge: bulgeAmount * bulgeSign,
      );
      final ctrl2 = _radiallyBulgedControlPoint(
        center: arcCenter,
        from: peak,
        to: strandEnd,
        bulge: bulgeAmount * bulgeSign,
      );

      final arcPath = Path()
        ..moveTo(currentPoint.dx, currentPoint.dy)
        ..quadraticBezierTo(ctrl1.dx, ctrl1.dy, peak.dx, peak.dy)
        ..quadraticBezierTo(ctrl2.dx, ctrl2.dy, strandEnd.dx, strandEnd.dy);

      // 弧の内側を背景色で塗りつぶす（下に重なる毛束の線を隠す）
      final innerR = baseRadius - _maxBaseOffset;
      final innerStart =
          arcCenter + Offset(cos(currentAngle), sin(currentAngle)) * innerR;
      final innerEnd =
          arcCenter + Offset(cos(strandEndAngle), sin(strandEndAngle)) * innerR;
      final fillPath = Path.from(arcPath)
        ..lineTo(innerEnd.dx, innerEnd.dy)
        ..lineTo(innerStart.dx, innerStart.dy)
        ..close();

      final fillPaint = Paint()
        ..color = backgroundColor
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

      if (isLast) {
        break;
      }
      currentPoint = strandEnd;
      currentAngle = strandEndAngle;
    }
  }

  /// 中心点を基準に、2点を結ぶ弦の中点から放射状方向（中心→中点方向）へ
  /// [bulge] だけオフセットした制御点を返す。
  ///
  /// [bulge] が正なら中心から離れる方向（外側）、負なら近づく方向（内側）に
  /// 膨らむ。
  Offset _radiallyBulgedControlPoint({
    required Offset center,
    required Offset from,
    required Offset to,
    required double bulge,
  }) {
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final dx = mid.dx - center.dx;
    final dy = mid.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) {
      return mid;
    }
    return Offset(
      mid.dx + dx / dist * bulge,
      mid.dy + dy / dist * bulge,
    );
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

  /// 指定された毛先位置における、風による毛先のオフセット（スクリーン座標系）。
  ///
  /// 方向は全ストランドで揃っており、水平・垂直の両成分が同じ sin 波で駆動される
  /// ため、毛先は固定された対角方向の直線上を行き来する。
  /// 振れ幅と位相だけ [peak] 位置から決定論的に算出した倍率/オフセットで少しだけ
  /// 変化させており、機械的になりすぎず自然な揺らぎが出る。
  /// [windAnimation] が null の場合は [Offset.zero] を返し、静止状態と同じ描画になる。
  Offset _windOffset(Offset peak) {
    final animation = windAnimation;
    if (animation == null) {
      return Offset.zero;
    }
    final phase = 2 * pi * animation.value + _windPhaseOffset(peak);
    final magnitude = sin(phase) * _windAmplitudeFactor(peak);
    return Offset(
      _maxWindHorizontalAmplitude * magnitude,
      _maxWindVerticalAmplitude * magnitude,
    );
  }

  /// 毛先位置から `[1 - _windAmplitudeVariation, 1 + _windAmplitudeVariation]` の
  /// 範囲の倍率を決定論的に返す。
  ///
  /// 位置に対して周期の異なる sin 波を 2 本合成しただけのゆるい疑似ノイズで、
  /// 隣接ストランドでは値がなだらかに変わる。これにより、揺れの方向とタイミングは
  /// 揃ったまま、毛束ごとに振れ幅が少しずつズレて自然に見える。
  double _windAmplitudeFactor(Offset peak) {
    final noise =
        (sin(peak.dx * 0.31 + peak.dy * 0.17) +
            sin(peak.dx * 0.13 + peak.dy * 0.43 + 1.7)) /
        2;
    return 1.0 + _windAmplitudeVariation * noise;
  }

  /// 毛先位置から `±_windPhaseVariation` 範囲の位相シフト（ラジアン）を返す。
  ///
  /// 振れ幅と同じく位置ベースの疑似ノイズだが、別の係数を使うことで振れ幅と
  /// タイミングのズレが連動しないようにしている。
  double _windPhaseOffset(Offset peak) {
    final noise =
        (sin(peak.dx * 0.21 + peak.dy * 0.29 + 0.5) +
            sin(peak.dx * 0.47 + peak.dy * 0.11 + 2.3)) /
        2;
    return _windPhaseVariation * noise;
  }

  @override
  bool shouldRepaint(covariant CatFurBubblePainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.seed != seed ||
        oldDelegate.windAnimation != windAnimation;
  }
}

enum _Edge { top, bottom, left, right }

enum _Corner { topLeft, topRight, bottomRight, bottomLeft }

/// 辺に沿って敷き詰めたストランド群の、最初のストランドの始点と
/// 最後のストランドの終点（いずれもキャンバス座標）。
class _EdgeEndpoints {
  const _EdgeEndpoints({required this.firstStart, required this.lastEnd});

  final Offset firstStart;
  final Offset lastEnd;
}
