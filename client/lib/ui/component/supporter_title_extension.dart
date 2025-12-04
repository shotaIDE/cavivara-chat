import 'package:flutter/material.dart';
import 'package:house_worker/data/model/supporter_title.dart';

/// SupporterTitleにUI関連の機能を拡張するExtension
extension SupporterTitleExtension on SupporterTitle {
  /// 称号の表示名
  String get displayName {
    return switch (this) {
      SupporterTitle.newbie => '駆け出しヴィヴァサポーター',
      SupporterTitle.beginner => '初心ヴィヴァサポーター',
      SupporterTitle.intermediate => '一人前ヴィヴァサポーター',
      SupporterTitle.advanced => 'ベテランヴィヴァサポーター',
      SupporterTitle.expert => '熟練ヴィヴァサポーター',
      SupporterTitle.master => '達人ヴィヴァサポーター',
      SupporterTitle.legend => '伝説のヴィヴァサポーター',
    };
  }

  /// 称号の説明文
  String get description {
    return switch (this) {
      SupporterTitle.newbie => '応援を始めたばかりのサポーター',
      SupporterTitle.beginner => '定期的に応援してくれるサポーター',
      SupporterTitle.intermediate => '頻繁に応援してくれるサポーター',
      SupporterTitle.advanced => '長年応援し続けているサポーター',
      SupporterTitle.expert => 'カヴィヴァラの熱心な支援者',
      SupporterTitle.master => 'カヴィヴァラを深く理解する支援者',
      SupporterTitle.legend => 'カヴィヴァラ界のレジェンド',
    };
  }

  /// 必要最低VP
  int get requiredVP {
    return switch (this) {
      SupporterTitle.newbie => 0,
      SupporterTitle.beginner => 10,
      SupporterTitle.intermediate => 30,
      SupporterTitle.advanced => 70,
      SupporterTitle.expert => 150,
      SupporterTitle.master => 300,
      SupporterTitle.legend => 500,
    };
  }

  /// 称号アイコン
  IconData get icon {
    return switch (this) {
      SupporterTitle.newbie => Icons.star_border,
      SupporterTitle.beginner => Icons.star_half,
      SupporterTitle.intermediate => Icons.star,
      SupporterTitle.advanced => Icons.stars,
      SupporterTitle.expert => Icons.workspace_premium,
      SupporterTitle.master => Icons.military_tech,
      SupporterTitle.legend => Icons.emoji_events,
    };
  }

  /// 称号の色
  Color get color {
    return switch (this) {
      SupporterTitle.newbie => Colors.grey,
      SupporterTitle.beginner => const Color(0xFFCD7F32), // ブロンズ
      SupporterTitle.intermediate => const Color(0xFFC0C0C0), // シルバー
      SupporterTitle.advanced => const Color(0xFFFFD700), // ゴールド
      SupporterTitle.expert => const Color(0xFFE5E4E2), // プラチナ
      SupporterTitle.master => const Color(0xFF50C878), // エメラルド
      SupporterTitle.legend => const Color(0xFFB9F2FF), // ダイヤモンド
    };
  }
}
