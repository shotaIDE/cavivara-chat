import 'package:flutter/material.dart';
import 'package:house_worker/data/model/support_plan.dart';

/// SupportPlanにUI関連の機能を拡張するExtension
extension SupportPlanExtension on SupportPlan {
  /// プランの表示名
  String get displayName {
    return switch (this) {
      SupportPlan.small => 'ちょっと応援',
      SupportPlan.medium => 'しっかり応援',
      SupportPlan.large => 'めっちゃ応援',
    };
  }

  /// プランのアイコン
  IconData get icon {
    return switch (this) {
      SupportPlan.small => Icons.favorite_border,
      SupportPlan.medium => Icons.favorite,
      SupportPlan.large => Icons.volunteer_activism,
    };
  }

  /// 感謝メッセージ
  String get thankYouMessage {
    return switch (this) {
      SupportPlan.small => '頑張って!',
      SupportPlan.medium => 'いつもありがとう!',
      SupportPlan.large => 'これからも応援するヴィヴァ!',
    };
  }

  /// RevenueCatの商品ID (iOS/Android共通)
  String get productId {
    return switch (this) {
      SupportPlan.small => 'small_support',
      SupportPlan.medium => 'medium_support',
      SupportPlan.large => 'large_support',
    };
  }
}
