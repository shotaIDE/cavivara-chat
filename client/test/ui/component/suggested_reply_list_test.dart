import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/ui/component/suggested_reply_list.dart';
import 'package:house_worker/ui/feature/home/home_presenter.dart';

void main() {
  group('SuggestedReplyList', () {
    testWidgets('空のサジェストリストの場合、何も表示されないこと', (tester) async {
      const cavivaraId = 'test_cavivara';
      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SuggestedReplyList(
                cavivaraId: cavivaraId,
                onSuggestionTap: (_) {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // SizedBox.shrink が表示されていることを確認（何も表示されない）
      expect(find.byType(SizedBox), findsOneWidget);
      expect(tapped, isFalse);
    });

    testWidgets('サジェストが表示されること', (tester) async {
      const cavivaraId = 'test_cavivara';
      final testSuggestions = ['質問1', '質問2', '質問3'];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SuggestedReplyList(
                cavivaraId: cavivaraId,
                onSuggestionTap: (_) {},
              ),
            ),
          ),
        ),
      );

      // プロバイダーにサジェストを設定
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SuggestedReplyList)),
      );
      container
          .read(suggestedRepliesProvider(cavivaraId).notifier)
          .save(testSuggestions);

      await tester.pumpAndSettle();

      // すべてのサジェストが表示されていることを確認
      for (final suggestion in testSuggestions) {
        expect(find.text(suggestion), findsOneWidget);
      }
    });

    testWidgets('サジェストをタップするとコールバックが呼ばれること', (tester) async {
      const cavivaraId = 'test_cavivara';
      final testSuggestions = ['質問1', '質問2', '質問3'];
      String? tappedText;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SuggestedReplyList(
                cavivaraId: cavivaraId,
                onSuggestionTap: (text) {
                  tappedText = text;
                },
              ),
            ),
          ),
        ),
      );

      // プロバイダーにサジェストを設定
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SuggestedReplyList)),
      );
      container
          .read(suggestedRepliesProvider(cavivaraId).notifier)
          .save(testSuggestions);

      await tester.pumpAndSettle();

      // 2番目のサジェストをタップ
      await tester.tap(find.text('質問2'));
      await tester.pumpAndSettle();

      // コールバックが正しいテキストで呼ばれたことを確認
      expect(tappedText, equals('質問2'));
    });

    testWidgets('横スクロールが可能であること', (tester) async {
      const cavivaraId = 'test_cavivara';
      final testSuggestions = [
        '非常に長い質問1',
        '非常に長い質問2',
        '非常に長い質問3',
        '非常に長い質問4',
        '非常に長い質問5',
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SuggestedReplyList(
                cavivaraId: cavivaraId,
                onSuggestionTap: (_) {},
              ),
            ),
          ),
        ),
      );

      // プロバイダーにサジェストを設定
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SuggestedReplyList)),
      );
      container
          .read(suggestedRepliesProvider(cavivaraId).notifier)
          .save(testSuggestions);

      await tester.pumpAndSettle();

      // SingleChildScrollView が存在することを確認
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
