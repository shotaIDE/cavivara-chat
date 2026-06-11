import 'package:flutter/material.dart';
import 'package:house_worker/ui/component/cavivara_avatar.dart';
import 'package:house_worker/ui/component/cavivara_entrance_animation.dart';

/// カヴィヴァラさんの肖像画を、美術館の額装のような額縁付きで表示するウィジェット。
///
/// 業績画面とドロワーで共有する。
class CavivaraPortrait extends StatelessWidget {
  const CavivaraPortrait({
    this.frameColor,
    this.maxWidth = 200,
    this.animate = false,
    this.simplified = false,
    super.key,
  });

  /// 額縁の色。サポーター称号の色に合わせる。null の場合はテーマの既定色を使う。
  final Color? frameColor;

  /// 額縁の最大幅。
  final double maxWidth;

  /// 表示時に、拡大しながらふわっとフェードインさせるか。
  final bool animate;

  /// 内側の簡易的な額縁のみを描画するか。発光やドロップシャドウは付けない。
  final bool simplified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedFrameColor = frameColor ?? theme.colorScheme.outlineVariant;

    // 額縁の明暗。称号色から明部・暗部・最暗部を作り、立体的な額装を表現する
    final frameHsl = HSLColor.fromColor(resolvedFrameColor);
    final lighterFrameColor = frameHsl
        .withLightness((frameHsl.lightness + 0.18).clamp(0.0, 1.0))
        .toColor();
    final darkerFrameColor = frameHsl
        .withLightness((frameHsl.lightness - 0.18).clamp(0.0, 1.0))
        .toColor();
    final deepestFrameColor = frameHsl
        .withLightness((frameHsl.lightness - 0.35).clamp(0.0, 1.0))
        .toColor();

    // 肖像画全体が額縁内に収まるよう、切り取らずに余白を付けて表示する
    final portrait = AspectRatio(
      aspectRatio: 3 / 4,
      child: Image.asset(
        CavivaraAvatar.defaultAssetPath,
        fit: BoxFit.contain,
      ),
    );

    // 作品まわりの細い縁取り
    final portraitWithLine = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: darkerFrameColor.withValues(alpha: 0.4),
        ),
      ),
      child: portrait,
    );

    // 広めの台紙（マット）。美術館の額装のように作品の周囲に余白を取る
    final mat = Container(
      padding: const EdgeInsets.all(18),
      color: theme.colorScheme.surface,
      child: portraitWithLine,
    );

    // 簡易表示では、台紙の周りに細い枠を付けただけの額縁にする
    if (simplified) {
      final simpleFrame = Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: resolvedFrameColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: mat,
      );

      return Center(
        child: Semantics(
          label: 'カヴィヴァラさんの肖像画',
          image: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: simpleFrame,
          ),
        ),
      );
    }

    // 額縁の溝（リップ）。モールディングと台紙の境目を暗くして奥行きを出す
    final lip = Container(
      padding: const EdgeInsets.all(3),
      color: deepestFrameColor,
      child: mat,
    );

    // 外側のモールディング（金枠）。光沢グラデーションとハイライトの縁取りで
    // 立体的な額装を表現し、周囲を称号色で発光させる
    final framedPortrait = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            lighterFrameColor,
            resolvedFrameColor,
            darkerFrameColor,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: lighterFrameColor.withValues(alpha: 0.7),
        ),
        boxShadow: [
          // 称号色で額縁の周囲をぼかして発光しているように見せる
          BoxShadow(
            color: resolvedFrameColor.withValues(alpha: 0.6),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: resolvedFrameColor.withValues(alpha: 0.35),
            blurRadius: 48,
            spreadRadius: 8,
          ),
          // 額縁を壁から浮かせるドロップシャドウ
          const BoxShadow(
            color: Color(0x55000000),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: lip,
    );

    final centeredPortrait = Center(
      child: Semantics(
        label: 'カヴィヴァラさんの肖像画',
        image: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: framedPortrait,
        ),
      ),
    );

    if (!animate) {
      return centeredPortrait;
    }

    // 表示時に、拡大しながらふわっとフェードインさせる
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: CavivaraEntranceAnimation.duration,
      curve: CavivaraEntranceAnimation.curve,
      child: centeredPortrait,
      builder: (context, value, child) {
        return Opacity(
          // easeOutBack は終盤で 1.0 を超えるため、不透明度は範囲内に収める
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.7 + 0.3 * value,
            child: child,
          ),
        );
      },
    );
  }
}
