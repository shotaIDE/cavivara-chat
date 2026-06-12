import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/ui/component/animated_cavivara.dart';

void main() {
  group('AnimatedCavivara', () {
    testWidgets('ビルドできること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: AnimatedCavivara(),
              ),
            ),
          ),
        ),
      );

      // ウィジェットと描画用の CustomPaint が生成されていることを確認
      expect(find.byType(AnimatedCavivara), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AnimatedCavivara),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ウィンクアニメーションを含めて一定時間 pump しても例外が出ないこと', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: AnimatedCavivara(),
              ),
            ),
          ),
        ),
      );

      // 初回ウィンクの待機時間 -> アニメーション再生 -> 次のウィンク待機まで進める。
      // 繰り返しタイマーを持つため pumpAndSettle は使わず、明示的に時間を進める。
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets('strokeColor を指定してもビルドできること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: AnimatedCavivara(strokeColor: Colors.black),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCavivara), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fillColor を指定してもビルドできること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: AnimatedCavivara(fillColor: Colors.grey),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCavivara), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
