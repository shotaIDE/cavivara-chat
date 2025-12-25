import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/ui/component/suggested_reply_button.dart';

void main() {
  group('SuggestedReplyButton', () {
    testWidgets('テキストが表示されること', (tester) async {
      const testText = 'テスト質問';
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestedReplyButton(
              text: testText,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // テキストが表示されていることを確認
      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('タップ時にコールバックが発火すること', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestedReplyButton(
              text: 'テスト質問',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // ボタンをタップ
      await tester.tap(find.byType(SuggestedReplyButton));
      await tester.pumpAndSettle();

      // コールバックが発火していることを確認
      expect(tapped, isTrue);
    });

    testWidgets('長いテキストが適切に表示されること', (tester) async {
      const longText = 'これは非常に長いテキストですが、適切に表示されるべきです';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestedReplyButton(
              text: longText,
              onTap: () {},
            ),
          ),
        ),
      );

      // テキストが表示されていることを確認
      expect(find.text(longText), findsOneWidget);
    });
  });
}
