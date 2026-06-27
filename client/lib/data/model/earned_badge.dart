import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/data/model/app_badge.dart';

part 'earned_badge.freezed.dart';
part 'earned_badge.g.dart';

/// 獲得済みバッジを表すモデル
@freezed
abstract class EarnedBadge with _$EarnedBadge {
  const factory EarnedBadge({
    required AppBadge badge,
    required DateTime earnedAt,
  }) = _EarnedBadge;

  factory EarnedBadge.fromJson(Map<String, dynamic> json) =>
      _$EarnedBadgeFromJson(json);
}
