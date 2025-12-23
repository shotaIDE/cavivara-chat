import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/ai_response.dart';

void main() {
  group('AiResponse', () {
    test('デフォルト値でインスタンスを生成できる', () {
      const aiResponse = AiResponse(
        content: 'こんにちは！',
      );

      expect(aiResponse.content, 'こんにちは！');
      expect(aiResponse.suggestedReplies, isEmpty);
    });

    test('suggestedRepliesを指定してインスタンスを生成できる', () {
      const aiResponse = AiResponse(
        content: 'こんにちは！',
        suggestedReplies: ['ありがとう', 'もっと教えて', 'それはなぜ？'],
      );

      expect(aiResponse.content, 'こんにちは！');
      expect(aiResponse.suggestedReplies, hasLength(3));
      expect(aiResponse.suggestedReplies[0], 'ありがとう');
      expect(aiResponse.suggestedReplies[1], 'もっと教えて');
      expect(aiResponse.suggestedReplies[2], 'それはなぜ？');
    });

    test('JSONからデシリアライズできる', () {
      final json = {
        'content': 'こんにちは！',
        'suggestedReplies': ['ありがとう', 'もっと教えて'],
      };

      final aiResponse = AiResponse.fromJson(json);

      expect(aiResponse.content, 'こんにちは！');
      expect(aiResponse.suggestedReplies, hasLength(2));
      expect(aiResponse.suggestedReplies[0], 'ありがとう');
      expect(aiResponse.suggestedReplies[1], 'もっと教えて');
    });

    test('JSONへシリアライズできる', () {
      const aiResponse = AiResponse(
        content: 'こんにちは！',
        suggestedReplies: ['ありがとう', 'もっと教えて'],
      );

      final json = aiResponse.toJson();

      expect(json['content'], 'こんにちは！');
      final suggestedReplies = json['suggestedReplies'] as List<dynamic>;
      expect(suggestedReplies, hasLength(2));
      expect(suggestedReplies[0], 'ありがとう');
      expect(suggestedReplies[1], 'もっと教えて');
    });

    test('suggestedRepliesが存在しないJSONからデシリアライズできる', () {
      final json = {
        'content': 'こんにちは！',
      };

      final aiResponse = AiResponse.fromJson(json);

      expect(aiResponse.content, 'こんにちは！');
      expect(aiResponse.suggestedReplies, isEmpty);
    });
  });
}
