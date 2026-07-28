import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:house_worker/data/model/function_calling_config.dart';
import 'package:house_worker/data/model/function_calling_config_exception.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:house_worker/data/service/remote_config_service.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'function_calling_config_service.g.dart';

final _logger = Logger('FunctionCallingConfigService');

/// アプリが解釈できる設定の構造バージョンの上限
///
/// これを超えるバージョンの設定は、部分的に解釈すると誤った関数宣言をモデルに
/// 渡すことになるため、設定全体を破棄して組み込みデフォルト設定を使用する。
const int supportedFunctionCallingSchemaVersion = 1;

/// 関数名として許容する形式
///
/// Gemini API の制約に合わせ、英字またはアンダースコアで始まる 64 文字以内とする。
final _functionNamePattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]{0,63}$');

/// アプリに埋め込んだ組み込みデフォルト設定
///
/// Remote Config に値が設定されていない場合や、設定を解釈できなかった場合に使用する。
const FunctionCallingToolConfig defaultFunctionCallingConfig =
    FunctionCallingToolConfig(
      schemaVersion: supportedFunctionCallingSchemaVersion,
      toolInstruction: '''
## 情報の取得ルール（厳守）
- プレクトラム結社の公式情報（給与、定期演奏会、開催日時、会場、イベントなど）を尋ねられた場合は、必ず getPlectrumSocietyKnowledge 関数を呼び出して取得した内容のみを根拠に回答する。推測や記憶で答えてはならない。
- 現在の日時や「今日」「今」など時点に依存する情報が必要な場合は、必ず getCurrentDateTime 関数を呼び出す。
- 関数で該当情報が得られなかった場合は、分からない旨を正直に伝える。''',
      functions: [
        FunctionCallingFunction(
          name: 'getPlectrumSocietyKnowledge',
          handler: FunctionCallingHandler.knowledgeLookup,
          description: 'プレクトラム結社に関する社内公式知識を取得します。',
          parameters: [
            FunctionCallingParameter(
              name: 'topic',
              type: FunctionCallingParameterType.string,
              description: '取得したいトピックID。',
              isRequired: true,
            ),
            FunctionCallingParameter(
              name: 'query',
              type: FunctionCallingParameterType.string,
              description: '自然言語で記述された検索クエリ。例: "給料は？"',
              isRequired: true,
            ),
          ],
          entries: [
            KnowledgeEntry(
              topic: 'salary_policy',
              title: '給与制度',
              summary: '結社の給料は0円。毎年5%のベースアップが行われているが、元々0円のため昇給額も0円。',
              facts: [
                '結社の給料は0円です。',
                '毎年5%のベースアップが実施されますが、もともとが0円のため昇給額も0円です。',
              ],
              keywords: [
                '給料',
                '給与',
                '賃金',
                '報酬',
                'ベースアップ',
                '昇給',
                '0円',
              ],
            ),
          ],
        ),
      ],
    );

/// Function Calling の設定
///
/// Remote Config に有効な設定がない場合は、組み込みデフォルト設定を返す。
@riverpod
FunctionCallingToolConfig functionCallingConfig(Ref ref) {
  final rawJson = ref.watch(functionCallingConfigJsonProvider);
  if (rawJson.isEmpty) {
    _logger.info(
      'Remote Config に Function Calling の設定がないため、組み込みデフォルト設定を使用します。',
    );
    return defaultFunctionCallingConfig;
  }

  try {
    return parseFunctionCallingConfig(rawJson);
  } on FunctionCallingConfigExceptionUnsupportedSchemaVersion catch (e) {
    // アプリと Remote Config の世代差でも発生し得るため、Crashlytics には報告しない
    _logger.warning(
      'Function Calling の設定の構造バージョン ${e.schemaVersion} に対応していないため、'
      '組み込みデフォルト設定を使用します。',
    );
    return defaultFunctionCallingConfig;
  } on Exception catch (e, stackTrace) {
    _logger.severe('Function Calling の設定の解釈に失敗: $e');
    unawaited(ref.read(errorReportServiceProvider).recordError(e, stackTrace));

    return defaultFunctionCallingConfig;
  }
}

