/// 応援プランを表すenum
enum SupportPlan {
  /// ちょっと応援
  small('support-small', 1),

  /// しっかり応援
  medium('support-medium', 4),

  /// めっちゃ応援
  large('support-large', 8)
  ;

  const SupportPlan(this.storeIdentifier, this.vivaPoint);

  /// RevenueCatの商品ID (iOS/Android共通)
  final String storeIdentifier;

  /// 獲得ヴィヴァポイント
  final int vivaPoint;
}
