import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// アニメーション可能なカヴィヴァラ(Cavivara)の全身像を描画する自己完結ウィジェット。
/// [strokeColor] が全ての線と塗りつぶした瞳の色を指定する。
///
/// 表示後、一定間隔で右目のウィンクアニメーションを再生する。
class AnimatedCavivara extends StatefulWidget {
  const AnimatedCavivara({
    super.key,
    this.strokeColor = const Color(0xFF3D678D),
  });

  final Color strokeColor;

  @override
  State<AnimatedCavivara> createState() => _AnimatedCavivaraState();
}

class _AnimatedCavivaraState extends State<AnimatedCavivara>
    with SingleTickerProviderStateMixin {
  /// 表示後、最初にウィンクするまでの待機時間。
  static const _initialDelay = Duration(milliseconds: 500);

  /// ウィンクを繰り返す間隔。
  static const _winkInterval = Duration(seconds: 3);

  /// ウィンク 1 回（閉眼 → 開眼）にかける時間。
  static const _winkDuration = Duration(milliseconds: 260);

  late final AnimationController _controller;
  late final Animation<double> _wink;
  Timer? _winkTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _winkDuration,
    );

    // 0 -> 1 -> 0 と進めて、閉眼してから開眼するまばたきを表現する。
    _wink = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
    ]).animate(_controller);

    _winkTimer = Timer(_initialDelay, _playWink);
  }

  void _playWink() {
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) {
        return;
      }
      _winkTimer = Timer(_winkInterval, _playWink);
    });
  }

  @override
  void dispose() {
    _winkTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _kSrcWidth / _kSrcHeight,
      child: AnimatedBuilder(
        animation: _wink,
        builder: (_, _) => CustomPaint(
          painter: _CavivaraPainter(
            strokeColor: widget.strokeColor,
            winkProgress: _wink.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

const double _kSrcWidth = 2308;
const double _kSrcHeight = 1890;

const List<List<double>> _kStrokes = [
  [
    169.0,
    1673.0,
    152.0,
    1788.0,
    161.0,
    1836.0,
    182.0,
    1851.0,
    219.0,
    1834.0,
    292.0,
    1750.0,
    316.0,
    1741.0,
    338.0,
    1747.0,
    354.0,
    1781.0,
    501.0,
    1837.0,
    612.0,
    1865.0,
    723.0,
    1871.0,
    853.0,
    1848.0,
    1014.0,
    1759.0,
    1095.0,
    1737.0,
    1136.0,
    1750.0,
    1176.0,
    1838.0,
    1210.0,
    1843.0,
    1263.0,
    1761.0,
    1296.0,
    1739.0,
  ],
  [1819.0, 377.0, 1921.0, 341.0, 2001.0, 282.0],
  [980.0, 685.0, 1012.0, 633.0],
  [757.0, 1708.0, 793.0, 1684.0],
  [
    2002.0,
    282.0,
    2039.0,
    305.0,
    2112.0,
    296.0,
    2181.0,
    231.0,
    2172.0,
    204.0,
    2141.0,
    206.0,
  ],
  [
    978.0,
    496.0,
    1234.0,
    345.0,
    1442.0,
    297.0,
    1562.0,
    287.0,
    1651.0,
    297.0,
    1744.0,
    329.0,
    1818.0,
    377.0,
  ],
  [48.0, 1563.0, 23.0, 1548.0, 18.0, 1464.0],
  [1012.0, 633.0, 994.0, 603.0, 951.0, 599.0, 915.0, 618.0, 902.0, 649.0],
  [1012.0, 633.0, 1056.0, 631.0, 1084.0, 646.0],
  [2135.0, 111.0, 2144.0, 80.0, 2176.0, 51.0, 2263.0, 19.0],
  [1504.0, 1337.0, 1490.0, 1311.0, 1515.0, 1250.0, 1476.0, 1183.0],
  [1239.0, 936.0, 1250.0, 908.0, 1305.0, 884.0, 1338.0, 899.0],
  [93.0, 1200.0, 88.0, 1117.0, 131.0, 1083.0, 167.0, 1083.0],
  [1166.0, 744.0, 1147.0, 708.0, 1113.0, 697.0, 1067.0, 712.0, 1047.0, 748.0],
  [1166.0, 744.0, 1225.0, 757.0],
  [1166.0, 744.0, 1140.0, 763.0, 1127.0, 795.0],
  [2134.0, 112.0, 2090.0, 141.0],
  [1338.0, 1100.0, 1374.0, 1053.0, 1406.0, 1047.0, 1439.0, 1062.0],
  [297.0, 676.0, 312.0, 640.0, 345.0, 640.0],
  [317.0, 787.0, 271.0, 747.0, 246.0, 741.0, 236.0, 756.0],
  [319.0, 1123.0, 333.0, 1157.0, 305.0, 1196.0],
  [510.0, 1623.0, 442.0, 1644.0, 398.0, 1622.0],
  [510.0, 1623.0, 541.0, 1646.0, 634.0, 1652.0, 697.0, 1692.0],
  [681.0, 1337.0, 698.0, 1188.0, 760.0, 1051.0],
  [511.0, 1452.0, 480.0, 1488.0, 478.0, 1516.0, 503.0, 1543.0, 574.0, 1563.0],
  [115.0, 1637.0, 134.0, 1664.0, 169.0, 1672.0],
  [346.0, 639.0, 378.0, 597.0, 447.0, 646.0],
  [635.0, 1572.0, 682.0, 1575.0, 714.0, 1549.0, 726.0, 1508.0, 720.0, 1451.0],
  [
    1296.0,
    1739.0,
    1316.0,
    1680.0,
    1284.0,
    1651.0,
    1295.0,
    1601.0,
    1253.0,
    1518.0,
    1256.0,
    1494.0,
    1285.0,
    1462.0,
  ],
  [1296.0, 1739.0, 1358.0, 1800.0, 1401.0, 1799.0, 1448.0, 1762.0],
  [517.0, 596.0, 451.0, 562.0, 438.0, 584.0],
  [511.0, 1450.0, 572.0, 1244.0, 607.0, 1177.0],
  [168.0, 1082.0, 177.0, 1034.0, 226.0, 1006.0, 215.0, 925.0, 285.0, 882.0],
  [590.0, 1712.0, 519.0, 1692.0],
  [519.0, 596.0, 553.0, 555.0, 625.0, 593.0],
  [48.0, 1564.0, 62.0, 1629.0, 114.0, 1637.0],
  [2135.0, 112.0, 2269.0, 110.0, 2289.0, 47.0, 2283.0, 26.0, 2265.0, 19.0],
  [297.0, 677.0, 354.0, 728.0],
  [1380.0, 978.0, 1353.0, 964.0, 1315.0, 970.0, 1281.0, 1017.0],
  [626.0, 593.0, 660.0, 563.0, 728.0, 596.0],
  [2003.0, 274.0, 2066.0, 211.0, 2090.0, 141.0],
  [825.0, 624.0, 777.0, 581.0, 753.0, 576.0, 730.0, 596.0],
  [2090.0, 141.0, 2036.0, 150.0, 1996.0, 190.0, 1985.0, 236.0, 2001.0, 274.0],
  [
    1294.0,
    1410.0,
    1258.0,
    1385.0,
    1277.0,
    1310.0,
    1254.0,
    1267.0,
    1285.0,
    1224.0,
    1328.0,
    1201.0,
  ],
  [273.0, 697.0, 296.0, 677.0],
  [1305.0, 825.0, 1270.0, 809.0, 1238.0, 816.0, 1201.0, 865.0],
  [389.0, 688.0, 346.0, 641.0],
  [91.0, 1400.0, 57.0, 1381.0, 47.0, 1331.0, 56.0, 1282.0, 84.0, 1245.0],
  [1536.0, 1383.0, 1567.0, 1399.0],
  [
    1819.0,
    378.0,
    1916.0,
    569.0,
    1973.0,
    819.0,
    1992.0,
    1094.0,
    1977.0,
    1262.0,
    1927.0,
    1379.0,
    1869.0,
    1427.0,
    1812.0,
    1437.0,
    1785.0,
    1422.0,
    1777.0,
    1380.0,
    1809.0,
    1318.0,
    1798.0,
    1293.0,
    1777.0,
    1288.0,
    1688.0,
    1307.0,
    1568.0,
    1399.0,
  ],
  [656.0, 1445.0, 652.0, 1412.0],
  [
    296.0,
    1237.0,
    324.0,
    1279.0,
    278.0,
    1354.0,
    299.0,
    1393.0,
    272.0,
    1439.0,
    274.0,
    1482.0,
    302.0,
    1513.0,
    273.0,
    1558.0,
    283.0,
    1624.0,
    251.0,
    1655.0,
    170.0,
    1672.0,
  ],
  [
    1568.0,
    1400.0,
    1545.0,
    1493.0,
    1576.0,
    1520.0,
    1566.0,
    1618.0,
    1600.0,
    1653.0,
    1604.0,
    1684.0,
    1595.0,
    1712.0,
    1545.0,
    1746.0,
  ],
];
// ---- Eyes: drawn with elliptical arcs instead of free-form strokes ----

class _Eye {
  const _Eye({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ryUp,
    required this.ryLo,
    required this.angleDeg,
  });
  final double cx;
  final double cy;
  final double rx;
  final double ryUp;
  final double ryLo;
  final double angleDeg;
}

class _Pupil {
  const _Pupil({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
  });
  final double cx;
  final double cy;
  final double rx;
  final double ry;
}

// Eyebrows: full ellipses (flattened).
class _Brow {
  const _Brow({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    required this.angleDeg,
  });
  final double cx;
  final double cy;
  final double rx;
  final double ry;
  final double angleDeg;
}

const _Eye _kLeftEye = _Eye(
  cx: 480.5,
  cy: 1075,
  rx: 83.5,
  ryUp: 32.3,
  ryLo: 32.3,
  angleDeg: 0,
);
const _Eye _kRightEye = _Eye(
  cx: 938,
  cy: 1132.5,
  rx: 88,
  ryUp: 37.8,
  ryLo: 37.8,
  angleDeg: 0,
);
const _Pupil _kLeftPupil = _Pupil(cx: 480.5, cy: 1078.2, rx: 22.6, ry: 20.3);
const _Pupil _kRightPupil = _Pupil(cx: 938, cy: 1136.3, rx: 26.5, ry: 23.8);
const _Brow _kLeftBrow = _Brow(
  cx: 463,
  cy: 956,
  rx: 127,
  ry: 48.6,
  angleDeg: 2.25,
);
const _Brow _kRightBrow = _Brow(
  cx: 952,
  cy: 1035.5,
  rx: 148,
  ry: 54.9,
  angleDeg: 5.02,
);

class _CavivaraPainter extends CustomPainter {
  _CavivaraPainter({required this.strokeColor, this.winkProgress = 0});

  /// 線および塗りつぶした瞳の太さ（ソース画像の座標系での値）。
  static const double _strokeWidth = 20;

  /// 閉眼（[winkProgress] = 1）時に右目を縦方向へ潰す割合。
  static const double _winkCloseAmount = 0.92;

  /// ウィンクの影響を受けない静的な Path 群（輪郭などの自由曲線・眉・左目）。
  /// ソース画像座標系で定義されており、色・サイズ・ウィンク進捗に依存しない。
  /// 毎フレーム再生成するとアニメーションがカクつくため、一度だけ生成して使い回す。
  static final List<Path> _staticStrokePaths = _buildStaticStrokePaths();

  /// 静的に塗りつぶす左の瞳の Path。
  static final Path _leftPupilPath = _pupilPath(_kLeftPupil);

  /// ウィンクで変形させる右目・右の瞳の基準 Path（変形前）。
  static final Path _rightEyeBasePath = _eyePath(_kRightEye);
  static final Path _rightPupilBasePath = _pupilPath(_kRightPupil);

  final Color strokeColor;

  /// 右目のウィンク進捗。0 で開眼、1 で閉眼。
  final double winkProgress;

  @override
  void paint(Canvas canvas, Size size) {
    // ソース画像をアスペクト比を保ったまま中央に収まるよう拡縮・移動する。
    final sx = size.width / _kSrcWidth;
    final sy = size.height / _kSrcHeight;
    final s = sx < sy ? sx : sy;
    final dx = (size.width - _kSrcWidth * s) / 2;
    final dy = (size.height - _kSrcHeight * s) / 2;

    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(s, s);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    _drawStaticFeatures(canvas, strokePaint, fillPaint);
    _drawWinkingRightEye(canvas, strokePaint, fillPaint);

    canvas.restore();
  }

  /// ウィンクの影響を受けない部分（輪郭などの自由曲線・眉・左目・左の瞳）を描く。
  void _drawStaticFeatures(Canvas canvas, Paint strokePaint, Paint fillPaint) {
    for (final path in _staticStrokePaths) {
      canvas.drawPath(path, strokePaint);
    }

    canvas.drawPath(_leftPupilPath, fillPaint);
  }

  /// 右目（輪郭と瞳）をウィンク進捗に応じて目の中心を軸に上下へ潰して描く。
  /// 閉じると横線（細いレンズ形）になってウィンクに見える。
  void _drawWinkingRightEye(
    Canvas canvas,
    Paint strokePaint,
    Paint fillPaint,
  ) {
    final winkScaleY = 1.0 - _winkCloseAmount * winkProgress;
    final winkMatrix = Matrix4.identity()
      ..translateByDouble(_kRightEye.cx, _kRightEye.cy, 0, 1)
      ..scaleByDouble(1, winkScaleY, 1, 1)
      ..translateByDouble(-_kRightEye.cx, -_kRightEye.cy, 0, 1);

    canvas
      ..drawPath(
        _rightEyeBasePath.transform(winkMatrix.storage),
        strokePaint,
      )
      ..drawPath(
        _rightPupilBasePath.transform(winkMatrix.storage),
        fillPaint,
      );
  }

  /// ウィンクの影響を受けない静的なストローク Path をまとめて生成する。
  static List<Path> _buildStaticStrokePaths() => _buildStrokePaths()
    ..add(_browPath(_kLeftBrow))
    ..add(_browPath(_kRightBrow))
    ..add(_eyePath(_kLeftEye));

  // ---- Free-form strokes via Catmull-Rom -> cubic bezier ----
  static List<Path> _buildStrokePaths() {
    final paths = <Path>[];
    for (final stroke in _kStrokes) {
      final pts = <Offset>[];
      for (var i = 0; i + 1 < stroke.length; i += 2) {
        pts.add(Offset(stroke[i], stroke[i + 1]));
      }
      if (pts.length < 2) {
        continue;
      }

      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      if (pts.length == 2) {
        path.lineTo(pts[1].dx, pts[1].dy);
        paths.add(path);
        continue;
      }
      const tension = 6;
      for (var i = 0; i < pts.length - 1; i++) {
        final p0 = i == 0 ? pts[0] : pts[i - 1];
        final p1 = pts[i];
        final p2 = pts[i + 1];
        final p3 = (i + 2 < pts.length) ? pts[i + 2] : pts[pts.length - 1];
        final c1 = Offset(
          p1.dx + (p2.dx - p0.dx) / tension,
          p1.dy + (p2.dy - p0.dy) / tension,
        );
        final c2 = Offset(
          p2.dx - (p3.dx - p1.dx) / tension,
          p2.dy - (p3.dy - p1.dy) / tension,
        );
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
      }
      paths.add(path);
    }
    return paths;
  }

  // ---- Eye: almond shape = upper arc + lower arc of two ellipses ----
  //
  // The two arcs share the SAME corner points (inner/outer eye corner) at
  // (-rx, 0) and (+rx, 0). Each arc's ellipse center is pushed away from the
  // axis by [_kEyeTip], so the tangent at the corners is slanted instead of
  // vertical. Where the upper and lower arcs meet, their differing tangents
  // produce a sharp point -> the almond/cat-eye shape.
  static const double _kEyeTip = 45; // larger = sharper corners

  static Path _eyePath(_Eye e) {
    final rot = e.angleDeg * math.pi / 180.0;
    final center = Offset(e.cx, e.cy);

    final path = Path();
    _addLidArc(path, e.rx, e.ryUp, _kEyeTip, -1); // upper lid
    _addLidArc(path, e.rx, e.ryLo, _kEyeTip, 1); // lower lid

    final m = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..rotateZ(rot);
    return path.transform(m.storage);
  }

  /// Appends an elliptical arc that passes through the corners (-a, 0)/(a, 0)
  /// and bulges to a peak of height [h] (sign < 0 = upward, sign > 0 = down).
  /// [yc] offsets the ellipse center to slant the tangents at the corners,
  /// which is what makes the eye corners come to a point.
  static void _addLidArc(Path path, double a, double h, double yc, int sign) {
    final ry = h + yc;
    var val = 1 - (yc * yc) / (ry * ry);
    if (val <= 1e-6) {
      val = 1e-6;
    }
    final rx = a / math.sqrt(val);

    final se = -yc / ry; // sin at the corner points
    final ce = a / rx; // cos at the corner points
    var aLeft = math.atan2(se, -ce);
    final aRight = math.atan2(se, ce);
    if (aLeft > 0) {
      aLeft -= 2 * math.pi;
    }

    const n = 48;
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final th = aLeft + (aRight - aLeft) * t;
      final x = rx * math.cos(th);
      final y = yc + ry * math.sin(th);
      final yy = sign < 0 ? y : -y;
      if (i == 0) {
        path.moveTo(x, yy);
      } else {
        path.lineTo(x, yy);
      }
    }
  }

  static Path _pupilPath(_Pupil p) {
    return Path()..addOval(
      Rect.fromCenter(
        center: Offset(p.cx, p.cy),
        width: p.rx * 2,
        height: p.ry * 2,
      ),
    );
  }

  // ---- Eyebrow: an upper (convex) elliptical arc ----
  static Path _browPath(_Brow b) {
    final rot = b.angleDeg * math.pi / 180.0;
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: b.rx * 2,
      height: b.ry * 2,
    );
    // 180deg -> 360deg = top half of the ellipse (arches upward).
    final path = Path()..addArc(rect, math.pi, math.pi);
    final m = Matrix4.identity()
      ..translateByDouble(b.cx, b.cy, 0, 1)
      ..rotateZ(rot);
    return path.transform(m.storage);
  }

  @override
  bool shouldRepaint(covariant _CavivaraPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.winkProgress != winkProgress;
}
