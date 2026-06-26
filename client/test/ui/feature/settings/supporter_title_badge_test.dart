import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';
import 'package:house_worker/ui/component/supporter_title_image.dart';
import 'package:house_worker/ui/feature/settings/supporter_title_badge.dart';

void main() {
  group('SupporterTitleBadge', () {
    testWidgets('称号画像、名前が表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SupporterTitleBadge(
              title: SupporterTitle.beginner,
            ),
          ),
        ),
      );

      // 称号名が表示されていること
      expect(
        find.text(SupporterTitle.beginner.displayName),
        findsOneWidget,
      );

      // 称号画像が表示されていること
      expect(
        find.byType(SupporterTitleImage),
        findsOneWidget,
      );
    });

    testWidgets('showDescription=trueの場合、説明文が表示されること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SupporterTitleBadge(
              title: SupporterTitle.beginner,
              showDescription: true,
            ),
          ),
        ),
      );

      // 説明文が表示されていること
      expect(
        find.text(SupporterTitle.beginner.description),
        findsOneWidget,
      );
    });

    testWidgets('showDescription=falseの場合、説明文が表示されないこと', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SupporterTitleBadge(
              title: SupporterTitle.beginner,
            ),
          ),
        ),
      );

      // 説明文が表示されていないこと
      expect(
        find.text(SupporterTitle.beginner.description),
        findsNothing,
      );
    });

    testWidgets('称号の色が称号名テキストに反映されること', (tester) async {
      const title = SupporterTitle.legend;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SupporterTitleBadge(
              title: title,
            ),
          ),
        ),
      );

      // 称号名テキストの色を確認
      final textWidget = tester.widget<Text>(
        find.text(title.displayName),
      );
      expect(textWidget.style?.color, title.color);
    });
  });
}
