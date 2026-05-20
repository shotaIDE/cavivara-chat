import 'package:flutter/material.dart';
import 'package:house_worker/data/model/chat_bubble_design.dart';
import 'package:house_worker/ui/component/cat_fur_bubble_painter.dart';
import 'package:house_worker/ui/component/harmonized_bubble_clipper.dart';

enum MessageType {
  user, // ユーザーメッセージ
  ai, // AIメッセージ
  system, // システムメッセージ
}

extension ChatBubbleDesignExtension on ChatBubbleDesign {
  String get displayName {
    switch (this) {
      case ChatBubbleDesign.corporateStandard:
        return '社内標準様式';
      case ChatBubbleDesign.nextGeneration:
        return '次世代様式';
      case ChatBubbleDesign.harmonized:
        return '調整済様式';
      case ChatBubbleDesign.catFur:
        return '猫毛様式';
    }
  }

  bool get shouldWithPointer {
    switch (this) {
      case ChatBubbleDesign.corporateStandard:
        return true;
      case ChatBubbleDesign.nextGeneration:
        return false;
      case ChatBubbleDesign.harmonized:
        return false;
      case ChatBubbleDesign.catFur:
        return false;
    }
  }

  Widget buildBubble({
    required BuildContext context,
    required MessageType messageType,
    required Color backgroundColor,
    required Widget child,
    int seed = 0,
  }) {
    const padding = EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    );
    final constraints = BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.8,
    );

    switch (this) {
      case ChatBubbleDesign.corporateStandard:
        return Container(
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );

      case ChatBubbleDesign.nextGeneration:
        final BorderRadius borderRadius;
        switch (messageType) {
          case MessageType.user:
            borderRadius = const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(2), // ツノがあった位置
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            );
          case MessageType.ai:
            borderRadius = const BorderRadius.only(
              topLeft: Radius.circular(2), // ツノがあった位置
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            );
          case MessageType.system:
            borderRadius = BorderRadius.circular(8);
        }

        return Container(
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: child,
        );

      case ChatBubbleDesign.harmonized:
        return ClipPath(
          clipper: HarmonizedBubbleClipper(
            messageType: messageType,
          ),
          child: Container(
            constraints: constraints,
            padding: padding,
            color: backgroundColor,
            child: child,
          ),
        );

      case ChatBubbleDesign.catFur:
        return _CatFurBubble(
          seed: seed,
          constraints: constraints,
          padding: padding.copyWith(
            left: padding.left + CatFurBubblePainter.maxOuterExtent,
            right: padding.right + CatFurBubblePainter.maxOuterExtent,
            top: padding.top + CatFurBubblePainter.maxOuterExtent,
            bottom: padding.bottom + CatFurBubblePainter.maxOuterExtent,
          ),
          child: child,
        );
    }
  }
}

/// 猫毛様式の吹き出し本体。
///
/// 毛先が風に靡くアニメーションを駆動するため、独立した [StatefulWidget] として
/// [AnimationController] を保持し、その値を [CatFurBubblePainter] に渡す。
class _CatFurBubble extends StatefulWidget {
  const _CatFurBubble({
    required this.seed,
    required this.constraints,
    required this.padding,
    required this.child,
  });

  /// 1サイクルの周期。値が長いほど毛先がゆっくり靡く。
  static const _windPeriod = Duration(milliseconds: 4200);

  final int seed;
  final BoxConstraints constraints;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  State<_CatFurBubble> createState() => _CatFurBubbleState();
}

class _CatFurBubbleState extends State<_CatFurBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _windController;

  @override
  void initState() {
    super.initState();
    _windController = AnimationController(
      vsync: this,
      duration: _CatFurBubble._windPeriod,
    )..repeat();
  }

  @override
  void dispose() {
    _windController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CatFurBubblePainter(
        seed: widget.seed,
        windAnimation: _windController,
      ),
      child: Container(
        constraints: widget.constraints,
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}
