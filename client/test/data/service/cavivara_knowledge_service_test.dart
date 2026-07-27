import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/service/cavivara_knowledge_service.dart';

void main() {
  group('CavivaraKnowledgeBase', () {
    late CavivaraKnowledgeBase knowledgeBase;

    setUp(() {
      knowledgeBase = CavivaraKnowledgeBase();
    });

    test('exposes function declaration for plectrum society knowledge', () {
      final tools = knowledgeBase.tools;
      expect(tools, isNotEmpty);

      final tool = tools.first;
      expect(tool, isNotNull);
      // ツールが正しく構成されていることを確認
      expect(tools.length, equals(1));
    });

    test('returns salary policy knowledge when topic is specified', () async {
      final result = await knowledgeBase.execute(
        functionName: 'getPlectrumSocietyKnowledge',
        arguments: const {'topic': 'salary_policy'},
      );

      expect(result['found'], isTrue);
      expect(result['topic'], 'salary_policy');
      final facts = result['facts'] as List<dynamic>;
      expect(
        facts,
        contains('結社の給料は0円です。'),
      );
    });

    test('infers regular concert knowledge from query text', () async {
      final result = await knowledgeBase.execute(
        functionName: 'getPlectrumSocietyKnowledge',
        arguments: const {'query': '定期演奏会はいつ開催されるの？'},
      );

      expect(result['found'], isTrue);
      expect(result['topic'], 'regular_concert_11');
      final facts = result['facts'] as List<dynamic>;
      expect(
        facts,
        contains('開催日: 2026年9月12日(土)。'),
      );
    });

    test('returns fallback payload for unknown query', () async {
      final result = await knowledgeBase.execute(
        functionName: 'getPlectrumSocietyKnowledge',
        arguments: const {'query': '未知の話題'},
      );

      expect(result['found'], isFalse);
      expect(result['availableTopics'], contains('salary_policy'));
    });

    test(
      'returns available functions when unknown function is requested',
      () async {
        final result = await knowledgeBase.execute(
          functionName: 'unknownFunction',
        );

        expect(result['found'], isFalse);
        expect(result['requestedFunction'], 'unknownFunction');
        final availableFunctions = List<String>.from(
          result['availableFunctions'] as List<dynamic>,
        );
        expect(
          availableFunctions,
          containsAll(<String>[
            'getPlectrumSocietyKnowledge',
            'getCurrentDateTime',
          ]),
        );
      },
    );

    test(
      'returns true from hasRelevantKnowledge when query matches a keyword',
      () {
        expect(
          knowledgeBase.hasRelevantKnowledge('定期演奏会はいつ開催されるの？'),
          isTrue,
        );
      },
    );

    test(
      'returns false from hasRelevantKnowledge when query matches nothing',
      () {
        expect(
          knowledgeBase.hasRelevantKnowledge('今日の天気は？'),
          isFalse,
        );
      },
    );

    test('returns current date time information', () async {
      final start = DateTime.now().toUtc();

      final result = await knowledgeBase.execute(
        functionName: 'getCurrentDateTime',
      );

      final end = DateTime.now().toUtc();

      final dateTime = result['dateTime'] as String;
      final parsed = DateTime.parse(dateTime);
      expect(
        parsed.isAfter(start.subtract(const Duration(seconds: 5))),
        isTrue,
      );
      expect(
        parsed.isBefore(end.add(const Duration(seconds: 5))),
        isTrue,
      );

      final epochMilliseconds = result['epochMilliseconds'] as int;
      expect(parsed.millisecondsSinceEpoch, epochMilliseconds);
    });
  });
}
