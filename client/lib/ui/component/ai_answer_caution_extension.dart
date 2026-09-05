import 'package:house_worker/data/model/ai_answer_caution.dart';

extension AiAnswerCautionExtension on AiAnswerCaution {
  /// 注意書きのダイアログで引用する、カヴィヴァラさんのセリフ
  String get quote => switch (this) {
    AiAnswerCaution.overwork => '日々の激務で幻覚を見ることあるヴィヴァよ',
    AiAnswerCaution.sleepDeprivation => '寝不足で夢と現実が混ざることあるヴィヴァよ',
    AiAnswerCaution.hunger => '空腹すぎて口から出まかせを言うことあるヴィヴァよ',
    AiAnswerCaution.oldMemory => '遠い昔の記憶と混同することあるヴィヴァよ',
    AiAnswerCaution.practiceFatigue => '練習のしすぎで頭がぼんやりすることあるヴィヴァよ',
    AiAnswerCaution.catWhim => '猫だから気まぐれに話を盛ることあるヴィヴァよ',
  };
}
