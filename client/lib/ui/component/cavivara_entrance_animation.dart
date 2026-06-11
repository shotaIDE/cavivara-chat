import 'package:flutter/animation.dart';

/// カヴィヴァラさんの登場演出で共有するアニメーション定義。
///
/// 業績画面の肖像画やトーク画面の入場など、カヴィヴァラさんが画面に
/// 現れる際の演出で、統一感を出すために時間とカーブを共通化する。
abstract final class CavivaraEntranceAnimation {
  /// 登場演出にかける時間。
  static const duration = Duration(milliseconds: 700);

  /// 登場演出のアニメーションカーブ。少し行き過ぎてから戻ることで、
  /// ぴょこっと飛び出すような印象を与える。
  static const Curve curve = Curves.easeOutBack;
}
