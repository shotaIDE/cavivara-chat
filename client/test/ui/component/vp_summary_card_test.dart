import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/vp_summary_card.dart';

void main() {
  group('VpSummaryCard', () {
    testWidgets('累計VPと次の称号までの進捗が表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VpSummaryCard(
              totalVP: 25,
              currentTitle: SupporterTitle.beginner,
              nextTitle: SupporterTitle.intermediate,
              vpToNext: 5,
              progress: 0.833, // 25/30
            ),
          ),
        ),
      );

      // 累計VPが表示されていること
      expect(find.text('25 VP'), findsOneWidget);

      // 次の称号までのVP数が表示されていること
      expect(find.text('次の称号まであと5VP'), findsOneWidget);

      // 進捗バーが表示されていること
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // 最高称号メッセージは表示されないこと
      expect(find.text('最高称号を獲得しました！'), findsNothing);
    });

    testWidgets('進捗バーのvalueとセマンティクスが正しく設定されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VpSummaryCard(
              totalVP: 50,
              currentTitle: SupporterTitle.intermediate,
              nextTitle: SupporterTitle.advanced,
              vpToNext: 20,
              progress: 0.714, // 50/70
            ),
          ),
        ),
      );

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      // 進捗バーのvalueがprogressと一致すること（進捗率の読み上げもこの値に依存）
      expect(progressIndicator.value, closeTo(0.714, 0.001));

      // 称号名は伏せ、進捗のラベルのみ読み上げること。
      // 進捗率は value から自動で読み上げられるため semanticsValue は指定しない
      // （progressBar ロールでは数値以外を指定するとセマンティクス更新時に失敗する）。
      expect(progressIndicator.semanticsLabel, '次の称号への進捗');
      expect(progressIndicator.semanticsValue, isNull);
    });

    testWidgets('最上位称号の場合、最高称号メッセージが表示され進捗バーは表示されないこと', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VpSummaryCard(
              totalVP: 500,
              currentTitle: SupporterTitle.legend,
              nextTitle: null, // 最上位称号
              vpToNext: 0,
              progress: 1,
            ),
          ),
        ),
      );

      // 累計VPは引き続き表示されること
      expect(find.text('500 VP'), findsOneWidget);

      // 最高称号獲得メッセージが表示されていること
      expect(find.text('最高称号を獲得しました！'), findsOneWidget);

      // 次の称号までのメッセージは表示されないこと
      expect(find.textContaining('次の称号まであと'), findsNothing);

      // 進捗バーは表示されないこと
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
