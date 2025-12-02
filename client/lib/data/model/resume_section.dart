import 'package:freezed_annotation/freezed_annotation.dart';

part 'resume_section.freezed.dart';

/// 履歴書セクション
///
/// カヴィヴァラの履歴書を構成するセクション情報を保持する
@freezed
abstract class ResumeSection with _$ResumeSection {
  const factory ResumeSection({
    /// セクションID
    required String id,

    /// セクションタイトル
    required String title,

    /// セクション内容（項目リスト）
    required List<String> items,

    /// 表示順序
    required int order,
  }) = _ResumeSection;

  const ResumeSection._();
}

/// 履歴書セクション種別
///
/// 定義済みの履歴書セクション種別を提供する
enum ResumeSectionType {
  /// 専門分野
  expertise('expertise', '専門分野'),

  /// 性格・スタイル
  personality('personality', '性格・スタイル'),

  /// コミュニケーション指針
  communication('communication', 'コミュニケーション指針'),

  /// 代表的な活動
  activities('activities', '代表的な活動');

  const ResumeSectionType(this.id, this.displayName);

  /// セクションID
  final String id;

  /// 表示名
  final String displayName;
}
