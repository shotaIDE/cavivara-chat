import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/service/cavivara_directory_service.dart';

void main() {
  group('CavivaraDirectoryService', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('cavivaraDirectoryProvider', () {
      test('デフォルトカヴィヴァラのみが取得できること', () {
        final profiles = container.read(cavivaraDirectoryProvider);

        expect(profiles, hasLength(1));

        // デフォルトカヴィヴァラの確認
        final defaultCavivara = profiles.firstWhere(
          (profile) => profile.id == 'cavivara_default',
        );
        expect(defaultCavivara.displayName, equals('カヴィヴァラ'));
        expect(defaultCavivara.title, contains('マスコットキャラクター'));
      });
    });

    group('cavivaraByIdProvider', () {
      test('有効なIDで正しいプロフィールが取得できること', () {
        const targetId = 'cavivara_default';
        final profile = container.read(cavivaraByIdProvider(targetId));

        expect(profile.id, equals(targetId));
        expect(profile.displayName, equals('カヴィヴァラ'));
      });

      test('存在しないIDでCavivaraNotFoundExceptionが投げられること', () {
        const invalidId = 'non_existent_id';

        expect(
          () => container.read(cavivaraByIdProvider(invalidId)),
          throwsA(
            predicate(
              (e) =>
                  e.toString().contains('ProviderException') &&
                  e.toString().contains('CavivaraNotFoundException'),
            ),
          ),
        );
      });

      test('CavivaraNotFoundExceptionに正しいIDが含まれること', () {
        const invalidId = 'non_existent_id';

        try {
          container.read(cavivaraByIdProvider(invalidId));
          fail('ProviderExceptionが投げられるべきです');
        } on Object catch (e) {
          expect(e.toString(), contains('ProviderException'));
          expect(e.toString(), contains('CavivaraNotFoundException'));
          expect(e.toString(), contains(invalidId));
        }
      });
    });
  });
}
