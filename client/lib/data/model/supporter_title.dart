/// サポーター称号を表すenum
enum SupporterTitle {
  /// 駆け出しヴィヴァサポーター
  newbie,

  /// 初心ヴィヴァサポーター
  beginner,

  /// 一人前ヴィヴァサポーター
  intermediate,

  /// ベテランヴィヴァサポーター
  advanced,

  /// 熟練ヴィヴァサポーター
  expert,

  /// 達人ヴィヴァサポーター
  master,

  /// 伝説のヴィヴァサポーター
  legend,
}

/// SupporterTitleにビジネスロジックを拡張するExtension
extension SupporterTitleLogic on SupporterTitle {
  /// 必要最低VP
  int get requiredVP {
    return switch (this) {
      SupporterTitle.newbie => 0,
      SupporterTitle.beginner => 10,
      SupporterTitle.intermediate => 30,
      SupporterTitle.advanced => 70,
      SupporterTitle.expert => 150,
      SupporterTitle.master => 300,
      SupporterTitle.legend => 500,
    };
  }

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
