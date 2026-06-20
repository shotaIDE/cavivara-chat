import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/ui/component/suggested_reply_list.dart';
import 'package:house_worker/ui/feature/home/home_presenter.dart';

void main() {
  group('SuggestedReplyList', () {
    testWidgets('空のサジェストリストの場合、何も表示されないこと', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SuggestedReplyList(
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
      final testSuggestions = ['質問1', '質問2', '質問3'];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SuggestedReplyList(
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
      container.read(suggestedRepliesProvider.notifier).save(testSuggestions);

      // 初回サジェストと同様の遅延表示のため、表示開始まで時間を進めてから
      // フェードインを完了させる。
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // すべてのサジェストが表示されていることを確認
      for (final suggestion in testSuggestions) {
        expect(find.text(suggestion), findsOneWidget);
      }
    });

    testWidgets('サジェストをタップするとコールバックが呼ばれること', (tester) async {
      final testSuggestions = ['質問1', '質問2', '質問3'];
      String? tappedText;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SuggestedReplyList(
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
      container.read(suggestedRepliesProvider.notifier).save(testSuggestions);

      // 初回サジェストと同様の遅延表示のため、表示開始まで時間を進めてから
      // フェードインを完了させる。
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // 2番目のサジェストをタップ
      await tester.tap(find.text('質問2'));
      await tester.pumpAndSettle();

      // コールバックが正しいテキストで呼ばれたことを確認
      expect(tappedText, equals('質問2'));
    });

    testWidgets('サジェストが表示され始めるタイミングで onSuggestionsVisible コールバックが呼ばれること',
        (tester) async {
      final testSuggestions = ['質問1', '質問2'];
      var visibleCallCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SuggestedReplyList(
                onSuggestionTap: (_) {},
                onSuggestionsVisible: () {
                  visibleCallCount++;
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
      container.read(suggestedRepliesProvider.notifier).save(testSuggestions);

      // 遅延前はコールバックが呼ばれていないことを確認
      await tester.pump();
      expect(visibleCallCount, equals(0));

      // 遅延後にコールバックが呼ばれることを確認
      await tester.pump(const Duration(seconds: 1));
      expect(visibleCallCount, equals(1));
    });

    testWidgets('横スクロールが可能であること', (tester) async {
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
      container.read(suggestedRepliesProvider.notifier).save(testSuggestions);

      // 初回サジェストと同様の遅延表示のため、表示開始まで時間を進めてから
      // フェードインを完了させる。
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // ListView が存在することを確認（横スクロール可能）
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
