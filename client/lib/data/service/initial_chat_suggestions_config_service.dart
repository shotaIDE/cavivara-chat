import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:house_worker/data/model/initial_chat_suggestions_config.dart';
import 'package:house_worker/data/model/initial_chat_suggestions_config_exception.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:house_worker/data/service/remote_config_service.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'initial_chat_suggestions_config_service.g.dart';

final _logger = Logger('InitialChatSuggestionsConfigService');

/// アプリが解釈できる設定の構造バージョンの上限
///
/// これを超えるバージョンの設定は、部分的に解釈すると意図しないサジェストを
/// 表示することになるため、設定全体を破棄して組み込みデフォルト設定を使用する。
const int supportedInitialChatSuggestionsSchemaVersion = 1;

/// 一度に表示するサジェストの件数の既定値
const int defaultInitialChatSuggestionDisplayCount = 3;

/// アプリに埋め込んだ組み込みデフォルト設定
///
/// Remote Config に値が設定されていない場合や、設定を解釈できなかった場合に使用する。
/// Remote Config 未設定の環境（ローカル開発、Firebase 初期化失敗時、エミュレーター Suite）
/// でも従来と同じサジェストが表示されるよう、Remote Config 導入前の内容をそのまま持つ。
const InitialChatSuggestionsConfig defaultInitialChatSuggestionsConfig =
    InitialChatSuggestionsConfig(
      schemaVersion: supportedInitialChatSuggestionsSchemaVersion,
      displayCount: defaultInitialChatSuggestionDisplayCount,
      suggestions: [
        // カヴィヴァラ・マンドリン関連
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.queueMusic,
          label: 'マンドリンの演奏会の選曲会議で何を出すか迷っているヴィヴァ',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.group,
          label: 'プレクトラム結社の最新の演奏会について教えて',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.musicNote,
          label: 'マンドリンの練習方法を教えてヴィヴァ',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.libraryMusic,
          label: 'マンドリンオーケストラのおすすめ曲は？',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.piano,
          label: 'トレモロを綺麗に弾くコツを教えて',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.event,
          label: '演奏会のプログラム構成のアドバイスをくださいヴィヴァ',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.headphones,
          label: 'マンドリンの歴史について教えて',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.build,
          label: 'マンドリンの弦の張り替え方を教えて',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.album,
          label: 'イタリアのマンドリン曲でおすすめは？',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.people,
          label: 'アンサンブルで合わせるコツを教えてヴィヴァ',
        ),
        // 一般的な質問
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.restaurantMenu,
          label: '今晩の夜ご飯のレシピを考えて',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.flightTakeoff,
          label: '週末のお出かけスポットを教えてヴィヴァ',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.fitnessCenter,
          label: '家でできる簡単なストレッチを教えて',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.book,
          label: 'おすすめの本を紹介して',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.lightbulb,
          label: '集中力を高める方法を教えて',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.wbSunny,
          label: '朝のルーティンのおすすめを教えてヴィヴァ',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.movie,
          label: '最近観た映画のおすすめを教えて',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.language,
          label: '効果的な語学学習の方法を教えて',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.coffee,
          label: 'リラックスできる休日の過ごし方は？',
        ),
        InitialChatSuggestion(
          icon: InitialChatSuggestionIcon.work,
          label: '仕事の効率を上げるコツを教えてヴィヴァ',
        ),
      ],
    );

/// 会話開始時に表示するサジェストの設定
///
/// Remote Config に有効な設定がない場合は、組み込みデフォルト設定を返す。
@riverpod
InitialChatSuggestionsConfig initialChatSuggestionsConfig(Ref ref) {
  final rawJson = ref.watch(initialChatSuggestionsConfigJsonProvider);
  if (rawJson.isEmpty) {
    _logger.info(
      'Remote Config に会話開始時のサジェストの設定がないため、組み込みデフォルト設定を使用します。',
    );
    return defaultInitialChatSuggestionsConfig;
  }

  try {
    return parseInitialChatSuggestionsConfig(rawJson);
  } on InitialChatSuggestionsConfigExceptionUnsupportedSchemaVersion catch (e) {
    // アプリと Remote Config の世代差でも発生し得るため、Crashlytics には報告しない
    _logger.warning(
      '会話開始時のサジェストの設定の構造バージョン ${e.schemaVersion} に対応していないため、'
      '組み込みデフォルト設定を使用します。',
    );
    return defaultInitialChatSuggestionsConfig;
  } on Exception catch (e, stackTrace) {
    _logger.severe('会話開始時のサジェストの設定の解釈に失敗: $e');
    unawaited(ref.read(errorReportServiceProvider).recordError(e, stackTrace));

    return defaultInitialChatSuggestionsConfig;
  }
}

