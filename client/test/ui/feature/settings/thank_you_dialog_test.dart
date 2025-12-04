import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/support_plan_extension.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';
import 'package:house_worker/ui/feature/settings/thank_you_dialog.dart';

void main() {
  group('ThankYouDialog', () {
    testWidgets('感謝メッセージ、獲得VPが表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThankYouDialog(
              plan: SupportPlan.medium,
              earnedVP: 4,
              newTitle: null,
            ),
          ),
        ),
      );

      // 感謝メッセージが表示されていること
      expect(
        find.text(SupportPlan.medium.thankYouMessage),
        findsOneWidget,
      );

      // 獲得VPが表示されていること
      expect(find.textContaining('4 VP'), findsOneWidget);

      // 閉じるボタンが表示されていること
      expect(find.text('閉じる'), findsOneWidget);
    });

    testWidgets('称号昇格時に新称号が表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThankYouDialog(
              plan: SupportPlan.small,
              earnedVP: 1,
              newTitle: SupporterTitle.beginner,
            ),
          ),
        ),
      );

      // 「おめでとう！」メッセージが表示されていること
      expect(find.textContaining('おめでとう'), findsOneWidget);

      // 新しい称号名が表示されていること
      expect(
        find.textContaining(SupporterTitle.beginner.displayName),
        findsOneWidget,
      );
    });

    testWidgets('称号昇格なしの場合、おめでとうメッセージが表示されないこと', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThankYouDialog(
              plan: SupportPlan.large,
              earnedVP: 8,
              newTitle: null, // 称号昇格なし
            ),
          ),
        ),
      );

      // 「おめでとう！」メッセージが表示されていないこと
      expect(find.textContaining('おめでとう'), findsNothing);
    });

    testWidgets('閉じるボタンをタップするとダイアログが閉じること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => const ThankYouDialog(
                        plan: SupportPlan.small,
                        earnedVP: 1,
                        newTitle: null,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // ダイアログが表示されていることを確認
      expect(find.byType(ThankYouDialog), findsOneWidget);

      // 閉じるボタンをタップ
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      // ダイアログが閉じられていることを確認
      expect(find.byType(ThankYouDialog), findsNothing);
    });
  });
}
