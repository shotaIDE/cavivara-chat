import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/ai_answer_caution.dart';
import 'package:house_worker/ui/component/ai_answer_caution_extension.dart';

void main() {
  group('AiAnswerCautionExtension', () {
    test('quote は種類ごとに空でないセリフを返すこと', () {
      for (final caution in AiAnswerCaution.values) {
        expect(caution.quote, isNotEmpty);
      }
    });

    test('quote は種類ごとに一意なセリフを返すこと', () {
      final quotes = AiAnswerCaution.values
          .map((caution) => caution.quote)
          .toSet();

      expect(quotes, hasLength(AiAnswerCaution.values.length));
    });
  });
}
