import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/chat_mode.dart';
import 'package:house_worker/ui/component/chat_mode_extension.dart';

void main() {
  group('ChatModeExtension', () {
    test('displayName はモードごとに一意な表示名を返すこと', () {
      expect(
        ChatMode.plectrumSocietyMaster.displayName,
        equals('結社マスター'),
      );
      expect(
        ChatMode.chitChatMaster.displayName,
        equals('雑談マスター'),
      );
    });

    test('shortLabel はモードごとに一意な短いラベルを返すこと', () {
      expect(
        ChatMode.plectrumSocietyMaster.shortLabel,
        isNotEmpty,
      );
      expect(
        ChatMode.chitChatMaster.shortLabel,
        isNotEmpty,
      );
      expect(
        ChatMode.plectrumSocietyMaster.shortLabel,
        isNot(equals(ChatMode.chitChatMaster.shortLabel)),
      );
    });

    test('description はモードごとに空でない説明を返すこと', () {
      for (final mode in ChatMode.values) {
        expect(mode.description, isNotEmpty);
      }
    });
  });
}
