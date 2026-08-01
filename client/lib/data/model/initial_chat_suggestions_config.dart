import 'package:freezed_annotation/freezed_annotation.dart';

part 'initial_chat_suggestions_config.freezed.dart';

/// 会話開始時に表示するサジェストの設定
///
/// Remote Config から取得した内容、またはアプリに埋め込んだ組み込みデフォルト設定を表す。
@freezed
abstract class InitialChatSuggestionsConfig
    with _$InitialChatSuggestionsConfig {
  const factory InitialChatSuggestionsConfig({
    /// 設定の構造バージョン
    required int schemaVersion,

    /// 表示候補のサジェスト
    ///
    /// このうち何件を実際に表示するかはアプリ側が決める。
    @Default([]) List<InitialChatSuggestion> suggestions,
  }) = _InitialChatSuggestionsConfig;
}

/// 会話開始時に表示するサジェストの 1 件
@freezed
abstract class InitialChatSuggestion with _$InitialChatSuggestion {
  const factory InitialChatSuggestion({
    /// タップした際に送信される文言
    ///
    /// カードに表示する文言も兼ねる。
    required String label,

    /// カードに表示するアイコンの種別
    @Default(InitialChatSuggestionIcon.chat) InitialChatSuggestionIcon icon,
  }) = _InitialChatSuggestion;
}

/// サジェストのカードに表示するアイコンの種別
///
/// アイコンの実体（`IconData`）はビルド時にツリーシェイクされるため、Remote Config から
/// 任意のアイコンを指定することはできない。アプリがあらかじめ用意した候補の中からの
/// 選択のみを許し、識別子と `IconData` の対応はUI層の拡張で解決する。
enum InitialChatSuggestionIcon {
  /// 種別が指定されていない場合や、アプリが知らない種別が指定された場合に使う既定のアイコン
  chat,

  // マンドリン・音楽関連
  queueMusic,
  musicNote,
  libraryMusic,
  piano,
  album,
  headphones,
  event,
  group,
  people,
  build,

  // 一般的な話題
  restaurantMenu,
  flightTakeoff,
  fitnessCenter,
  book,
  lightbulb,
  wbSunny,
  movie,
  language,
  coffee,
  work,
  school,
  pets,
  celebration,
  savings,
  favorite,
  help,
}
