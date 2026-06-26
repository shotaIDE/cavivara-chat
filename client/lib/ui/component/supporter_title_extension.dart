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

  /// 称号アイコン
  ///
  /// 画像の読み込みに失敗した場合のフォールバックとしても利用する。
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

  /// 称号画像のアセットパス
  String get imagePath {
    return switch (this) {
      SupporterTitle.newbie => 'assets/image/cavivara_01.png',
      SupporterTitle.beginner => 'assets/image/cavivara_02.png',
      SupporterTitle.intermediate => 'assets/image/cavivara_03.png',
      SupporterTitle.advanced => 'assets/image/cavivara_04.png',
      SupporterTitle.expert => 'assets/image/cavivara_05.png',
      SupporterTitle.master => 'assets/image/cavivara_06.png',
      SupporterTitle.legend => 'assets/image/cavivara_07.png',
    };
  }

  /// 称号の色
  Color get color {
    return switch (this) {
      SupporterTitle.newbie => const Color(0xFF9A9A9A), // 鉄（くすんだグレー）
      SupporterTitle.beginner => const Color(0xFFC17A3F), // ブロンズ（銅）
      SupporterTitle.intermediate => const Color(0xFFEB6A8C), // ピンク（紅梅）
      SupporterTitle.advanced => const Color(0xFFE6B422), // ゴールド（金）
      SupporterTitle.expert => const Color(0xFF1FA567), // エメラルド（翠玉）
      SupporterTitle.master => const Color(0xFF2E63D6), // サファイア（青玉）
      SupporterTitle.legend => const Color(0xFF7A3FB5), // ロイヤルパープル（紫水晶）
    };
  }
}
