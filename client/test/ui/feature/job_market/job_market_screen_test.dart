import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/ui/feature/job_market/job_market_screen.dart';

void main() {
  group('JobMarketScreen', () {
    testWidgets('displays job market title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JobMarketScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // タイトルが表示されることを確認
      expect(find.text('転職市場'), findsOneWidget);
    });

    testWidgets('can be created without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JobMarketScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ウィジェットが正常に作成されることを確認
      expect(find.byType(JobMarketScreen), findsOneWidget);
    });

    testWidgets('displays cavivara profiles', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: JobMarketScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // カヴィヴァラの名前が表示されることを確認
      expect(find.text('カヴィヴァラ'), findsOneWidget);
      expect(find.text('カヴィヴァラ・マスコット'), findsOneWidget);
    });
  });
}
