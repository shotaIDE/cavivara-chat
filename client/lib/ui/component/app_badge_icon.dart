import 'package:flutter/material.dart';
import 'package:house_worker/data/model/app_badge.dart';
import 'package:house_worker/ui/component/app_badge_extension.dart';

/// バッジを正方形のリッチな見た目で表示するウィジェット
class AppBadgeIcon extends StatelessWidget {
  const AppBadgeIcon({
    required this.badge,
    required this.size,
    super.key,
  });

  final AppBadge badge;

  /// 正方形の一辺の長さ
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = badge.gradientColors;

    // 角丸の正方形の外形
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(size * 0.24),
    );

    // 立体感を出すための影
    final shadow = BoxShadow(
      color: colors.last.withValues(alpha: 0.4),
      blurRadius: size * 0.16,
      offset: Offset(0, size * 0.08),
    );

    // 画像を持つバッジは、グラデーションとアイコンの代わりに画像を表示する。
    final imagePath = badge.imagePath;
    if (imagePath != null) {
      return Container(
        width: size,
        height: size,
        decoration: ShapeDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          shape: shape.copyWith(
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.6),
              width: size * 0.03,
            ),
          ),
          shadows: [shadow],
        ),
      );
    }

    // アイコンの背面に敷く半透明の円（リッチさを演出）
    final iconBackdrop = Container(
      width: size * 0.62,
      height: size * 0.62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(
        badge.icon,
        size: size * 0.42,
        color: Colors.white,
      ),
    );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        shape: shape.copyWith(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.6),
            width: size * 0.03,
          ),
        ),
        shadows: [shadow],
      ),
      child: iconBackdrop,
    );
  }
}
