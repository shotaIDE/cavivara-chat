import 'dart:math';

import 'package:flutter/material.dart';

/// 角丸吹き出しに猫毛様式の毛束（ストランド）を生やす [CustomPainter]。
///
/// 各辺と四隅の輪郭に沿って2次ベジェ曲線で構成した毛束を敷き詰め、
/// [windAnimation] が指定されている場合は毛先を風揺れさせる。
class CatFurBubblePainter extends CustomPainter {
  CatFurBubblePainter({required this.seed, this.windAnimation})
    : super(repaint: windAnimation);

  /// 描画される毛先が背景矩形の外側に突き出しうる最大距離（px）。
  /// 親ウィジェットに余白として確保してもらうための公開定数。
  static const maxOuterExtent = 10.0;

  // ===== ジオメトリ定数 =====

  /// 角丸部分を避けるマージン
  static const _cornerMargin = 10.0;

  /// コーナーストランドの生え際の仮想弧の中心点を、キャンバスの各角からどれだけ
  /// 内側に置くか。値を大きくするほど弧の半径が大きくなり、緩やかな角丸になる。
  /// 隣接辺の端点（角から約 `_cornerMargin` の位置にある）までの距離が弧の半径と
  /// なるため、半径 ≈ √((offset - baseOffset)² + (offset - cornerMargin)²)。
  static const _cornerArcCenterOffset = 18.0;

  /// 外側ストランドの生え際から、奥側に敷くシルエット層の生え際までの距離（px）。
  /// シルエット層は外側と同形状のストランドを吹き出しの内側にもう一周分敷き、
  /// 薄いグレーの輪郭として奥行きを与える。
  static const _silhouetteInset = 5.0;

  /// 背景の角丸半径。内側の塗りつぶし矩形と外側の背景矩形で
  /// コーナー中心が同心になるよう、内側半径はここから派生して算出する。
  static const _backgroundCornerRadius = 12.0;

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

  /// ストランドの膨らみ量（ベジェ制御点の弦中点からのオフセット）の最小値・最大値。
  static const _minBulgeAmount = 1.5;
  static const _maxBulgeAmount = 4.0;

  /// 辺・四隅ごとにサブ乱数列を派生させるときに使う `nextInt` の上限。
  /// 全レイヤーで共通の seed 空間から、各辺・四隅へ独立した乱数列を割り当てる。
  static const _subRandomSeedSpace = 100000;

  // ===== 風アニメーション定数 =====

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

  final int seed;

  /// 風のアニメーション。0..1 で1サイクルとして扱う。
  /// null の場合は揺れずに静止状態で描画する。
  final Animation<double>? windAnimation;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawFurLayer(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CatFurBubblePainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.windAnimation != windAnimation;
  }

