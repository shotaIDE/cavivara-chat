import 'package:flutter/material.dart';

class CavivaraAvatar extends StatelessWidget {
  const CavivaraAvatar({
    super.key,
    this.size = 40,
    this.onTap,
    this.assetPath = _defaultAssetPath,
    this.backgroundColor,
  });

  final double size;
  final VoidCallback? onTap;
  final String assetPath;
  final Color? backgroundColor;

  static const String defaultAssetPath = 'assets/image/cavivara.png';
  static const String _defaultAssetPath = defaultAssetPath;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    const label = 'カヴィヴァラさんのアイコン';

    Widget buildImage() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: backgroundColor,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    if (onTap == null) {
      return Semantics(
        label: label,
        image: true,
        child: buildImage(),
      );
    }

    return Semantics(
      label: label,
      button: true,
      image: true,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                image: DecorationImage(
                  image: AssetImage(assetPath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
