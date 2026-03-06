import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/ui/feature/resume/resume_screen.dart';

void main() {
  group('ResumeScreen', () {
    const testCavivaraId = 'cavivara_default';

    testWidgets(
      'displays resume content for given cavivara',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: ResumeScreen(cavivaraId: testCavivaraId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // AppBarにカヴィヴァラの名前が表示されることを確認
        expect(find.text('カヴィヴァラ'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('can be created without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResumeScreen(cavivaraId: testCavivaraId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ウィジェットが正常に作成されることを確認
      expect(find.byType(ResumeScreen), findsOneWidget);
    });
  });
}
