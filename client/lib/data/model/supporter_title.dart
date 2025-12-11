/// サポーター称号を表すenum
enum SupporterTitle {
  /// 駆け出しヴィヴァサポーター
  newbie(0),

  /// 初心ヴィヴァサポーター
  beginner(10),

  /// 一人前ヴィヴァサポーター
  intermediate(30),

  /// ベテランヴィヴァサポーター
  advanced(70),

  /// 熟練ヴィヴァサポーター
  expert(150),

  /// 達人ヴィヴァサポーター
  master(300),

  /// 伝説のヴィヴァサポーター
  legend(500);

  const SupporterTitle(this.requiredVP);

  /// 必要最低VP
  final int requiredVP;
}

/// SupporterTitleにビジネスロジックを拡張するExtension
extension SupporterTitleLogic on SupporterTitle {
  /// 累計VPから現在の称号を算出
  static SupporterTitle fromTotalVP(int totalVP) {
    // 降順でチェックし、最初に条件を満たす称号を返す
    for (final title in SupporterTitle.values.reversed) {
      if (totalVP >= title.requiredVP) {
        return title;
      }
    }
    // ここには到達しないはずだが、万が一の場合は最低ランクを返す
    return SupporterTitle.newbie;
  }

  /// 次の称号を取得（最上位の場合はnull）
  SupporterTitle? get nextTitle {
    final currentIndex = SupporterTitle.values.indexOf(this);

    // 最上位称号の場合はnullを返す
    if (currentIndex == SupporterTitle.values.length - 1) {
      return null;
    }

    return SupporterTitle.values[currentIndex + 1];
  }

  /// 次の称号までに必要なVP数を取得（最上位の場合は0）
  int vpToNextTitle(int currentTotalVP) {
    final next = nextTitle;

    // 最上位称号の場合は0を返す
    if (next == null) {
      return 0;
    }

    return next.requiredVP - currentTotalVP;
  }
}
