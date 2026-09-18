import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/app_badge.dart';
import 'package:house_worker/data/model/earned_badge.dart';
import 'package:house_worker/data/repository/earned_badges_repository.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:house_worker/data/service/remote_config_service.dart';
import 'package:house_worker/ui/feature/code_scanner/code_scanner_presenter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('CodeScannerPresenter', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      // Remote Config は Firebase の初期化を必要とするため、単体テストでは
      // 値を上書きする。ここでは称号を獲得できる状態とし、獲得できない場合は
      // テストケース側で別のコンテナーを用意する。
      container = ProviderContainer(
        overrides: [
          enablePlectrumConcertVol11BadgeProvider.overrideWith((_) => true),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('対象外のURLではバッジもVPも付与されないこと', () async {
      final result = await container
          .read(codeScannerPresenterProvider.notifier)
          .handleScannedValue('https://example.com/other');

      expect(result, CodeScanResult.notMatched);

      final badges = await container.read(
        earnedBadgesRepositoryProvider.future,
      );
      final totalVP = await container.read(vivaPointRepositoryProvider.future);

      expect(badges, isEmpty);
      expect(totalVP, 0);
    });

    test('対象のURLでバッジとVPが付与されること', () async {
      final result = await container
          .read(codeScannerPresenterProvider.notifier)
          .handleScannedValue(plectrumConcertVol11CodeUrl);

      expect(result, CodeScanResult.earnedNewBadge);

      final badges = await container.read(
        earnedBadgesRepositoryProvider.future,
      );
      final totalVP = await container.read(vivaPointRepositoryProvider.future);

      expect(badges.length, 1);
      expect(badges.first.badge, AppBadge.plectrumConcertVol11);
      expect(totalVP, codeScanEventBonusVP);
    });

    test('すでに獲得済みの場合はVPが重複付与されないこと', () async {
      // 事前に同じバッジを獲得済みにしておく
      await container
          .read(earnedBadgesRepositoryProvider.notifier)
          .add(
            EarnedBadge(
              badge: AppBadge.plectrumConcertVol11,
              earnedAt: DateTime(2026, 6, 27, 12),
            ),
          );

      final result = await container
          .read(codeScannerPresenterProvider.notifier)
          .handleScannedValue(plectrumConcertVol11CodeUrl);

      expect(result, CodeScanResult.alreadyEarned);

      final badges = await container.read(
        earnedBadgesRepositoryProvider.future,
      );
      final totalVP = await container.read(vivaPointRepositoryProvider.future);

      // バッジは増えず、VPも付与されない
      expect(badges.length, 1);
      expect(totalVP, 0);
    });

    test('称号の獲得が無効化されている場合はバッジもVPも付与されないこと', () async {
      final disabledContainer = ProviderContainer(
        overrides: [
          enablePlectrumConcertVol11BadgeProvider.overrideWith((_) => false),
        ],
      );
      addTearDown(disabledContainer.dispose);

      final result = await disabledContainer
          .read(codeScannerPresenterProvider.notifier)
          .handleScannedValue(plectrumConcertVol11CodeUrl);

      expect(result, CodeScanResult.notAvailable);

      final badges = await disabledContainer.read(
        earnedBadgesRepositoryProvider.future,
      );
      final totalVP = await disabledContainer.read(
        vivaPointRepositoryProvider.future,
      );

      expect(badges, isEmpty);
      expect(totalVP, 0);
    });

    test('称号の獲得が無効化されている場合は獲得済みでも獲得できない旨を返すこと', () async {
      final disabledContainer = ProviderContainer(
        overrides: [
          enablePlectrumConcertVol11BadgeProvider.overrideWith((_) => false),
        ],
      );
      addTearDown(disabledContainer.dispose);

      // 事前に同じバッジを獲得済みにしておく
      await disabledContainer
          .read(earnedBadgesRepositoryProvider.notifier)
          .add(
            EarnedBadge(
              badge: AppBadge.plectrumConcertVol11,
              earnedAt: DateTime(2026, 6, 27, 12),
            ),
          );

      final result = await disabledContainer
          .read(codeScannerPresenterProvider.notifier)
          .handleScannedValue(plectrumConcertVol11CodeUrl);

      expect(result, CodeScanResult.notAvailable);
    });
  });
}
