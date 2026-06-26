import 'package:flutter/material.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';

/// 称号画像ウィジェット
///
/// ランクごとのカヴィヴァラ画像を角丸の正方形で表示する。
/// 画像の読み込みに失敗した場合は、称号のアイコンを表示する。
class SupporterTitleImage extends StatelessWidget {
  const SupporterTitleImage({
    required this.title,
    this.size = 40,
    super.key,
  });

  /// 表示する称号
  final SupporterTitle title;

  /// 表示サイズ
  final double size;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size / 4);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        title.imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // 大きな画像をデコード時に表示サイズへ縮小し、メモリ使用量を抑える。
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            title.icon,
            size: size,
            color: title.color,
          );
        },
      ),
    );
  }
}
