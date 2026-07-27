// cspell:ignore hitomi

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final cavivaraKnowledgeBaseProvider = Provider<CavivaraKnowledgeBase>((ref) {
  return CavivaraKnowledgeBase();
});

class CavivaraKnowledgeBase {
  CavivaraKnowledgeBase();

  static final Logger _logger = Logger('CavivaraKnowledgeBase');

  static const String _knowledgeFunctionName = 'getPlectrumSocietyKnowledge';
  static const String _currentDateTimeFunctionName = 'getCurrentDateTime';

  static const Map<String, _KnowledgeEntry> _entries = {
    'salary_policy': _KnowledgeEntry(
      topic: 'salary_policy',
      title: '給与制度',
      summary: '結社の給料は0円。毎年5%のベースアップが行われているが、元々0円のため昇給額も0円。',
      details: [
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
    'regular_concert_11': _KnowledgeEntry(
      topic: 'regular_concert_11',
      title: '第11回定期演奏会',
      summary: 'プレクトラム結社の第11回定期演奏会は2026年9月12日(土)、メニコンANNEX HITOMIホールで開催予定。',
      details: [
        'イベント名: プレクトラム結社 第11回定期演奏会。',
        '開催日: 2026年9月12日(土)。',
        '会場: メニコンANNEX HITOMIホール。',
      ],
      keywords: [
        '演奏会',
        '定期演奏会',
        '第11回',
        '11回',
        '2026年9月12日',
        '2026/9/12',
        'メニコン',
        'annex',
        'hitomi',
        'ホール',
      ],
    ),
  };

  static final List<Tool> _knowledgeTools = List.unmodifiable([
    Tool.functionDeclarations([
      _buildKnowledgeFunctionDeclaration(),
      _buildCurrentDateTimeFunctionDeclaration(),
    ]),
  ]);

  List<Tool> get tools => _knowledgeTools;

  /// 指定した文言が、結社の知識ベースに関連する内容かどうかを判定する。
  ///
  /// 自動選択モードでの初回メッセージに対し、結社マスターモードと
  /// 雑談マスターモードのどちらを使うか判断する材料として利用する。
  bool hasRelevantKnowledge(String query) {
    final normalizedQuery = _normalizeQuery(query);
    if (normalizedQuery == null) {
      return false;
    }

    return _entries.values.any((entry) => entry.matches(normalizedQuery));
  }

  Future<Map<String, dynamic>> execute({
    required String functionName,
    Map<String, dynamic> arguments = const <String, dynamic>{},
  }) async {
    switch (functionName) {
      case _knowledgeFunctionName:
        return _getKnowledge(arguments);
      case _currentDateTimeFunctionName:
        return _getCurrentDateTime();
      default:
        _logger.warning('Unknown function call requested: $functionName');
        return {
          'found': false,
          'message': '未対応の関数が指定されました。',
          'requestedFunction': functionName,
          'availableFunctions': const [
            _knowledgeFunctionName,
            _currentDateTimeFunctionName,
          ],
        };
    }
  }

  static Map<String, dynamic> _getKnowledge(Map<String, dynamic> arguments) {
    final resolvedTopic = _resolveTopic(
      topic: arguments['topic'],
      query: arguments['query'],
    );

    if (resolvedTopic == null) {
      _logger.info(
        'Knowledge topic could not be resolved from arguments: $arguments',
      );
      return {
        'found': false,
        'message': '該当するトピックが見つかりませんでした。',
        'availableTopics': _entries.keys.toList(),
        if (arguments['topic'] != null) 'requestedTopic': arguments['topic'],
        if (arguments['query'] != null) 'query': arguments['query'],
      };
    }

    final entry = _entries[resolvedTopic]!;

    return {
      'found': true,
      'topic': entry.topic,
      'title': entry.title,
      'summary': entry.summary,
      'facts': List<String>.from(entry.details),
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

  static FunctionDeclaration _buildKnowledgeFunctionDeclaration() {
    return FunctionDeclaration(
      _knowledgeFunctionName,
      'プレクトラム結社に関する社内公式知識を取得します。',
      parameters: {
        'topic': Schema.string(
          description: '取得したいトピックID。',
        ),
        'query': Schema.string(
          description: '自然言語で記述された検索クエリ。例: "給料は？"',
        ),
      },
    );
  }

  static FunctionDeclaration _buildCurrentDateTimeFunctionDeclaration() {
    return FunctionDeclaration(
      _currentDateTimeFunctionName,
      '現在の日時情報を取得します。',
      parameters: {},
    );
  }

  static String? _resolveTopic({
    Object? topic,
    Object? query,
  }) {
    final normalizedTopic = _normalizeTopic(topic);
    if (normalizedTopic != null) {
      return normalizedTopic;
    }

    final normalizedQuery = _normalizeQuery(query);
    if (normalizedQuery == null) {
      return null;
    }

    for (final entry in _entries.entries) {
      if (entry.value.matches(normalizedQuery)) {
        return entry.key;
      }
    }

    return null;
  }

  static String? _normalizeTopic(Object? rawTopic) {
    if (rawTopic is String) {
      final normalized = rawTopic.trim().toLowerCase();
      if (_entries.containsKey(normalized)) {
        return normalized;
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

class _KnowledgeEntry {
  const _KnowledgeEntry({
    required this.topic,
    required this.title,
    required this.summary,
    required this.details,
    required this.keywords,
  });

  final String topic;
  final String title;
  final String summary;
  final List<String> details;
  final List<String> keywords;

  List<String> get _normalizedKeywords =>
      keywords.map((keyword) => keyword.toLowerCase()).toList();

  bool matches(String query) {
    final normalizedQuery = query.toLowerCase();
    return _normalizedKeywords.any(normalizedQuery.contains);
  }
}
