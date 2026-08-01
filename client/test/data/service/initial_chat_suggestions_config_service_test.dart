import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/initial_chat_suggestions_config.dart';
import 'package:house_worker/data/model/initial_chat_suggestions_config_exception.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:house_worker/data/service/initial_chat_suggestions_config_service.dart';
import 'package:house_worker/data/service/remote_config_service.dart';
import 'package:mocktail/mocktail.dart';

class MockErrorReportService extends Mock implements ErrorReportService {}

void main() {
  /// 正常な設定の JSON を組み立てる
  ///
  /// テストケースごとに変えたい部分のみを [suggestions] などで上書きする。
  String buildRawJson({
    Object? schemaVersion = 1,
    Object? displayCount,
    Object? suggestions,
  }) {
    return jsonEncode({
      'schemaVersion': ?schemaVersion,
      'displayCount': ?displayCount,
      'suggestions': ?suggestions,
    });
  }

  const validSuggestion = {
    'icon': 'queueMusic',
    'label': 'マンドリンの練習方法を教えてヴィヴァ',
  };

  group('parseInitialChatSuggestionsConfig', () {
    test('正常な JSON を解釈できること', () {
      final config = parseInitialChatSuggestionsConfig(
        buildRawJson(displayCount: 5, suggestions: [validSuggestion]),
      );

      expect(config.schemaVersion, equals(1));
      expect(config.displayCount, equals(5));
      expect(config.suggestions.length, equals(1));

      final suggestion = config.suggestions.first;
      expect(suggestion.label, equals('マンドリンの練習方法を教えてヴィヴァ'));
      expect(suggestion.icon, equals(InitialChatSuggestionIcon.queueMusic));
    });

    test('displayCount が未指定の場合は既定値となること', () {
      final config = parseInitialChatSuggestionsConfig(
        buildRawJson(suggestions: [validSuggestion]),
      );

      expect(
        config.displayCount,
        equals(defaultInitialChatSuggestionDisplayCount),
      );
    });

    test('displayCount が不正な場合は既定値となること', () {
      for (final invalidDisplayCount in <Object>[0, -1, '3', 1.5]) {
        final config = parseInitialChatSuggestionsConfig(
          buildRawJson(
            displayCount: invalidDisplayCount,
            suggestions: [validSuggestion],
          ),
        );

        expect(
          config.displayCount,
          equals(defaultInitialChatSuggestionDisplayCount),
          reason: 'displayCount: $invalidDisplayCount',
        );
      }
    });

    test('サジェストが空のリストの場合は空のまま解釈されること', () {
      final config = parseInitialChatSuggestionsConfig(
        buildRawJson(suggestions: <Object>[]),
      );

      expect(config.suggestions, isEmpty);
    });

    group('設定全体を破棄する場合', () {
      test('JSON が不正な場合は例外を投げること', () {
        expect(
          () => parseInitialChatSuggestionsConfig('{'),
          throwsA(isA<InitialChatSuggestionsConfigExceptionMalformed>()),
        );
      });

      test('ルートがオブジェクトではない場合は例外を投げること', () {
        expect(
          () => parseInitialChatSuggestionsConfig('[]'),
          throwsA(isA<InitialChatSuggestionsConfigExceptionMalformed>()),
        );
      });

      test('schemaVersion が欠落している場合は例外を投げること', () {
        expect(
          () => parseInitialChatSuggestionsConfig(
            buildRawJson(schemaVersion: null, suggestions: [validSuggestion]),
          ),
          throwsA(isA<InitialChatSuggestionsConfigExceptionMalformed>()),
        );
      });

      test('suggestions が欠落している場合は例外を投げること', () {
        expect(
          () => parseInitialChatSuggestionsConfig(buildRawJson()),
          throwsA(isA<InitialChatSuggestionsConfigExceptionMalformed>()),
        );
      });

      test('対応バージョンを超えている場合は専用の例外を投げること', () {
        expect(
          () => parseInitialChatSuggestionsConfig(
            buildRawJson(
              schemaVersion: supportedInitialChatSuggestionsSchemaVersion + 1,
              suggestions: [validSuggestion],
            ),
          ),
          throwsA(
            isA<
              InitialChatSuggestionsConfigExceptionUnsupportedSchemaVersion
            >(),
          ),
        );
      });
    });

    group('サジェスト単位で除外する場合', () {
      /// 除外されずに残ったサジェストの文言を取得する
      List<String> parsedLabels(List<Object> suggestions) {
        final config = parseInitialChatSuggestionsConfig(
          buildRawJson(suggestions: suggestions),
        );
        return config.suggestions
            .map((suggestion) => suggestion.label)
            .toList();
      }

      test('文言が欠けているサジェストのみが除外されること', () {
        final suggestion = {...validSuggestion}..remove('label');

        expect(
          parsedLabels([suggestion, validSuggestion]),
          equals(['マンドリンの練習方法を教えてヴィヴァ']),
        );
      });

      test('文言が空白のみのサジェストが除外されること', () {
        expect(
          parsedLabels([
            {...validSuggestion, 'label': '   '},
          ]),
          isEmpty,
        );
      });

      test('オブジェクトではないサジェストのみが除外されること', () {
        expect(
          parsedLabels(['マンドリンの練習方法を教えてヴィヴァ', validSuggestion]),
          equals(['マンドリンの練習方法を教えてヴィヴァ']),
        );
      });

      test('無効化されたサジェストが除外されること', () {
        expect(
          parsedLabels([
            {...validSuggestion, 'enabled': false},
          ]),
          isEmpty,
        );
      });

      test('文言が重複している場合は先に定義されたものが採用されること', () {
        final config = parseInitialChatSuggestionsConfig(
          buildRawJson(
            suggestions: [
              validSuggestion,
              {...validSuggestion, 'icon': 'book'},
            ],
          ),
        );

        expect(config.suggestions.length, equals(1));
        expect(
          config.suggestions.first.icon,
          equals(InitialChatSuggestionIcon.queueMusic),
        );
      });
    });

    group('アイコンの解釈', () {
      /// 解釈されたアイコンを取得する
      InitialChatSuggestionIcon parsedIcon(Object? icon) {
        final config = parseInitialChatSuggestionsConfig(
          buildRawJson(
            suggestions: [
              {'label': 'マンドリンの練習方法を教えてヴィヴァ', 'icon': ?icon},
            ],
          ),
        );
        return config.suggestions.first.icon;
      }

      test('アイコンが未指定の場合は既定のアイコンとなること', () {
        expect(parsedIcon(null), equals(InitialChatSuggestionIcon.chat));
      });

      test('未対応のアイコンが指定された場合も既定のアイコンでサジェストが残ること', () {
        expect(
          parsedIcon('unknownIcon'),
          equals(InitialChatSuggestionIcon.chat),
        );
      });
    });
  });

  group('initialChatSuggestionsConfigProvider', () {
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
          initialChatSuggestionsConfigJsonProvider.overrideWithValue(rawJson),
          errorReportServiceProvider.overrideWithValue(mockErrorReportService),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('Remote Config に値がない場合は組み込みデフォルト設定が使われること', () {
      final container = createContainer('');

      expect(
        container.read(initialChatSuggestionsConfigProvider),
        equals(defaultInitialChatSuggestionsConfig),
      );
    });

    test('Remote Config の値が不正な場合は組み込みデフォルト設定が使われること', () {
      final container = createContainer('{');

      expect(
        container.read(initialChatSuggestionsConfigProvider),
        equals(defaultInitialChatSuggestionsConfig),
      );
      verify(
        () => mockErrorReportService.recordError(
          any<dynamic>(),
          any<StackTrace>(),
        ),
      ).called(1);
    });

    test('対応バージョンを超えている場合は組み込みデフォルト設定が使われ、報告されないこと', () {
      final container = createContainer(
        buildRawJson(
          schemaVersion: supportedInitialChatSuggestionsSchemaVersion + 1,
          suggestions: [validSuggestion],
        ),
      );

      expect(
        container.read(initialChatSuggestionsConfigProvider),
        equals(defaultInitialChatSuggestionsConfig),
      );
      verifyNever(
        () => mockErrorReportService.recordError(
          any<dynamic>(),
          any<StackTrace>(),
        ),
      );
    });

    test('Remote Config の値が正常な場合はその値が使われること', () {
      final container = createContainer(
        buildRawJson(displayCount: 2, suggestions: [validSuggestion]),
      );

      final config = container.read(initialChatSuggestionsConfigProvider);
      expect(config.displayCount, equals(2));
      expect(
        config.suggestions.map((suggestion) => suggestion.label),
        equals(['マンドリンの練習方法を教えてヴィヴァ']),
      );
    });
  });
}
