import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';

void main() {
  group('SupporterTitleExtension', () {
    test('requiredVPが昇順であること', () {
      // すべての称号のrequiredVPを取得
      final requiredVPs = SupporterTitle.values
          .map((e) => e.requiredVP)
          .toList();

      // 昇順であることを確認
      for (var i = 0; i < requiredVPs.length - 1; i++) {
        expect(
          requiredVPs[i],
          lessThan(requiredVPs[i + 1]),
          reason:
              '${SupporterTitle.values[i].name}のrequiredVPは'
              '${SupporterTitle.values[i + 1].name}のrequiredVPより小さくなければならない',
        );
      }
    });

    test('displayNameがすべての称号に対して定義されていること', () {
      for (final title in SupporterTitle.values) {
        expect(title.displayName, isNotEmpty);
      }
    });

    test('descriptionがすべての称号に対して定義されていること', () {
      for (final title in SupporterTitle.values) {
        expect(title.description, isNotEmpty);
      }
    });

    test('iconがすべての称号に対して定義されていること', () {
      for (final title in SupporterTitle.values) {
        expect(title.icon, isNotNull);
      }
    });

    test('colorがすべての称号に対して定義されていること', () {
      for (final title in SupporterTitle.values) {
        expect(title.color, isNotNull);
      }
    });

    test('requiredVPが正しい値であること', () {
      expect(SupporterTitle.newbie.requiredVP, 0);
      expect(SupporterTitle.beginner.requiredVP, 10);
      expect(SupporterTitle.intermediate.requiredVP, 30);
      expect(SupporterTitle.advanced.requiredVP, 70);
      expect(SupporterTitle.expert.requiredVP, 150);
      expect(SupporterTitle.master.requiredVP, 300);
      expect(SupporterTitle.legend.requiredVP, 500);
    });
  });
}