/// 生の JSON から Function Calling の設定を解釈する
///
/// 設定全体を破棄すべき内容だった場合は [FunctionCallingConfigException] を投げる。
/// 個別の関数や項目に不正があった場合は、その要素のみを除外して解釈を続ける。
@visibleForTesting
FunctionCallingToolConfig parseFunctionCallingConfig(String rawJson) {
  final Object? decoded;
  try {
    decoded = jsonDecode(rawJson);
  } on FormatException catch (e) {
    throw FunctionCallingConfigException.malformed(message: 'JSON が不正です: $e');
  }

  if (decoded is! Map<String, dynamic>) {
    throw const FunctionCallingConfigException.malformed(
      message: '設定のルートがオブジェクトではありません。',
    );
  }

  final schemaVersion = decoded['schemaVersion'];
  if (schemaVersion is! int) {
    throw const FunctionCallingConfigException.malformed(
      message: 'schemaVersion が指定されていません。',
    );
  }

  if (schemaVersion > supportedFunctionCallingSchemaVersion) {
    throw FunctionCallingConfigException.unsupportedSchemaVersion(
      schemaVersion: schemaVersion,
    );
  }

  final rawFunctions = decoded['functions'];
  if (rawFunctions is! List) {
    throw const FunctionCallingConfigException.malformed(
      message: 'functions が指定されていません。',
    );
  }

  final toolInstruction = decoded['toolInstruction'];

  return FunctionCallingToolConfig(
    schemaVersion: schemaVersion,
    toolInstruction: toolInstruction is String ? toolInstruction : '',
    functions: _parseFunctions(rawFunctions),
  );
}

List<FunctionCallingFunction> _parseFunctions(List<dynamic> rawFunctions) {
  final functions = <FunctionCallingFunction>[];
  final names = <String>{};

  for (final rawFunction in rawFunctions) {
    final function = _parseFunction(rawFunction);
    if (function == null) {
      continue;
    }

    if (builtInFunctionNames.contains(function.name)) {
      _logger.warning(
        '組み込み関数と同名の関数が定義されているため除外します: ${function.name}',
      );
      continue;
    }

    if (!names.add(function.name)) {
      _logger.warning('関数名が重複しているため除外します: ${function.name}');
      continue;
    }

    functions.add(function);
  }

  return List.unmodifiable(functions);
}

/// 関数定義を解釈する
///
/// 解釈できない項目が含まれる場合や、無効化されている場合は `null` を返す。
/// 呼び出されても何も返せない関数をモデルに提示しないため、引数や項目一覧に
/// 不正があった場合は関数ごと除外する。
FunctionCallingFunction? _parseFunction(Object? rawFunction) {
  if (rawFunction is! Map<String, dynamic>) {
    _logger.warning('関数定義がオブジェクトではないため除外します: $rawFunction');
    return null;
  }

  final enabled = rawFunction['enabled'];
  if (enabled is bool && !enabled) {
    return null;
  }

  final name = _parseNonEmptyString(rawFunction['name']);
  if (name == null || !_functionNamePattern.hasMatch(name)) {
    _logger.warning('関数名が不正なため除外します: ${rawFunction['name']}');
    return null;
  }

  final description = _parseNonEmptyString(rawFunction['description']);
  if (description == null) {
    _logger.warning('関数の説明が指定されていないため除外します: $name');
    return null;
  }

  final handler = _parseHandler(rawFunction['handler']);
  if (handler == null) {
    _logger.warning(
      '未対応のハンドラーが指定されているため除外します: '
      '$name (handler: ${rawFunction['handler']})',
    );
    return null;
  }

  final parameters = _parseParameters(rawFunction['parameters']);
  if (parameters == null) {
    _logger.warning('引数定義が不正なため除外します: $name');
    return null;
  }

  final entries = _parseEntries(rawFunction['entries']);
  if (handler == FunctionCallingHandler.knowledgeLookup && entries.isEmpty) {
    _logger.warning('項目一覧が空のため除外します: $name');
    return null;
  }

  return FunctionCallingFunction(
    name: name,
    handler: handler,
    description: description,
    parameters: parameters,
    entries: entries,
  );
}

