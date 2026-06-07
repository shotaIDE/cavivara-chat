import 'package:freezed_annotation/freezed_annotation.dart';

part 'cavivara_profile.freezed.dart';

/// カヴィヴァラのプロフィール
///
/// カヴィヴァラキャラクターの基本情報とAI用プロンプトを保持する
@freezed
abstract class CavivaraProfile with _$CavivaraProfile {
  const factory CavivaraProfile({
    /// 表示名
    required String displayName,

    /// 役職・肩書き
    required String title,

    /// 自己紹介・説明文
    required String description,

    /// アイコン画像のパス
    required String iconPath,

    /// AI用プロンプト
    required String aiPrompt,

    /// タグ一覧
    required List<String> tags,
  }) = _CavivaraProfile;

  const CavivaraProfile._();
}