/// 生の JSON から会話開始時のサジェストの設定を解釈する
///
/// 設定全体を破棄すべき内容だった場合は
/// [InitialChatSuggestionsConfigException] を投げる。
/// 個別のサジェストに不正があった場合は、その要素のみを除外して解釈を続ける。
@visibleForTesting
InitialChatSuggestionsConfig parseInitialChatSuggestionsConfig(String rawJson) {
  final Object? decoded;
  try {
    decoded = jsonDecode(rawJson);
  } on FormatException catch (e) {
    throw InitialChatSuggestionsConfigException.malformed(
      message: 'JSON が不正です: $e',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    throw const InitialChatSuggestionsConfigException.malformed(
      message: '設定のルートがオブジェクトではありません。',
    );
  }

  final schemaVersion = decoded['schemaVersion'];
  if (schemaVersion is! int) {
    throw const InitialChatSuggestionsConfigException.malformed(
      message: 'schemaVersion が指定されていません。',
    );
  }

  if (schemaVersion > supportedInitialChatSuggestionsSchemaVersion) {
    throw InitialChatSuggestionsConfigException.unsupportedSchemaVersion(
      schemaVersion: schemaVersion,
    );
  }

  final rawSuggestions = decoded['suggestions'];
  if (rawSuggestions is! List) {
    throw const InitialChatSuggestionsConfigException.malformed(
      message: 'suggestions が指定されていません。',
    );
  }

  return InitialChatSuggestionsConfig(
    schemaVersion: schemaVersion,
    displayCount: _parseDisplayCount(decoded['displayCount']),
    suggestions: _parseSuggestions(rawSuggestions),
  );
}

/// 表示件数を解釈する
///
/// 表示件数だけの誤りで設定全体を破棄する必要はないため、不正な値は既定値に読み替える。
int _parseDisplayCount(Object? rawDisplayCount) {
  if (rawDisplayCount == null) {
    return defaultInitialChatSuggestionDisplayCount;
  }

  if (rawDisplayCount is! int || rawDisplayCount < 1) {
    _logger.warning('表示件数が不正なため既定値を使用します: $rawDisplayCount');
    return defaultInitialChatSuggestionDisplayCount;
  }

  return rawDisplayCount;
}

/// サジェストのリストを解釈する
///
/// 解釈できないサジェストと、文言が重複したサジェストは除外する。
List<InitialChatSuggestion> _parseSuggestions(List<dynamic> rawSuggestions) {
  final suggestions = <InitialChatSuggestion>[];
  final labels = <String>{};

  for (final rawSuggestion in rawSuggestions) {
    final suggestion = _parseSuggestion(rawSuggestion);
    if (suggestion == null) {
      continue;
    }

    // 同じ文言のカードが並ぶと選択肢が実質的に減るため、重複は取り除く
    if (!labels.add(suggestion.label)) {
      _logger.warning('サジェストの文言が重複しているため除外します: ${suggestion.label}');
      continue;
    }

    suggestions.add(suggestion);
  }

  return List.unmodifiable(suggestions);
}

/// サジェストを 1 件解釈する
///
/// 解釈できない場合や、無効化されている場合は `null` を返す。
InitialChatSuggestion? _parseSuggestion(Object? rawSuggestion) {
  if (rawSuggestion is! Map<String, dynamic>) {
    _logger.warning('サジェストがオブジェクトではないため除外します: $rawSuggestion');
    return null;
  }

  final enabled = rawSuggestion['enabled'];
  if (enabled is bool && !enabled) {
    return null;
  }

  final label = _parseNonEmptyString(rawSuggestion['label']);
  if (label == null) {
    _logger.warning('サジェストの文言が指定されていないため除外します: $rawSuggestion');
    return null;
  }

  return InitialChatSuggestion(
    label: label,
    icon: _parseIcon(rawSuggestion['icon']),
  );
}

/// アイコンの種別を解釈する
///
/// アイコンは装飾であり、種別を解釈できなくても文言を送信するというサジェストの
/// 役割は果たせる。そのため、未知の種別が指定された場合もサジェストごと除外はせず、
/// 既定のアイコンに読み替える。
InitialChatSuggestionIcon _parseIcon(Object? rawIcon) {
  if (rawIcon == null) {
    return InitialChatSuggestionIcon.chat;
  }

  final icon = InitialChatSuggestionIcon.values.firstWhereOrNull(
    (icon) => icon.name == rawIcon,
  );
  if (icon == null) {
    _logger.warning('未対応のアイコンが指定されているため既定のアイコンを使用します: $rawIcon');
    return InitialChatSuggestionIcon.chat;
  }

  return icon;
}

String? _parseNonEmptyString(Object? rawValue) {
  if (rawValue is! String) {
    return null;
  }

  final trimmed = rawValue.trim();
  return trimmed.isEmpty ? null : trimmed;
}
