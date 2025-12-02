enum CavivaraReward {
  partTimer(
    threshold: 1000,
    displayName: 'プレクトラム結社アルバイト',
    conditionDescription: 'カヴィヴァラさんたちから受信したチャットの文字数が1000文字を超えた',
  ),
  leader(
    threshold: 10000,
    displayName: 'プレクトラム結社partTimeLeader',
    conditionDescription: 'カヴィヴァラさんたちから受信したチャットの文字数が10000文字を超えた',
  );

  const CavivaraReward({
    required this.threshold,
    required this.displayName,
    required this.conditionDescription,
  });

  final int threshold;
  final String displayName;
  final String conditionDescription;

  bool isAchieved(int receivedStringCount) => receivedStringCount >= threshold;

  static CavivaraReward? highestAchieved(int receivedStringCount) {
    for (final reward in values.reversed) {
      if (reward.isAchieved(receivedStringCount)) {
        return reward;
      }
    }
    return null;
  }
}
