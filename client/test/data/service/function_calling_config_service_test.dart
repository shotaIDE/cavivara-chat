import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/function_calling_config.dart';
import 'package:house_worker/data/model/function_calling_config_exception.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:house_worker/data/service/function_calling_config_service.dart';
import 'package:house_worker/data/service/remote_config_service.dart';
import 'package:mocktail/mocktail.dart';

class MockErrorReportService extends Mock implements ErrorReportService {}

void main() {
  /// 正常な設定の JSON を組み立てる
  ///
  /// テストケースごとに変えたい部分のみを [functions] などで上書きする。
  String buildRawJson({
    Object? schemaVersion = 1,
    Object? toolInstruction = '関数を必ず呼び出すこと。',
    Object? functions,
  }) {
    return jsonEncode({
      'schemaVersion': ?schemaVersion,
      'toolInstruction': ?toolInstruction,
      'functions': ?functions,
    });
  }

  const validEntry = {
    'topic': 'salary_policy',
    'title': '給与制度',
    'summary': '結社の給料は0円。',
    'facts': ['結社の給料は0円です。'],
    'keywords': ['給料', '給与'],
  };

  const validFunction = {
    'name': 'getPlectrumSocietyKnowledge',
    'handler': 'knowledgeLookup',
    'description': 'プレクトラム結社の公式情報を取得します。',
    'parameters': [
      {'name': 'topic', 'type': 'string', 'description': 'トピックID。'},
    ],
    'entries': [validEntry],
  };

  group('parseFunctionCallingConfig', () {
    test('正常な JSON を解釈できること', () {
      final config = parseFunctionCallingConfig(
        buildRawJson(functions: [validFunction]),
      );

      expect(config.schemaVersion, equals(1));
      expect(config.toolInstruction, equals('関数を必ず呼び出すこと。'));
      expect(config.functions.length, equals(1));

      final function = config.functions.first;
      expect(function.name, equals('getPlectrumSocietyKnowledge'));
      expect(function.handler, equals(FunctionCallingHandler.knowledgeLookup));
      expect(function.entries.length, equals(1));
      expect(function.entries.first.topic, equals('salary_policy'));
    });

    test('引数の必須指定を解釈できること', () {
      final config = parseFunctionCallingConfig(
        buildRawJson(
          functions: [
            {
              ...validFunction,
              'parameters': [
                {
                  'name': 'topic',
                  'type': 'string',
                  'description': 'トピックID。',
                  'required': true,
                },
                {'name': 'query', 'type': 'string', 'description': '検索クエリ。'},
              ],
            },
          ],
        ),
      );

      final parameters = config.functions.first.parameters;
      expect(parameters.map((parameter) => parameter.isRequired), [
        true,
        false,
      ]);
    });

    test('列挙値の制限は文字列型の引数でのみ有効になること', () {
      final config = parseFunctionCallingConfig(
        buildRawJson(
          functions: [
            {
              ...validFunction,
              'parameters': [
                {
                  'name': 'topic',
                  'type': 'string',
                  'description': 'トピックID。',
                  'enumValues': ['salary_policy'],
                },
                {
                  'name': 'limit',
                  'type': 'integer',
                  'description': '件数。',
                  'enumValues': ['1'],
                },
              ],
            },
          ],
        ),
      );

      final parameters = config.functions.first.parameters;
      expect(parameters.first.enumValues, equals(['salary_policy']));
      expect(parameters.last.enumValues, isEmpty);
    });

    test('toolInstruction が未指定の場合は空文字となること', () {
      final config = parseFunctionCallingConfig(
        buildRawJson(toolInstruction: null, functions: [validFunction]),
      );

      expect(config.toolInstruction, isEmpty);
    });

    group('設定全体を破棄する場合', () {
      test('JSON が不正な場合は例外を投げること', () {
        expect(
          () => parseFunctionCallingConfig('{'),
          throwsA(isA<FunctionCallingConfigExceptionMalformed>()),
        );
      });

      test('ルートがオブジェクトではない場合は例外を投げること', () {
        expect(
          () => parseFunctionCallingConfig('[]'),
          throwsA(isA<FunctionCallingConfigExceptionMalformed>()),
        );
      });

      test('schemaVersion が欠落している場合は例外を投げること', () {
        expect(
          () => parseFunctionCallingConfig(
            buildRawJson(schemaVersion: null, functions: [validFunction]),
          ),
          throwsA(isA<FunctionCallingConfigExceptionMalformed>()),
        );
      });

      test('functions が欠落している場合は例外を投げること', () {
        expect(
          () => parseFunctionCallingConfig(buildRawJson()),
          throwsA(isA<FunctionCallingConfigExceptionMalformed>()),
        );
      });

      test('対応バージョンを超えている場合は専用の例外を投げること', () {
        expect(
          () => parseFunctionCallingConfig(
            buildRawJson(
              schemaVersion: supportedFunctionCallingSchemaVersion + 1,
              functions: [validFunction],
            ),
          ),
          throwsA(
            isA<FunctionCallingConfigExceptionUnsupportedSchemaVersion>(),
          ),
        );
      });
    });

    group('関数単位で除外する場合', () {
      /// 除外されずに残った関数の名前を取得する
      List<String> parsedFunctionNames(List<Object> functions) {
        final config = parseFunctionCallingConfig(
          buildRawJson(functions: functions),
        );
        return config.functions.map((function) => function.name).toList();
      }

      test('関数名が不正な関数が除外されること', () {
        expect(
          parsedFunctionNames([
            {...validFunction, 'name': '1_invalid_name'},
            validFunction,
          ]),
          equals(['getPlectrumSocietyKnowledge']),
        );
      });

      test('説明が欠けている関数が除外されること', () {
        final function = {...validFunction}..remove('description');

        expect(parsedFunctionNames([function]), isEmpty);
      });

      test('未対応のハンドラーが指定された関数が除外されること', () {
        expect(
          parsedFunctionNames([
            {...validFunction, 'handler': 'unknownHandler'},
          ]),
          isEmpty,
        );
      });

      test('未対応の型の引数を持つ関数が除外されること', () {
        expect(
          parsedFunctionNames([
            {
              ...validFunction,
              'parameters': [
                {'name': 'topic', 'type': 'object', 'description': 'トピック。'},
              ],
            },
          ]),
          isEmpty,
        );
      });

      test('無効化された関数が除外されること', () {
        expect(
          parsedFunctionNames([
            {...validFunction, 'enabled': false},
          ]),
          isEmpty,
        );
      });

      test('関数名が重複している場合は先に定義されたものが採用されること', () {
        final config = parseFunctionCallingConfig(
          buildRawJson(
            functions: [
              validFunction,
              {...validFunction, 'description': '後から定義された関数。'},
            ],
          ),
        );

        expect(config.functions.length, equals(1));
        expect(
          config.functions.first.description,
          equals('プレクトラム結社の公式情報を取得します。'),
        );
      });

      test('組み込み関数と同名の関数が除外されること', () {
        expect(
          parsedFunctionNames([
            {...validFunction, 'name': currentDateTimeFunctionName},
          ]),
          isEmpty,
        );
      });

      test('項目一覧が欠けている関数が除外されること', () {
        final function = {...validFunction}..remove('entries');

        expect(parsedFunctionNames([function]), isEmpty);
      });

      test('項目がすべて不正で項目一覧が空になった関数が除外されること', () {
        expect(
          parsedFunctionNames([
            {
              ...validFunction,
              'entries': [
                {'topic': 'salary_policy'},
              ],
            },
          ]),
          isEmpty,
        );
      });
    });

    group('項目単位で除外する場合', () {
      test('必須内容が欠けている項目のみが除外されること', () {
        final config = parseFunctionCallingConfig(
          buildRawJson(
            functions: [
              {
                ...validFunction,
                'entries': [
                  {'topic': 'invalid_entry', 'title': '不正な項目'},
                  validEntry,
                ],
              },
            ],
          ),
        );

        final entries = config.functions.first.entries;
        expect(entries.map((entry) => entry.topic), equals(['salary_policy']));
      });

      test('同一関数内でトピックIDが重複している場合は先に定義されたものが採用されること', () {
        final config = parseFunctionCallingConfig(
          buildRawJson(
            functions: [
              {
                ...validFunction,
                'entries': [
                  validEntry,
                  {...validEntry, 'title': '後から定義された給与制度'},
                ],
              },
            ],
          ),
        );

        final entries = config.functions.first.entries;
        expect(entries.length, equals(1));
        expect(entries.first.title, equals('給与制度'));
      });

      test('別の関数との間ではトピックIDの重複が許容されること', () {
        final config = parseFunctionCallingConfig(
          buildRawJson(
            functions: [
              validFunction,
              {...validFunction, 'name': 'getAnotherKnowledge'},
            ],
          ),
        );

        expect(
          config.functions.map((function) => function.entries.first.topic),
          equals(['salary_policy', 'salary_policy']),
        );
      });
    });
  });

  group('functionCallingConfigProvider', () {
    late MockErrorReportService mockErrorReportService;

    setUpAll(() {
      registerFallbackValue(StackTrace.empty);
    });

    setUp(() {
      mockErrorReportService = MockErrorReportService();
      when(
        () => mockErrorReportService.recordError(
          any<dynamic>(),
          any<StackTrace>(),
        ),
      ).thenAnswer((_) async {});
    });

    /// Remote Config の生値を差し替えたコンテナーを生成する
    ///
    /// 設定を解釈できなかった場合は Crashlytics へ報告するため、
    /// Firebase の初期化を必要としないようにエラー報告もモックに差し替える。
    ProviderContainer createContainer(String rawJson) {
      final container = ProviderContainer(
        overrides: [
          functionCallingConfigJsonProvider.overrideWithValue(rawJson),
          errorReportServiceProvider.overrideWithValue(mockErrorReportService),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('Remote Config に値がない場合は組み込みデフォルト設定が使われること', () {
      final container = createContainer('');

      expect(
        container.read(functionCallingConfigProvider),
        equals(defaultFunctionCallingConfig),
      );
    });

    test('Remote Config の値が不正な場合は組み込みデフォルト設定が使われること', () {
      final container = createContainer('{');

      expect(
        container.read(functionCallingConfigProvider),
        equals(defaultFunctionCallingConfig),
      );
    });

    test('対応バージョンを超えている場合は組み込みデフォルト設定が使われること', () {
      final container = createContainer(
        buildRawJson(
          schemaVersion: supportedFunctionCallingSchemaVersion + 1,
          functions: [validFunction],
        ),
      );

      expect(
        container.read(functionCallingConfigProvider),
        equals(defaultFunctionCallingConfig),
      );
    });

    test('Remote Config の値が正常な場合はその値が使われること', () {
      final container = createContainer(
        buildRawJson(functions: [validFunction]),
      );

      final config = container.read(functionCallingConfigProvider);
      expect(config.toolInstruction, equals('関数を必ず呼び出すこと。'));
      expect(
        config.functions.map((function) => function.name),
        equals(['getPlectrumSocietyKnowledge']),
      );
    });
  });
}
