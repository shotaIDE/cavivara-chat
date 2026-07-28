import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/function_calling_config.dart';
import 'package:house_worker/data/service/cavivara_knowledge_service.dart';
import 'package:house_worker/data/service/function_calling_config_service.dart';

void main() {
  group('CavivaraKnowledgeBase', () {
    /// モデルに提供される関数の名前を取得する
    List<String> functionNamesOf(List<Tool> tools) {
      final declarations =
          tools.first.toJson()['functionDeclarations']! as List<dynamic>;
      return declarations
          .map(
            (declaration) =>
                (declaration as Map<String, Object?>)['name']! as String,
          )
          .toList();
    }

    group('組み込みデフォルト設定', () {
      late CavivaraKnowledgeBase knowledgeBase;

      setUp(() {
        knowledgeBase = CavivaraKnowledgeBase(
          config: defaultFunctionCallingConfig,
        );
      });

      test('組み込み関数と設定の関数が1つのツールとして提供されること', () {
        final tools = knowledgeBase.tools;

        expect(tools.length, equals(1));
        expect(
          functionNamesOf(tools),
          containsAll(<String>[
            'getCurrentDateTime',
            'getPlectrumSocietyKnowledge',
          ]),
        );
      });

      test('トピックIDを指定すると給与制度の知識が返されること', () async {
        final result = await knowledgeBase.execute(
          functionName: 'getPlectrumSocietyKnowledge',
          arguments: const {'topic': 'salary_policy'},
        );

        expect(result['found'], isTrue);
        expect(result['topic'], 'salary_policy');
        final facts = result['facts'] as List<dynamic>;
        expect(facts, contains('結社の給料は0円です。'));
      });

      test('検索クエリから知識が推定されること', () async {
        final result = await knowledgeBase.execute(
          functionName: 'getPlectrumSocietyKnowledge',
          arguments: const {'query': '結社の給料はいくらですか？'},
        );

        expect(result['found'], isTrue);
        expect(result['topic'], 'salary_policy');
        final facts = result['facts'] as List<dynamic>;
        expect(facts, contains('結社の給料は0円です。'));
      });

      test('該当する知識がない場合は利用可能なトピックが返されること', () async {
        final result = await knowledgeBase.execute(
          functionName: 'getPlectrumSocietyKnowledge',
          arguments: const {'query': '未知の話題'},
        );

        expect(result['found'], isFalse);
        expect(result['availableTopics'], contains('salary_policy'));
      });

      test('未対応の関数が指定された場合は利用可能な関数が返されること', () async {
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
      });

      test('キーワードに一致する文言では関連知識ありと判定されること', () {
        expect(knowledgeBase.hasRelevantKnowledge('結社の給料はいくらですか？'), isTrue);
      });

      test('キーワードに一致しない文言では関連知識なしと判定されること', () {
        expect(knowledgeBase.hasRelevantKnowledge('今日の天気は？'), isFalse);
      });

      test('現在の日時情報が返されること', () async {
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
        expect(parsed.isBefore(end.add(const Duration(seconds: 5))), isTrue);

        final epochMilliseconds = result['epochMilliseconds'] as int;
        expect(parsed.millisecondsSinceEpoch, epochMilliseconds);
      });
    });

    group('データ駆動関数が0件の設定', () {
      late CavivaraKnowledgeBase knowledgeBase;

      setUp(() {
        knowledgeBase = CavivaraKnowledgeBase(
          config: const FunctionCallingToolConfig(schemaVersion: 1),
        );
      });

      test('組み込み関数の宣言のみが提供されること', () {
        expect(
          functionNamesOf(knowledgeBase.tools),
          equals(<String>[
            'getCurrentDateTime',
          ]),
        );
      });

      test('組み込み関数は実行できること', () async {
        final result = await knowledgeBase.execute(
          functionName: 'getCurrentDateTime',
        );

        expect(result['dateTime'], isA<String>());
      });

      test('関連知識なしと判定されること', () {
        expect(knowledgeBase.hasRelevantKnowledge('定期演奏会はいつ？'), isFalse);
      });
    });

    group('データ駆動関数が2つある設定', () {
      late CavivaraKnowledgeBase knowledgeBase;

      const eventEntry = KnowledgeEntry(
        topic: 'regular_concert_11',
        title: '第11回定期演奏会',
        summary: '第11回定期演奏会は2026年9月12日に開催予定。',
        facts: ['開催日: 2026年9月12日(土)。'],
        keywords: ['演奏会', '定期演奏会'],
      );
      const systemEntry = KnowledgeEntry(
        topic: 'salary_policy',
        title: '給与制度',
        summary: '結社の給料は0円。',
        facts: ['結社の給料は0円です。'],
        keywords: ['給料', '給与'],
      );

      setUp(() {
        knowledgeBase = CavivaraKnowledgeBase(
          config: const FunctionCallingToolConfig(
            schemaVersion: 1,
            functions: [
              FunctionCallingFunction(
                name: 'getEventKnowledge',
                handler: FunctionCallingHandler.knowledgeLookup,
                description: '演奏会・イベントの情報を取得します。',
                parameters: [
                  FunctionCallingParameter(
                    name: 'topic',
                    type: FunctionCallingParameterType.string,
                    description: 'トピックID。',
                  ),
                ],
                entries: [eventEntry],
              ),
              FunctionCallingFunction(
                name: 'getSystemKnowledge',
                handler: FunctionCallingHandler.knowledgeLookup,
                description: '制度の情報を取得します。',
                parameters: [
                  FunctionCallingParameter(
                    name: 'topic',
                    type: FunctionCallingParameterType.string,
                    description: 'トピックID。',
                  ),
                ],
                entries: [systemEntry],
              ),
            ],
          ),
        );
      });

      test('すべての関数の宣言が提供されること', () {
        expect(
          functionNamesOf(knowledgeBase.tools),
          equals(<String>[
            'getCurrentDateTime',
            'getEventKnowledge',
            'getSystemKnowledge',
          ]),
        );
      });

      test('各関数が自身の項目一覧のみを参照すること', () async {
        final result = await knowledgeBase.execute(
          functionName: 'getEventKnowledge',
          arguments: const {'topic': 'regular_concert_11'},
        );

        expect(result['found'], isTrue);
        expect(result['title'], '第11回定期演奏会');
      });

      test('他の関数のトピックIDを指定した場合は該当なしとなること', () async {
        final result = await knowledgeBase.execute(
          functionName: 'getEventKnowledge',
          arguments: const {'topic': 'salary_policy'},
        );

        expect(result['found'], isFalse);
        // 呼び出された関数が扱わないトピックは提示しない
        expect(
          result['availableTopics'],
          equals(<String>['regular_concert_11']),
        );
      });

      test('関連知識の判定は全関数の項目一覧を横断して行われること', () {
        expect(knowledgeBase.hasRelevantKnowledge('定期演奏会はいつ？'), isTrue);
        expect(knowledgeBase.hasRelevantKnowledge('給料はいくら？'), isTrue);
      });
    });

    group('組み込み関数と同名の関数が定義された設定', () {
      late CavivaraKnowledgeBase knowledgeBase;

      setUp(() {
        knowledgeBase = CavivaraKnowledgeBase(
          config: const FunctionCallingToolConfig(
            schemaVersion: 1,
            functions: [
              FunctionCallingFunction(
                name: 'getCurrentDateTime',
                handler: FunctionCallingHandler.knowledgeLookup,
                description: '偽の日時取得関数。',
                entries: [
                  KnowledgeEntry(
                    topic: 'fake',
                    title: '偽の日時',
                    summary: '偽の日時。',
                    facts: ['偽の日時です。'],
                    keywords: ['偽の日時'],
                  ),
                ],
              ),
            ],
          ),
        );
      });

      test('組み込みの実装が優先されること', () async {
        final result = await knowledgeBase.execute(
          functionName: 'getCurrentDateTime',
        );

        expect(result['dateTime'], isA<String>());
        expect(result['found'], isNull);
      });

      test('宣言が重複しないこと', () {
        expect(
          functionNamesOf(knowledgeBase.tools),
          equals(<String>['getCurrentDateTime']),
        );
      });

      test('利用可能な関数名が重複して提示されないこと', () async {
        final result = await knowledgeBase.execute(
          functionName: 'unknownFunction',
        );

        expect(
          result['availableFunctions'],
          equals(<String>['getCurrentDateTime']),
        );
      });

      test('提供されない関数の項目一覧は関連知識の判定に使われないこと', () {
        expect(knowledgeBase.hasRelevantKnowledge('偽の日時を教えて'), isFalse);
      });
    });
  });
}
