import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/support_plan.dart';
import 'package:house_worker/ui/component/support_plan_extension.dart';

void main() {
  group('SupportPlanExtension', () {
    group('displayName', () {
      test('smallプランの表示名が"ちょっと応援"であること', () {
        expect(SupportPlan.small.displayName, equals('ちょっと応援'));
      });

      test('mediumプランの表示名が"しっかり応援"であること', () {
        expect(SupportPlan.medium.displayName, equals('しっかり応援'));
      });

      test('largeプランの表示名が"めっちゃ応援"であること', () {
        expect(SupportPlan.large.displayName, equals('めっちゃ応援'));
      });
    });

    group('icon', () {
      test('smallプランのアイコンがfavorite_borderであること', () {
        expect(SupportPlan.small.icon, equals(Icons.favorite_border));
      });

      test('mediumプランのアイコンがfavoriteであること', () {
        expect(SupportPlan.medium.icon, equals(Icons.favorite));
      });

      test('largeプランのアイコンがvolunteer_activismであること', () {
        expect(SupportPlan.large.icon, equals(Icons.volunteer_activism));
      });
    });

    group('vivaPoint', () {
      test('smallプランのVPが1であること', () {
        expect(SupportPlan.small.vivaPoint, equals(1));
      });

      test('mediumプランのVPが4であること', () {
        expect(SupportPlan.medium.vivaPoint, equals(4));
      });

      test('largeプランのVPが8であること', () {
        expect(SupportPlan.large.vivaPoint, equals(8));
      });
    });

    group('thankYouMessage', () {
      test('smallプランの感謝メッセージが"頑張って!"であること', () {
        expect(SupportPlan.small.thankYouMessage, equals('頑張って!'));
      });

      test('mediumプランの感謝メッセージが"いつもありがとう!"であること', () {
        expect(SupportPlan.medium.thankYouMessage, equals('いつもありがとう!'));
      });

      test('largeプランの感謝メッセージが"これからも応援するヴィヴァ!"であること', () {
        expect(SupportPlan.large.thankYouMessage, equals('これからも応援するヴィヴァ!'));
      });
    });

    group('productId', () {
      test('smallプランの商品IDが"small_support"であること', () {
        expect(SupportPlan.small.productId, equals('small_support'));
      });

      test('mediumプランの商品IDが"medium_support"であること', () {
        expect(SupportPlan.medium.productId, equals('medium_support'));
      });

      test('largeプランの商品IDが"large_support"であること', () {
        expect(SupportPlan.large.productId, equals('large_support'));
      });
    });
  });
}
