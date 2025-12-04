import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/ui/component/support_plan_extension.dart';
import 'package:house_worker/ui/feature/settings/support_plan_card.dart';

void main() {
  group('SupportPlanCard', () {
    testWidgets('プラン名、アイコン、獲得VPが表示されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupportPlanCard(
              plan: SupportPlan.medium,
              priceString: '¥500',
              onTap: () {},
            ),
          ),
        ),
      );

      // プラン名が表示されていること
      expect(find.text(SupportPlan.medium.displayName), findsOneWidget);

      // アイコンが表示されていること
      expect(find.byIcon(SupportPlan.medium.icon), findsOneWidget);

      // 獲得VPが表示されていること
      expect(
        find.textContaining('${SupportPlan.medium.vivaPoint}VP'),
        findsOneWidget,
      );

      // 価格が表示されていること
      expect(find.text('¥500'), findsOneWidget);
    });

    testWidgets('タップイベントが発火すること', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupportPlanCard(
              plan: SupportPlan.small,
              priceString: '¥120',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // タップ前はfalse
      expect(tapped, false);

      // カードをタップ
      await tester.tap(find.byType(Card));
      await tester.pump();

      // タップ後はtrue
      expect(tapped, true);
    });

    testWidgets('価格が未取得の場合、プレースホルダーが表示されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupportPlanCard(
              plan: SupportPlan.large,
              priceString: null, // 価格未取得
              onTap: () {},
            ),
          ),
        ),
      );

      // プレースホルダーが表示されていること
      expect(find.text('---'), findsOneWidget);
    });

    testWidgets('すべてのプランが正しく表示されること', (tester) async {
      for (final plan in SupportPlan.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SupportPlanCard(
                plan: plan,
                priceString: '¥100',
                onTap: () {},
              ),
            ),
          ),
        );

        // プラン名が表示されていること
        expect(find.text(plan.displayName), findsOneWidget);

        // アイコンが表示されていること
        expect(find.byIcon(plan.icon), findsOneWidget);

        // 獲得VPが表示されていること
        expect(find.textContaining('${plan.vivaPoint}VP'), findsOneWidget);
      }
    });
  });
}
