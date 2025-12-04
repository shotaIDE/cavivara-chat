import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/feature/settings/vp_progress_widget.dart';

void main() {
  group('VPProgressWidget', () {
    testWidgets('累計VP、現在の称号、進捗が表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VPProgressWidget(
              currentVP: 25,
              currentTitle: SupporterTitle.beginner,
              nextTitle: SupporterTitle.intermediate,
              vpToNext: 5,
              progress: 0.833, // 25/30
            ),
          ),
        ),
      );

      // 累計VPが表示されていること
      expect(find.text('累計: 25VP'), findsOneWidget);

      // 次の称号までのVP数が表示されていること
      expect(find.textContaining('あと5VP'), findsOneWidget);

      // 進捗バーが表示されていること
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('最上位称号の場合、特別なメッセージが表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VPProgressWidget(
              currentVP: 500,
              currentTitle: SupporterTitle.legend,
              nextTitle: null, // 最上位称号
              vpToNext: 0,
              progress: 1,
            ),
          ),
        ),
      );

      // 最高称号獲得メッセージが表示されていること
      expect(find.text('最高称号獲得！'), findsOneWidget);

      // 次の称号までのメッセージは表示されないこと
      expect(find.textContaining('あと'), findsNothing);
    });

    testWidgets('進捗バーの値が正しく設定されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VPProgressWidget(
              currentVP: 50,
              currentTitle: SupporterTitle.intermediate,
              nextTitle: SupporterTitle.advanced,
              vpToNext: 20,
              progress: 0.714, // 50/70
            ),
          ),
        ),
      );

      // 進捗バーのvalueを確認
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, closeTo(0.714, 0.001));
    });

    testWidgets('現在の称号バッジが表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VPProgressWidget(
              currentVP: 100,
              currentTitle: SupporterTitle.advanced,
              nextTitle: SupporterTitle.expert,
              vpToNext: 50,
              progress: 0.428,
            ),
          ),
        ),
      );

      // SupporterTitleBadgeが表示されていること
      expect(find.byType(Card), findsWidgets);
    });
  });
}