  /// 背景の角丸矩形を描画する。
  void _drawBackground(Canvas canvas, Size size) {
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        _maxBaseOffset,
        _maxBaseOffset,
        size.width - _maxBaseOffset,
        size.height - _maxBaseOffset,
      ),
      const Radius.circular(_backgroundCornerRadius),
    );
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  /// シルエット層の内側（文字が乗る中央領域）を [color] で塗りつぶす。
  ///
  /// この塗りつぶしと内側ストランドが繋がることで、奥側に敷いた薄いグレーの
  /// 一体的なシルエットとして見えるようになる。
  /// 矩形は背景矩形より `_silhouetteInset - _maxBaseOffset` だけ内側に置き、
  /// 半径もその分だけ縮めることで、外側背景とコーナー中心が同心になる。
  void _drawSilhouetteFill(Canvas canvas, Size size, Color color) {
    const innerRadius =
        _backgroundCornerRadius - (_silhouetteInset - _maxBaseOffset);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        _silhouetteInset,
        _silhouetteInset,
        size.width - _silhouetteInset,
        size.height - _silhouetteInset,
      ),
      const Radius.circular(innerRadius),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  /// 4辺と4隅の全てに毛束を敷き詰める。
  ///
  /// 外側レイヤーに加えて、内側に十分なスペースがある場合は、外側の各辺のストランド
  /// と沿走軸方向の位置を完全に揃えた内側ストランドを `_silhouetteInset` だけ内側に
  /// 重ねる。コーナー領域と辺の左右端 `_silhouetteInset` px 分は内側ストランドの
  /// 描画を省略し、シルエット塗りつぶし矩形にシャドーを任せる。
  void _drawFurLayer(Canvas canvas, Size size) {
    _drawSingleStrandLayer(
      canvas,
      size,
      layerSeed: seed,
      inset: 0,
      strokeColor: Colors.grey.shade600.withAlpha(180),
      fillColor: Colors.white,
    );

    // 内側ストランドが少しでも描かれるのは、辺の中央部に余白を含めた長さが
    // 残っているとき。コーナー（_cornerMargin）に加えて両端の余白
    // （_silhouetteInset）を引いた長さが正である必要がある。
    final innerFits =
        size.width > 2 * (_cornerMargin + _silhouetteInset) &&
        size.height > 2 * (_cornerMargin + _silhouetteInset);
    if (innerFits) {
      // 枠線・塗りつぶしともに薄いグレーで揃え、奥側に控えめなシルエットとして敷く。
      // 文字が乗る中央領域も同色で塗り、内側ストランドと一体のシルエットに見せる。
      final silhouetteColor = Colors.grey.shade200;
      _drawSilhouetteFill(canvas, size, silhouetteColor);
      _drawAlignedInnerStrandLayer(
        canvas,
        size,
        outerSeed: seed,
        inset: _silhouetteInset,
        strokeColor: silhouetteColor,
        fillColor: silhouetteColor,
      );
    }
  }

  /// 外側レイヤー [outerSeed] と同じ乱数列で内側のストランドを生成して描画する。
  ///
  /// 各辺で外側 [_drawSingleStrandLayer] と同じ順序・同じ消費数で乱数を消費する
  /// ため、ストランドの沿走軸方向の位置（top 辺なら x 位置）は外側と完全に一致し、
  /// 内側のストランドは外側のストランドの直下に「影」のように並ぶ。
  ///
  /// 四隅は描画せず、各辺の左右端から [inset] px 以内に入るストランドも
  /// 描画をスキップする（乱数列のアラインメントは保つために消費は継続する）。
  /// コーナー領域・両端の余白部分のシャドーは [_drawSilhouetteFill] が描いた
  /// 塗りつぶし矩形に任せる。
  void _drawAlignedInnerStrandLayer(
    Canvas canvas,
    Size size, {
    required int outerSeed,
    required double inset,
    required Color strokeColor,
    required Color fillColor,
  }) {
    final random = Random(outerSeed);
    final style = _FurLayerStyle(
      color: strokeColor,
      strokeWidth: 1.5,
      minPeakHeight: _minPeakHeight,
      maxPeakHeight: _maxPeakHeight,
    );
    final paints = _StrandPaints.from(fillColor: fillColor, style: style);

    var isFirstEdge = true;
    for (final edge in _Edge.values) {
      final edgeRandom = isFirstEdge
          ? random
          : Random(random.nextInt(_subRandomSeedSpace));
      isFirstEdge = false;
      _drawAlignedInnerEdgeStrands(
        canvas,
        size,
        edge: edge,
        random: edgeRandom,
        style: style,
        paints: paints,
        inset: inset,
      );
    }
    // 四隅は描かない。コーナー用 sub-seed は外側との位相を揃える必要が
    // ないため消費しない。
  }

  /// 辺 [edge] に沿って、外側ストランドと同じ沿走軸位置にあるストランドだけを
  /// 内側の生え際で描画する。
  ///
  /// 反復範囲は外側 [_drawEdgeFurStrands] と同じ `[_cornerMargin, edge - _cornerMargin]`
  /// にして、各ストランドで外側と全く同じ乱数を消費する。実際の描画はそこから
  /// さらに両端 [inset] px の余白を除いた範囲に入るストランドだけで行う。
  void _drawAlignedInnerEdgeStrands(
    Canvas canvas,
    Size size, {
    required _Edge edge,
    required Random random,
    required _FurLayerStyle style,
    required _StrandPaints paints,
    required double inset,
  }) {
    final canvasEdgeLength = switch (edge) {
      _Edge.top || _Edge.bottom => size.width,
      _Edge.left || _Edge.right => size.height,
    };
    // 外側と同じ反復範囲。乱数列を完全に一致させるために必須。
    const iterStart = _cornerMargin;
    final iterEnd = canvasEdgeLength - _cornerMargin;
    if (iterEnd - iterStart <= 0) {
      return;
    }
    // 外側ストランドのコーナー境界から [inset] の余白を残して描画をスキップ。
    final drawStart = iterStart + inset;
    final drawEnd = iterEnd - inset;
    final baseline = _EdgeBaseline(size: size, edge: edge, inset: inset);

    final reversed = edge == _Edge.bottom || edge == _Edge.left;
    final direction = reversed ? -1.0 : 1.0;

    var pos = reversed ? iterEnd : iterStart;

    while (reversed ? pos > iterStart : pos < iterEnd) {
      // 外側 [_drawEdgeFurStrands] と消費順序・回数を完全に一致させる。
      final strandWidth = _randomStrandWidth(random);
      final peakHeight = _randomPeakHeight(random, style);

      final startParam = pos;
      final peakParam = pos + strandWidth * direction;
      final endParam =
          peakParam -
          random.nextDouble() * strandWidth * _endReturnRatio * direction;
      final startBaseOffset = random.nextDouble() * _maxBaseOffset;
      final endBaseOffset = random.nextDouble() * _maxBaseOffset;
      final bulgeAmount = _randomBulgeAmount(random);
      final bulgeSign = _randomBulgeSign(random);

      final strandLow = startParam < peakParam ? startParam : peakParam;
      final strandHigh = startParam > peakParam ? startParam : peakParam;
      final inDrawRange = strandLow >= drawStart && strandHigh <= drawEnd;

      if (inDrawRange) {
        final start = baseline.point(startParam, outward: -startBaseOffset);
        final rawPeak = baseline.point(peakParam, outward: peakHeight);
        final peak = rawPeak + _windOffset(rawPeak);
        final end = baseline.point(endParam, outward: -endBaseOffset);

        _drawStrand(
          canvas,
          baseline: baseline,
          start: start,
          peak: peak,
          end: end,
          innerStart: baseline.point(startParam, outward: -_maxBaseOffset),
          innerEnd: baseline.point(endParam, outward: -_maxBaseOffset),
          signedBulge: bulgeAmount * bulgeSign,
          paints: paints,
        );
      }

      pos = endParam;
    }
  }

  /// 4辺と4隅の全てに毛束を敷き詰める1レイヤー分の描画。
  ///
  /// [inset] が正なら、生え際全体を吹き出しの内側方向にその分だけ平行移動した位置に
  /// 同じ形状のストランドを敷く。[layerSeed] でレイヤー固有の乱数列を分離する。
  /// [strokeColor]/[fillColor] でレイヤーごとに枠線色と塗りつぶし色を切り替えられる。
  void _drawSingleStrandLayer(
    Canvas canvas,
    Size size, {
    required int layerSeed,
    required double inset,
    required Color strokeColor,
    required Color fillColor,
  }) {
    final random = Random(layerSeed);
    final style = _FurLayerStyle(
      color: strokeColor,
      strokeWidth: 1.5,
      minPeakHeight: _minPeakHeight,
      maxPeakHeight: _maxPeakHeight,
    );
    final paints = _StrandPaints.from(fillColor: fillColor, style: style);

    // 4辺：先頭の辺だけは layerSeed の乱数列をそのまま使い、残りの辺は
    // それぞれ独立したサブ乱数列を派生させて敷き詰める。
    final edgeEndpoints = <_Edge, _EdgeEndpoints>{};
    for (final edge in _Edge.values) {
      final edgeRandom = edgeEndpoints.isEmpty
          ? random
          : Random(random.nextInt(_subRandomSeedSpace));
      edgeEndpoints[edge] = _drawEdgeFurStrands(
        canvas,
        size,
        edge: edge,
        random: edgeRandom,
        style: style,
        paints: paints,
        inset: inset,
      );
    }

    // 四隅：隣接辺の端点を時計回りに繋ぐ円弧上に毛束を敷き詰める。
    // 各タプルは (角, 一つ手前の辺, 一つ後の辺)。手前の辺の `lastEnd` と
    // 後の辺の `firstStart` を弧で結ぶことで毛並みを連続させる。
    const cornerEdgePairs = [
      (_Corner.topLeft, _Edge.left, _Edge.top),
      (_Corner.topRight, _Edge.top, _Edge.right),
      (_Corner.bottomRight, _Edge.right, _Edge.bottom),
      (_Corner.bottomLeft, _Edge.bottom, _Edge.left),
    ];
    final cornerRandom = Random(random.nextInt(_subRandomSeedSpace));
    for (final (corner, prevEdge, nextEdge) in cornerEdgePairs) {
      _drawCornerFurStrands(
        canvas,
        size,
        corner: corner,
        edgeStart: edgeEndpoints[prevEdge]!.lastEnd,
        edgeEnd: edgeEndpoints[nextEdge]!.firstStart,
        random: cornerRandom,
        style: style,
        paints: paints,
        inset: inset,
      );
    }
  }

  // ===== ストランド乱数ヘルパー =====
  //
  // 辺と四隅のどちらでも同じ分布のパラメータが必要なので共通化する。
  // 各関数は内部で固定回数 `random.nextDouble()` を消費するため、
  // 呼び出し側はこれらを並べる順序で seed に対する描画結果を制御する。

  /// ストランド幅をランダムに返す。`nextDouble()` を 2 回消費する。
  ///
  /// `1 - r1 * r2` のバイアス（大きい値が出やすい）をかけることで、
  /// 細いストランドより太いストランドの方がやや多くなる。
  static double _randomStrandWidth(Random random) {
    return _minStrandWidth +
        (1 - random.nextDouble() * random.nextDouble()) *
            (_maxStrandWidth - _minStrandWidth);
  }

  /// ピーク高さ（外側への突き出し）をランダムに返す。`nextDouble()` を 1 回消費する。
  static double _randomPeakHeight(Random random, _FurLayerStyle style) {
    return style.minPeakHeight +
        random.nextDouble() * (style.maxPeakHeight - style.minPeakHeight);
  }

  /// 膨らみ量をランダムに返す。`nextDouble()` を 1 回消費する。
  static double _randomBulgeAmount(Random random) {
    return _minBulgeAmount +
        random.nextDouble() * (_maxBulgeAmount - _minBulgeAmount);
  }

  /// 膨らみの符号（外側=+1.0 / 内側=-1.0）をランダムに返す。
  /// `nextDouble()` を 1 回消費する。
  static double _randomBulgeSign(Random random) {
    return random.nextDouble() < _firstHalfOutwardBulgeProbability ? 1.0 : -1.0;
  }

  // ===== 辺のストランド =====

  /// [edge] に沿って毛束を隙間なく敷き詰める。
  ///
  /// 戻り値は最初のストランドの始点と、最後のストランドの終点（いずれもキャンバス
  /// 座標）。呼び出し側はこれを四隅のストランドの開始/終了点として利用する。
  _EdgeEndpoints _drawEdgeFurStrands(
    Canvas canvas,
    Size size, {
    required _Edge edge,
    required Random random,
    required _FurLayerStyle style,
    required _StrandPaints paints,
    double inset = 0,
  }) {
    final canvasEdgeLength = switch (edge) {
      _Edge.top || _Edge.bottom => size.width,
      _Edge.left || _Edge.right => size.height,
    };
    final rangeStart = inset + _cornerMargin;
    final rangeEnd = canvasEdgeLength - inset - _cornerMargin;
    final baseline = _EdgeBaseline(size: size, edge: edge, inset: inset);

    if (rangeEnd - rangeStart <= 0) {
      // 敷き詰める長さがない場合は辺の中央点をフォールバックとして返す
      final fallback = baseline.point((rangeStart + rangeEnd) / 2);
      return _EdgeEndpoints(firstStart: fallback, lastEnd: fallback);
    }

    // 左上→右上→右下→左下の時計回りに毛並みを揃えるため、
    // 下辺と左辺は逆方向に描画する。
    final reversed = edge == _Edge.bottom || edge == _Edge.left;
    final direction = reversed ? -1.0 : 1.0;

    var pos = reversed ? rangeEnd : rangeStart;
    Offset? firstStart;
    late Offset lastEnd;

    while (reversed ? pos > rangeStart : pos < rangeEnd) {
      // 乱数消費順序を変えると seed に対する描画結果が変わるため、
      // 以下の呼び出し順序を固定する。
      final strandWidth = _randomStrandWidth(random);
      final peakHeight = _randomPeakHeight(random, style);

      final startParam = pos;
      final peakParam = pos + strandWidth * direction;
      final endParam =
          peakParam -
          random.nextDouble() * strandWidth * _endReturnRatio * direction;
      final startBaseOffset = random.nextDouble() * _maxBaseOffset;
      final endBaseOffset = random.nextDouble() * _maxBaseOffset;
      final bulgeAmount = _randomBulgeAmount(random);
      final bulgeSign = _randomBulgeSign(random);

      final start = baseline.point(startParam, outward: -startBaseOffset);
      final rawPeak = baseline.point(peakParam, outward: peakHeight);
      final peak = rawPeak + _windOffset(rawPeak);
      final end = baseline.point(endParam, outward: -endBaseOffset);

      _drawStrand(
        canvas,
        baseline: baseline,
        start: start,
        peak: peak,
        end: end,
        innerStart: baseline.point(startParam, outward: -_maxBaseOffset),
        innerEnd: baseline.point(endParam, outward: -_maxBaseOffset),
        signedBulge: bulgeAmount * bulgeSign,
        paints: paints,
      );

      firstStart ??= start;
      lastEnd = end;

      // 次のストランドの開始位置 = 今のストランドの終点の沿走成分
      pos = switch (edge) {
        _Edge.top || _Edge.bottom => end.dx,
        _Edge.left || _Edge.right => end.dy,
      };
    }

    return _EdgeEndpoints(firstStart: firstStart!, lastEnd: lastEnd);
  }

  // ===== 四隅のストランド =====

  /// [corner] の角丸領域に、円弧に沿って毛束を敷き詰める。
  ///
  /// [edgeStart]/[edgeEnd] は前後の辺の最後/最初のストランドの端点で、
  /// この間を時計回りの円弧で繋ぐ。
  void _drawCornerFurStrands(
    Canvas canvas,
    Size size, {
    required _Corner corner,
    required Offset edgeStart,
    required Offset edgeEnd,
    required Random random,
    required _FurLayerStyle style,
    required _StrandPaints paints,
    double inset = 0,
  }) {
    final arcCenter = _arcCenterFor(corner, size, inset);

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

    final baseRadius =
        ((edgeStart - arcCenter).distance + (edgeEnd - arcCenter).distance) / 2;
    if (baseRadius <= 0) {
      // 弧が極端に小さい場合（バブルが極端に小さい場合）はストランドを描画しない
      return;
    }

    final baseline = _ArcBaseline(center: arcCenter, radius: baseRadius);

    var currentAngle = startAngle;
    var currentPoint = edgeStart;

    while (true) {
      final remaining = (startAngle + totalDelta) - currentAngle;

      // 乱数消費順序を変えると seed に対する描画結果が変わるため、
      // 以下の呼び出し順序を固定する（isLast でない場合のみ endParam/endRadial 用に 2 回追加消費）。
      final desiredArcLength = _randomStrandWidth(random);
      final strandAngularWidth = desiredArcLength / baseRadius;

      // 残り角度を上回りそうなら、これを最後のストランドとして edgeEnd で終わらせる
      final isLast = strandAngularWidth >= remaining * 0.7;

      final double peakParam;
      final double endParam;
      final Offset strandEnd;
      if (isLast) {
        endParam = startAngle + totalDelta;
        // ピーク位置は終点寄りに少しずらす
        peakParam = currentAngle + (endParam - currentAngle) * 0.6;
        strandEnd = edgeEnd;
      } else {
        peakParam = currentAngle + strandAngularWidth;
        endParam =
            peakParam -
            random.nextDouble() * strandAngularWidth * _endReturnRatio;
        final endRadialOffset = random.nextDouble() * _maxBaseOffset;
        strandEnd = baseline.point(endParam, outward: -endRadialOffset);
      }

      final peakHeight = _randomPeakHeight(random, style);
      final bulgeAmount = _randomBulgeAmount(random);
      final bulgeSign = _randomBulgeSign(random);

      final rawPeak = baseline.point(peakParam, outward: peakHeight);
      final peak = rawPeak + _windOffset(rawPeak);

      _drawStrand(
        canvas,
        baseline: baseline,
        start: currentPoint,
        peak: peak,
        end: strandEnd,
        innerStart: baseline.point(currentAngle, outward: -_maxBaseOffset),
        innerEnd: baseline.point(endParam, outward: -_maxBaseOffset),
        signedBulge: bulgeAmount * bulgeSign,
        paints: paints,
      );

      if (isLast) {
        break;
      }
      currentAngle = endParam;
      currentPoint = strandEnd;
    }
  }

  /// [corner] の生え際の仮想弧の中心点（バブル内部）。
  Offset _arcCenterFor(_Corner corner, Size size, double inset) {
    final offset = _cornerArcCenterOffset + inset;
    return Offset(
      corner.isLeft ? offset : size.width - offset,
      corner.isTop ? offset : size.height - offset,
    );
  }

  /// 1本の毛束（ストランド）を描画する。
  ///
  /// 描画は以下の手順で行われる:
  ///
  /// 1. [start] → [peak] → [end] を2本の二次ベジェ曲線で繋ぐ弧を構築する。
  ///    制御点は [baseline] が定める弦の中点から外側方向に [signedBulge] だけ
  ///    オフセットした点。
  /// 2. 弧と内側境界（[innerEnd] → [innerStart]）で閉じた領域を背景色で塗り潰し、
  ///    下に重なる毛束の線を隠す。
  /// 3. 弧の輪郭線を描画する。
  void _drawStrand(
    Canvas canvas, {
    required _StrandBaseline baseline,
    required Offset start,
    required Offset peak,
    required Offset end,
    required Offset innerStart,
    required Offset innerEnd,
    required double signedBulge,
    required _StrandPaints paints,
  }) {
    final ctrl1 = baseline.bulgedControlPoint(start, peak, signedBulge);
    final ctrl2 = baseline.bulgedControlPoint(peak, end, signedBulge);

    final arcPath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl1.dx, ctrl1.dy, peak.dx, peak.dy)
      ..quadraticBezierTo(ctrl2.dx, ctrl2.dy, end.dx, end.dy);

    final fillPath = Path.from(arcPath)
      ..lineTo(innerEnd.dx, innerEnd.dy)
      ..lineTo(innerStart.dx, innerStart.dy)
      ..close();

    canvas
      ..drawPath(fillPath, paints.fill)
      ..drawPath(arcPath, paints.stroke);
  }

  // ===== 風アニメーション =====

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
}

