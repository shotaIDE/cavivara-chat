import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/chat_bubble_design.dart';
import 'package:house_worker/ui/component/cat_fur_bubble_painter.dart';
import 'package:house_worker/ui/component/chat_bubble_design_extension.dart';

void main() {
  group('buildBubble', () {
    testWidgets(
      'corporateStandard design creates bubble with uniform small radius',
      (WidgetTester tester) async {
        const design = ChatBubbleDesign.corporateStandard;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return design.buildBubble(
                    context: context,
                    backgroundColor: Colors.blue,
                    child: const Text('User message'),
                  );
                },
              ),
            ),
          ),
        );
        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(8));
      },
    );

    testWidgets(
      'catFur design creates bubble with CustomPaint using CatFurBubblePainter',
      (WidgetTester tester) async {
        const design = ChatBubbleDesign.catFur;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return design.buildBubble(
                    context: context,
                    backgroundColor: Colors.blue,
                    child: const Text('AI message'),
                    seed: 42,
                  );
                },
              ),
            ),
          ),
        );

        final catFurPaintFinder = find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is CatFurBubblePainter,
        );
        expect(catFurPaintFinder, findsOneWidget);

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.constraints, isNotNull);
      },
    );

    testWidgets(
      'catFur design propagates Brightness.light to CatFurBubblePainter '
      'under default (light) MaterialApp theme',
      (WidgetTester tester) async {
        const design = ChatBubbleDesign.catFur;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return design.buildBubble(
                    context: context,
                    backgroundColor: Colors.blue,
                    child: const Text('AI message'),
                  );
                },
              ),
            ),
          ),
        );

        final painter = _findCatFurPainter(tester);
        expect(painter.brightness, Brightness.light);
      },
    );

    testWidgets(
      'catFur design propagates Brightness.dark to CatFurBubblePainter '
      'under dark MaterialApp theme',
      (WidgetTester tester) async {
        const design = ChatBubbleDesign.catFur;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return design.buildBubble(
                    context: context,
                    backgroundColor: Colors.blue,
                    child: const Text('AI message'),
                  );
                },
              ),
            ),
          ),
        );

        final painter = _findCatFurPainter(tester);
        expect(painter.brightness, Brightness.dark);
      },
    );
  });

  group('displayName', () {
    test('corporateStandard returns correct Japanese name', () {
      const design = ChatBubbleDesign.corporateStandard;
      expect(design.displayName, '社内標準様式');
    });

    test('catFur returns correct Japanese name', () {
      const design = ChatBubbleDesign.catFur;
      expect(design.displayName, '猫毛様式');
    });
  });

  group('shouldWithPointer', () {
    test('corporateStandard has a pointer', () {
      expect(ChatBubbleDesign.corporateStandard.shouldWithPointer, isTrue);
    });

    test('catFur has no pointer', () {
      expect(ChatBubbleDesign.catFur.shouldWithPointer, isFalse);
    });
  });

  group('CatFurBubblePainter.recommendedForegroundColor', () {
    test('returns grey.shade800 for light brightness', () {
      expect(
        CatFurBubblePainter.recommendedForegroundColor(Brightness.light),
        Colors.grey.shade800,
      );
    });

    test('returns grey.shade100 for dark brightness', () {
      expect(
        CatFurBubblePainter.recommendedForegroundColor(Brightness.dark),
        Colors.grey.shade100,
      );
    });
  });
}

/// テスト対象ウィジェットツリーから [CatFurBubblePainter] を 1 つ取り出す。
CatFurBubblePainter _findCatFurPainter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint && widget.painter is CatFurBubblePainter,
    ),
  );
  return paint.painter! as CatFurBubblePainter;
}
