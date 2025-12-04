import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/data/model/support_plan.dart';

part 'support_history.freezed.dart';
part 'support_history.g.dart';

/// 応援履歴を表すモデル
@freezed
abstract class SupportHistory with _$SupportHistory {
  const factory SupportHistory({
    required DateTime timestamp,
    required SupportPlan plan,
    required int earnedVP,
    required int totalVPAfter,
  }) = _SupportHistory;

  factory SupportHistory.fromJson(Map<String, dynamic> json) =>
      _$SupportHistoryFromJson(json);
}
