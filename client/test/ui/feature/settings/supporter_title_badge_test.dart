import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';
import 'package:house_worker/ui/feature/settings/supporter_title_badge.dart';

void main() {
  group('SupporterTitleBadge', () {
    testWidgets('称号アイコン、名前が表示されること', (tester) async {
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

      // アイコンが表示されていること
      expect(
        find.byIcon(SupporterTitle.beginner.icon),
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

    testWidgets('称号の色が反映されること', (tester) async {
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

      // アイコンの色を確認
      final iconWidget = tester.widget<Icon>(
        find.byIcon(title.icon),
      );
      expect(iconWidget.color, title.color);
    });
  });
}
