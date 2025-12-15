/// 応援プランを表すenum
enum SupportPlan {
  /// ちょっと応援
  small('small', 1),

  /// しっかり応援
  medium('medium', 4),

  /// めっちゃ応援
  large('large', 10)
  ;

  const SupportPlan(this.storeIdentifier, this.vivaPoint);

  /// RevenueCatの商品ID (iOS/Android共通)
  final String storeIdentifier;

  /// 獲得ヴィヴァポイント
  final int vivaPoint;
}
