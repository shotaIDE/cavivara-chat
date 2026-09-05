import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/ai_answer_caution.dart';
import 'package:house_worker/ui/component/ai_answer_caution_dialog.dart';
import 'package:house_worker/ui/component/ai_answer_caution_extension.dart';

void main() {
  Future<void> pumpAndOpenDialog(
    WidgetTester tester, {
    required AiAnswerCaution caution,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => AiAnswerCautionDialog.show(
                  context,
                  caution: caution,
                ),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('AiAnswerCautionDialog', () {
    testWidgets('渡された注意書きのセリフが引用されること', (tester) async {
      const caution = AiAnswerCaution.overwork;

      await pumpAndOpenDialog(tester, caution: caution);

      expect(find.text('”${caution.quote}”'), findsOneWidget);
    });

    testWidgets('閉じるを押すとダイアログが閉じること', (tester) async {
      await pumpAndOpenDialog(tester, caution: AiAnswerCaution.overwork);

      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      expect(find.byType(AiAnswerCautionDialog), findsNothing);
    });
  });
}
