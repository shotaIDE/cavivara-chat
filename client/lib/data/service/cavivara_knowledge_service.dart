import 'package:firebase_ai/firebase_ai.dart';
import 'package:house_worker/data/model/function_calling_config.dart';
import 'package:house_worker/data/service/function_calling_config_service.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cavivara_knowledge_service.g.dart';

@riverpod
CavivaraKnowledgeBase cavivaraKnowledgeBase(Ref ref) {
  return CavivaraKnowledgeBase(
    config: ref.watch(functionCallingConfigProvider),
  );
}

/// カヴィヴァラが Function Calling で参照する知識ベース
///
/// モデルに提供する関数の宣言と、関数が返す項目一覧は [config] で決まる。
/// ただし、端末の状態を参照する組み込み関数は [config] に含まれず、
/// 宣言も実装もこのクラスに固定されている。
class CavivaraKnowledgeBase {
  CavivaraKnowledgeBase({required this.config})
    : _functionsByName = {
        for (final function in config.functions) function.name: function,
      };

  static final Logger _logger = Logger('CavivaraKnowledgeBase');

  final FunctionCallingToolConfig config;

  /// 関数名から関数定義を引くための対応表
  final Map<String, FunctionCallingFunction> _functionsByName;

  /// モデルに提供する関数の宣言
  ///
  /// 組み込み関数の宣言を必ず含むため、空になることはない。
  /// 組み込み関数と同名の関数は、実行時に組み込みの実装が使われるため宣言からも除く。
  late final List<Tool> tools = List.unmodifiable([
    Tool.functionDeclarations([
      _buildCurrentDateTimeFunctionDeclaration(),
      ...config.functions
          .where((function) => !builtInFunctionNames.contains(function.name))
          .map(_buildFunctionDeclaration),
    ]),
  ]);

  /// Function Calling の利用を促すため、システムプロンプトに追記する指示文
  String get toolInstruction => config.toolInstruction;

  /// 指定した文言が、結社の知識ベースに関連する内容かどうかを判定する。
  ///
  /// 自動選択モードでの初回メッセージに対し、結社マスターモードと
  /// 雑談マスターモードのどちらを使うか判断する材料として利用する。
  /// 「結社の知識に関係する発話か」のみを判定するため、どの関数の項目かは区別せず、
  /// 全関数の項目一覧を横断して判定する。
  bool hasRelevantKnowledge(String query) {
    final normalizedQuery = _normalizeQuery(query);
    if (normalizedQuery == null) {
      return false;
    }

    return config.functions.any(
      (function) =>
          function.entries.any((entry) => entry.matches(normalizedQuery)),
    );
  }

  Future<Map<String, dynamic>> execute({
    required String functionName,
    Map<String, dynamic> arguments = const <String, dynamic>{},
  }) async {
    // Remote Config が組み込み関数と同名の関数を定義していても組み込みの実装を使うため、
    // 組み込み関数の判定を先に行う
    if (functionName == currentDateTimeFunctionName) {
      return _getCurrentDateTime();
    }

    final function = _functionsByName[functionName];
    if (function == null) {
      _logger.warning('Unknown function call requested: $functionName');
      return {
        'found': false,
        'message': '未対応の関数が指定されました。',
        'requestedFunction': functionName,
        'availableFunctions': [
          ...builtInFunctionNames,
          ..._functionsByName.keys,
        ],
      };
    }

    switch (function.handler) {
      case FunctionCallingHandler.knowledgeLookup:
        return _getKnowledge(function: function, arguments: arguments);
    }
  }

  static Map<String, dynamic> _getKnowledge({
    required FunctionCallingFunction function,
    required Map<String, dynamic> arguments,
  }) {
    final entry = _resolveEntry(
      entries: function.entries,
      topic: arguments['topic'],
      query: arguments['query'],
    );

    if (entry == null) {
      _logger.info(
        'Knowledge topic could not be resolved from arguments: $arguments',
      );
      return {
        'found': false,
        'message': '該当するトピックが見つかりませんでした。',
        // 呼び出された関数が扱うトピックのみを提示する
        'availableTopics': function.entries
            .map((entry) => entry.topic)
            .toList(),
        if (arguments['topic'] != null) 'requestedTopic': arguments['topic'],
        if (arguments['query'] != null) 'query': arguments['query'],
      };
    }

    return {
      'found': true,
      'topic': entry.topic,
      'title': entry.title,
      'summary': entry.summary,
      'facts': List<String>.from(entry.facts),
      'keywords': List<String>.from(entry.keywords),
    };
  }

  static Map<String, dynamic> _getCurrentDateTime() {
    final current = DateTime.now();
    return {
      'dateTime': current.toString(),
      'epochMilliseconds': current.millisecondsSinceEpoch,
    };
  }

  static FunctionDeclaration _buildFunctionDeclaration(
    FunctionCallingFunction function,
  ) {
    return FunctionDeclaration(
      function.name,
      function.description,
      parameters: {
        for (final parameter in function.parameters)
          parameter.name: _buildParameterSchema(parameter),
      },
      optionalParameters: function.parameters
          .where((parameter) => !parameter.isRequired)
          .map((parameter) => parameter.name)
          .toList(),
    );
  }

  static Schema _buildParameterSchema(FunctionCallingParameter parameter) {
    switch (parameter.type) {
      case FunctionCallingParameterType.string:
        if (parameter.enumValues.isNotEmpty) {
          return Schema.enumString(
            enumValues: parameter.enumValues,
            description: parameter.description,
          );
        }
        return Schema.string(description: parameter.description);
      case FunctionCallingParameterType.integer:
        return Schema.integer(description: parameter.description);
      case FunctionCallingParameterType.number:
        return Schema.number(description: parameter.description);
      case FunctionCallingParameterType.boolean:
        return Schema.boolean(description: parameter.description);
      case FunctionCallingParameterType.stringArray:
        return Schema.array(
          items: Schema.string(),
          description: parameter.description,
        );
    }
  }

  static FunctionDeclaration _buildCurrentDateTimeFunctionDeclaration() {
    return FunctionDeclaration(
      currentDateTimeFunctionName,
      '現在の日時情報を取得します。',
      parameters: {},
    );
  }

  static KnowledgeEntry? _resolveEntry({
    required List<KnowledgeEntry> entries,
    Object? topic,
    Object? query,
  }) {
    final normalizedTopic = _normalizeTopic(entries: entries, rawTopic: topic);
    if (normalizedTopic != null) {
      return normalizedTopic;
    }

    final normalizedQuery = _normalizeQuery(query);
    if (normalizedQuery == null) {
      return null;
    }

    for (final entry in entries) {
      if (entry.matches(normalizedQuery)) {
        return entry;
      }
    }

    return null;
  }

  static KnowledgeEntry? _normalizeTopic({
    required List<KnowledgeEntry> entries,
    Object? rawTopic,
  }) {
    if (rawTopic is! String) {
      return null;
    }

    final normalized = rawTopic.trim().toLowerCase();
    for (final entry in entries) {
      if (entry.topic.toLowerCase() == normalized) {
        return entry;
      }
    }

    return null;
  }

  static String? _normalizeQuery(Object? rawQuery) {
    if (rawQuery is String) {
      final normalized = rawQuery.trim().toLowerCase();
      return normalized.isEmpty ? null : normalized;
    }
    return null;
  }
}
