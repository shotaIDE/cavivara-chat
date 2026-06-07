import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/service/cavivara_profile_service.dart';

void main() {
  group('CavivaraProfileService', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('cavivaraProfileProvider', () {
      test('カヴィヴァラのプロフィールが取得できること', () {
        final profile = container.read(cavivaraProfileProvider);

        expect(profile.displayName, equals('カヴィヴァラ'));
        expect(profile.title, contains('マスコットキャラクター'));
        expect(profile.aiPrompt, isNotEmpty);
        expect(profile.tags, isNotEmpty);
      });
    });
  });
}
