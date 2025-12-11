import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/supporter_title.dart';

void main() {
  group('SupporterTitleLogic', () {
    group('fromTotalVP', () {
      test('VP=0で駆け出しヴィヴァサポーターになること', () {
        final title = SupporterTitleLogic.fromTotalVP(0);
        expect(title, equals(SupporterTitle.newbie));
      });

      test('VP=10で初心ヴィヴァサポーターになること', () {
        final title = SupporterTitleLogic.fromTotalVP(10);
        expect(title, equals(SupporterTitle.beginner));
      });

      test('VP=500以上で伝説のヴィヴァサポーターになること', () {
        final title = SupporterTitleLogic.fromTotalVP(500);
        expect(title, equals(SupporterTitle.legend));

        final title1000 = SupporterTitleLogic.fromTotalVP(1000);
        expect(title1000, equals(SupporterTitle.legend));
      });

      group('境界値テスト', () {
        test('VP=9で駆け出しヴィヴァサポーターになること', () {
          final title = SupporterTitleLogic.fromTotalVP(9);
          expect(title, equals(SupporterTitle.newbie));
        });

        test('VP=29で初心ヴィヴァサポーターになること', () {
          final title = SupporterTitleLogic.fromTotalVP(29);
          expect(title, equals(SupporterTitle.beginner));
        });

        test('VP=30で一人前ヴィヴァサポーターになること', () {
          final title = SupporterTitleLogic.fromTotalVP(30);
          expect(title, equals(SupporterTitle.intermediate));
        });

        test('VP=69で一人前ヴィヴァサポーターになること', () {
          final title = SupporterTitleLogic.fromTotalVP(69);
          expect(title, equals(SupporterTitle.intermediate));
        });

        test('VP=70でベテランヴィヴァサポーターになること', () {
          final title = SupporterTitleLogic.fromTotalVP(70);
          expect(title, equals(SupporterTitle.advanced));
        });

        test('VP=149でベテランヴィヴァサポーターになること', () {
          final title = SupporterTitleLogic.fromTotalVP(149);
          expect(title, equals(SupporterTitle.advanced));
        });

        test('VP=150で熟練ヴィヴァサポーターになること', () {
          final title = SupporterTitleLogic.fromTotalVP(150);
          expect(title, equals(SupporterTitle.expert));
        });

        test('VP=299で熟練ヴィヴァサポーターになること', () {
          final title = SupporterTitleLogic.fromTotalVP(299);
          expect(title, equals(SupporterTitle.expert));
        });

        test('VP=300で達人ヴィヴァサポーターになること', () {
          final title = SupporterTitleLogic.fromTotalVP(300);
          expect(title, equals(SupporterTitle.master));
        });

        test('VP=499で達人ヴィヴァサポーターになること', () {
          final title = SupporterTitleLogic.fromTotalVP(499);
          expect(title, equals(SupporterTitle.master));
        });
      });
    });

    group('nextTitle', () {
      test('駆け出しヴィヴァサポーターの次は初心ヴィヴァサポーターであること', () {
        final nextTitle = SupporterTitle.newbie.nextTitle;
        expect(nextTitle, equals(SupporterTitle.beginner));
      });

      test('達人ヴィヴァサポーターの次は伝説のヴィヴァサポーターであること', () {
        final nextTitle = SupporterTitle.master.nextTitle;
        expect(nextTitle, equals(SupporterTitle.legend));
      });

      test('伝説のヴィヴァサポーターの次はnullであること', () {
        final nextTitle = SupporterTitle.legend.nextTitle;
        expect(nextTitle, isNull);
      });
    });

    group('vpToNextTitle', () {
      test('VP=0の場合、次の称号まであと10VPであること', () {
        final title = SupporterTitleLogic.fromTotalVP(0);
        final vpToNext = title.vpToNextTitle(0);
        expect(vpToNext, equals(10));
      });

      test('VP=5の場合、次の称号まであと5VPであること', () {
        final title = SupporterTitleLogic.fromTotalVP(5);
        final vpToNext = title.vpToNextTitle(5);
        expect(vpToNext, equals(5));
      });

      test('VP=25の場合、次の称号まであと5VPであること', () {
        final title = SupporterTitleLogic.fromTotalVP(25);
        final vpToNext = title.vpToNextTitle(25);
        expect(vpToNext, equals(5));
      });

      test('VP=499の場合、次の称号まであと1VPであること', () {
        final title = SupporterTitleLogic.fromTotalVP(499);
        final vpToNext = title.vpToNextTitle(499);
        expect(vpToNext, equals(1));
      });

      test('VP=500の場合（最上位称号）、次の称号まで0VPであること', () {
        final title = SupporterTitleLogic.fromTotalVP(500);
        final vpToNext = title.vpToNextTitle(500);
        expect(vpToNext, equals(0));
      });

      test('VP=1000の場合（最上位称号）、次の称号まで0VPであること', () {
        final title = SupporterTitleLogic.fromTotalVP(1000);
        final vpToNext = title.vpToNextTitle(1000);
        expect(vpToNext, equals(0));
      });
    });
  });
}
