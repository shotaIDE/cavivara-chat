import 'package:house_worker/data/model/app_badge.dart';
import 'package:house_worker/data/model/earned_badge.dart';
import 'package:house_worker/data/repository/earned_badges_repository.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'code_scanner_presenter.g.dart';

/// 結社公演Vol.11のバッジ獲得対象となる二次元コードのURL。
///
/// 二次元コードの文字列がこのURLと完全一致した場合のみバッジを付与する。
const plectrumConcertVol11CodeUrl =
    'cavivara-chat:achievement/plectrum-rc/vol11';

/// 二次元コード読み込み成功時に付与するVP。
const codeScanEventBonusVP = 30;

/// 二次元コード読み取りの判定結果。
enum CodeScanResult {
  /// 対象の二次元コードで、新たにバッジを獲得した
  earnedNewBadge,

  /// 対象の二次元コードだが、すでにバッジを獲得済み
  alreadyEarned,

  /// 対象外の二次元コード
  notMatched,
}

/// 二次元コード読み取り画面のプレゼンター。
///
/// 読み取った文字列が対象のURLと一致した場合に、バッジとVPを付与する。
@riverpod
class CodeScannerPresenter extends _$CodeScannerPresenter {
  @override
  void build() {
    // 付与処理の途中（await後）にリポジトリが破棄されないよう、依存関係として
    // 監視し、このプロバイダーの生存期間中はリポジトリを保持する。
    ref
      ..watch(earnedBadgesRepositoryProvider)
      ..watch(vivaPointRepositoryProvider);
  }

  /// 読み取った二次元コードの文字列を処理し、判定結果を返す。
  Future<CodeScanResult> handleScannedValue(String rawValue) async {
    if (rawValue != plectrumConcertVol11CodeUrl) {
      return CodeScanResult.notMatched;
    }

    // await をまたいで ref を使うと、その間にこのプロバイダーが破棄されて
    // ref が無効化される場合がある。そのため、ref への参照は await より前に
    // すべて同期的に済ませ、以降は取得済みの Future / notifier だけを使う。
    final earnedBadgesFuture = ref.read(earnedBadgesRepositoryProvider.future);
    final earnedBadgesRepository = ref.read(
      earnedBadgesRepositoryProvider.notifier,
    );
    final vivaPointRepository = ref.read(vivaPointRepositoryProvider.notifier);

    final earnedBadges = await earnedBadgesFuture;

    // すでに同じバッジを獲得済みの場合は、二重付与しない
    final alreadyEarned = earnedBadges.any(
      (badge) => badge.badge == AppBadge.plectrumConcertVol11,
    );
    if (alreadyEarned) {
      return CodeScanResult.alreadyEarned;
    }

    final badge = EarnedBadge(
      badge: AppBadge.plectrumConcertVol11,
      earnedAt: DateTime.now(),
    );

    await earnedBadgesRepository.add(badge);
    await vivaPointRepository.addPoint(codeScanEventBonusVP);

    return CodeScanResult.earnedNewBadge;
  }
}
