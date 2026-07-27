import 'package:house_worker/data/model/chat_mode.dart';

extension ChatModeExtension on ChatMode {
  String get displayName {
    switch (this) {
      case ChatMode.plectrumSocietyMaster:
        return 'プレクトラム結社マスターモード';
      case ChatMode.chitChatMaster:
        return '雑談マスターモード';
    }
  }

  /// チャット画面のタイトル部分に表示する短いラベル
  String get shortLabel {
    switch (this) {
      case ChatMode.plectrumSocietyMaster:
        return '結社マスター';
      case ChatMode.chitChatMaster:
        return '雑談マスター';
    }
  }

  String get description {
    switch (this) {
      case ChatMode.plectrumSocietyMaster:
        return 'プレクトラム結社について、今来ている演奏会や過去の演奏会について知りたい場合に指定します。';
      case ChatMode.chitChatMaster:
        return '雑談をしたい場合に指定します。';
    }
  }
}