/// 毛束レイヤー1枚分の描画スタイル。
class _FurLayerStyle {
  const _FurLayerStyle({
    required this.color,
    required this.strokeWidth,
    required this.minPeakHeight,
    required this.maxPeakHeight,
  });

  final Color color;
  final double strokeWidth;
  final double minPeakHeight;
  final double maxPeakHeight;
}

/// 毛束描画に使う [Paint] のペア。フレーム毎に [Paint] を組み立て直すのを避ける。
class _StrandPaints {
  _StrandPaints._(this.fill, this.stroke);

  factory _StrandPaints.from({
    required Color fillColor,
    required _FurLayerStyle style,
  }) {
    return _StrandPaints._(
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
      Paint()
        ..color = style.color
        ..strokeWidth = style.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  final Paint fill;
  final Paint stroke;
}

/// 毛束を敷くための「生え際」抽象。直線辺（[_EdgeBaseline]）と
/// 円弧（[_ArcBaseline]）の2種類があり、辺と四隅の描画ロジックを共通化する。
abstract class _StrandBaseline {
  /// [parameter] の位置を [outward] だけ外側にずらした canvas 座標を返す。
  /// [outward] が正なら表面から外側、負ならバブル内部側。
  Offset point(double parameter, {double outward = 0});

  /// [from] と [to] を結ぶ弦の中点から、生え際の外側方向に [bulge] だけ
  /// オフセットしたベジェ制御点を返す。[bulge] が負なら内側に凹む。
  Offset bulgedControlPoint(Offset from, Offset to, double bulge);
}

/// 直線辺に沿った生え際。
///
/// [inset] を指定すると、生え際自体をキャンバス端から内側に平行移動する。
/// 内側に重ねる第2レイヤーの描画に使う。`inset` が0の場合はキャンバス端と一致する。
class _EdgeBaseline implements _StrandBaseline {
  _EdgeBaseline({required this.size, required this.edge, this.inset = 0});

  final Size size;
  final _Edge edge;
  final double inset;

  @override
  Offset point(double along, {double outward = 0}) {
    switch (edge) {
      case _Edge.top:
        return Offset(along, inset - outward);
      case _Edge.bottom:
        return Offset(along, size.height - inset + outward);
      case _Edge.left:
        return Offset(inset - outward, along);
      case _Edge.right:
        return Offset(size.width - inset + outward, along);
    }
  }

  @override
  Offset bulgedControlPoint(Offset from, Offset to, double bulge) {
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
}

/// 円弧に沿った生え際。四隅の角丸領域で使う。
class _ArcBaseline implements _StrandBaseline {
  _ArcBaseline({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Offset point(double angle, {double outward = 0}) {
    final r = radius + outward;
    return center + Offset(cos(angle), sin(angle)) * r;
  }

  @override
  Offset bulgedControlPoint(Offset from, Offset to, double bulge) {
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
}

enum _Edge { top, bottom, left, right }

enum _Corner {
  topLeft,
  topRight,
  bottomRight,
  bottomLeft;

  bool get isLeft => this == _Corner.topLeft || this == _Corner.bottomLeft;
  bool get isTop => this == _Corner.topLeft || this == _Corner.topRight;
}

/// 辺に沿って敷き詰めたストランド群の、最初のストランドの始点と
/// 最後のストランドの終点（いずれもキャンバス座標）。
class _EdgeEndpoints {
  const _EdgeEndpoints({required this.firstStart, required this.lastEnd});

  final Offset firstStart;
  final Offset lastEnd;
}