FunctionCallingHandler? _parseHandler(Object? rawHandler) {
  return FunctionCallingHandler.values.firstWhereOrNull(
    (handler) => handler.name == rawHandler,
  );
}

/// 引数定義のリストを解釈する
///
/// 1 つでも解釈できない引数が含まれる場合は `null` を返す。
List<FunctionCallingParameter>? _parseParameters(Object? rawParameters) {
  if (rawParameters == null) {
    return const [];
  }

  if (rawParameters is! List) {
    return null;
  }

  final parameters = <FunctionCallingParameter>[];
  final names = <String>{};

  for (final rawParameter in rawParameters) {
    if (rawParameter is! Map<String, dynamic>) {
      return null;
    }

    final name = _parseNonEmptyString(rawParameter['name']);
    final description = _parseNonEmptyString(rawParameter['description']);
    final type = _parseParameterType(rawParameter['type']);
    if (name == null || description == null || type == null) {
      return null;
    }

    if (!names.add(name)) {
      return null;
    }

    final isRequired = rawParameter['required'];
    final enumValues = _parseStringList(rawParameter['enumValues']);

    parameters.add(
      FunctionCallingParameter(
        name: name,
        type: type,
        description: description,
        isRequired: isRequired is bool && isRequired,
        // 列挙値による制限は文字列型の引数でのみ指定できる
        enumValues: type == FunctionCallingParameterType.string
            ? enumValues
            : const [],
      ),
    );
  }

  return List.unmodifiable(parameters);
}

FunctionCallingParameterType? _parseParameterType(Object? rawType) {
  return FunctionCallingParameterType.values.firstWhereOrNull(
    (type) => type.name == rawType,
  );
}

/// 項目一覧を解釈する
///
/// 解釈できない項目とトピックIDが重複した項目は除外する。
List<KnowledgeEntry> _parseEntries(Object? rawEntries) {
  if (rawEntries is! List) {
    return const [];
  }

  final entries = <KnowledgeEntry>[];
  final topics = <String>{};

  for (final rawEntry in rawEntries) {
    final entry = _parseEntry(rawEntry);
    if (entry == null) {
      continue;
    }

    if (!topics.add(entry.topic)) {
      _logger.warning('トピックIDが重複しているため除外します: ${entry.topic}');
      continue;
    }

    entries.add(entry);
  }

  return List.unmodifiable(entries);
}

KnowledgeEntry? _parseEntry(Object? rawEntry) {
  if (rawEntry is! Map<String, dynamic>) {
    _logger.warning('項目がオブジェクトではないため除外します: $rawEntry');
    return null;
  }

  final topic = _parseNonEmptyString(rawEntry['topic']);
  final title = _parseNonEmptyString(rawEntry['title']);
  final summary = _parseNonEmptyString(rawEntry['summary']);
  final facts = _parseStringList(rawEntry['facts']);
  if (topic == null || title == null || summary == null || facts.isEmpty) {
    _logger.warning('項目の必須内容が欠けているため除外します: ${rawEntry['topic']}');
    return null;
  }

  return KnowledgeEntry(
    topic: topic,
    title: title,
    summary: summary,
    facts: facts,
    keywords: _parseStringList(rawEntry['keywords']),
  );
}

String? _parseNonEmptyString(Object? rawValue) {
  if (rawValue is! String) {
    return null;
  }

  final trimmed = rawValue.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _parseStringList(Object? rawValue) {
  if (rawValue is! List) {
    return const [];
  }

  return List.unmodifiable(rawValue.whereType<String>());
}
