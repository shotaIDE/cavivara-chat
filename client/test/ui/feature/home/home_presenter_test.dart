import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/ai_response.dart';
import 'package:house_worker/data/model/cavivara_profile.dart';
import 'package:house_worker/data/model/chat_message.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/model/send_message_exception.dart';
import 'package:house_worker/data/service/ai_chat_service.dart';
import 'package:house_worker/data/service/cavivara_profile_service.dart';
import 'package:house_worker/data/service/preference_service.dart';
import 'package:house_worker/ui/feature/home/home_presenter.dart';
import 'package:mocktail/mocktail.dart';

class MockAiChatService extends Mock implements AiChatService {}

class MockPreferenceService extends Mock implements PreferenceService {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail matchers
    registerFallbackValue(PreferenceKey.skipClearChatConfirmation);
  });

  group('Home Presenter - Chat Messages', () {
    late MockAiChatService mockAiChatService;
    late MockPreferenceService mockPreferenceService;
    late ProviderContainer container;

    setUp(() {
      mockAiChatService = MockAiChatService();
      mockPreferenceService = MockPreferenceService();

      // モックの設定 - VivaPointRepository用
      when(
        () => mockPreferenceService.getInt(any()),
      ).thenAnswer((_) async => 0);
      when(
        () => mockPreferenceService.setInt(any(), value: any(named: 'value')),
      ).thenAnswer((_) async {});

      // HasEverSentMessageRepository用のモック
      when(
        () => mockPreferenceService.getBool(any()),
      ).thenAnswer((_) async => false);
      when(
        () => mockPreferenceService.setBool(
          any(),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      // テスト用のカヴィヴァラプロフィールを作成
      const testCavivaraProfile = CavivaraProfile(
        displayName: 'テストカヴィヴァラ',
        title: 'テスト用',
        description: 'テスト用のカヴィヴァラです',
        iconPath: 'test_icon.png',
        aiPrompt: 'You are a helpful assistant.',
        tags: ['test'],
      );

      container = ProviderContainer(
        overrides: [
          aiChatServiceProvider.overrideWith((ref) => mockAiChatService),
          preferenceServiceProvider.overrideWith(
            (ref) => mockPreferenceService,
          ),
          cavivaraProfileProvider.overrideWith(
            (ref) => testCavivaraProfile,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('chatMessagesProvider', () {
      test('初期状態では空のメッセージリストが返されること', () {
        final messages = container.read(chatMessagesProvider);

        expect(messages, isEmpty);
      });
    });

    group('sendMessage', () {
      test('メッセージ送信に成功した場合、メッセージリストが更新されること', () async {
        const messageText = 'テストメッセージ';

        // AI サービスのモック設定
        when(
          () => mockAiChatService.sendMessageStream(
            messageText,
            systemPrompt: any<String>(named: 'systemPrompt'),
            conversationHistory: any<List<ChatMessage>?>(
              named: 'conversationHistory',
            ),
          ),
        ).thenAnswer(
          (_) => Stream.value(
            const AiResponse(content: 'AIからの返信'),
          ),
        );

        final notifier = container.read(chatMessagesProvider.notifier);

        // メッセージ送信
        await notifier.sendMessage(messageText);

        final messages = container.read(chatMessagesProvider);

        // ユーザーメッセージとAIメッセージが追加されていることを確認
        expect(messages, hasLength(2));
        expect(messages[0].content, equals(messageText));
        expect(messages[0].sender, equals(const ChatMessageSender.user()));
        expect(messages[1].content, equals('AIからの返信'));
        expect(messages[1].sender, equals(const ChatMessageSender.ai()));
      });

      test(
        'AI サービス呼び出し時に適切なパラメーターが渡されること',
        () async {
          const messageText = 'テストメッセージ';

          when(
            () => mockAiChatService.sendMessageStream(
              messageText,
              systemPrompt: any<String>(named: 'systemPrompt'),
              conversationHistory: any<List<ChatMessage>?>(
                named: 'conversationHistory',
              ),
            ),
          ).thenAnswer(
            (_) => Stream.value(
              const AiResponse(content: 'AIからの返信'),
            ),
          );

          final notifier = container.read(chatMessagesProvider.notifier);
          await notifier.sendMessage(messageText);

          // AI サービスが適切なパラメーターで呼び出されたことを確認
          verify(
            () => mockAiChatService.sendMessageStream(
              messageText,
              systemPrompt: any<String>(named: 'systemPrompt'),
              conversationHistory: any<List<ChatMessage>?>(
                named: 'conversationHistory',
              ),
            ),
          ).called(1);
        },
      );

      test('メッセージ送信エラー時に適切に処理されること', () async {
        const messageText = 'エラーテスト';

        when(
          () => mockAiChatService.sendMessageStream(
            messageText,
            systemPrompt: any<String>(named: 'systemPrompt'),
            conversationHistory: any<List<ChatMessage>?>(
              named: 'conversationHistory',
            ),
          ),
        ).thenThrow(
          const SendMessageException.uncategorized(
            message: 'AI service error',
          ),
        );

        final notifier = container.read(chatMessagesProvider.notifier);

        // エラーが発生してもメッセージリストが破綻しないことを確認
        await notifier.sendMessage(messageText);

        final messages = container.read(chatMessagesProvider);

        // ユーザーメッセージとエラーメッセージが追加されていることを確認
        expect(messages, hasLength(2));
        expect(messages[0].content, equals(messageText));
        expect(messages[0].sender, equals(const ChatMessageSender.user()));
        expect(messages[1].content, contains('原因不明のエラーが発生しました'));
        expect(messages[1].sender, equals(const ChatMessageSender.app()));
      });

      test('ストリーミングレスポンスが部分的に更新されること', () async {
        const messageText = 'ストリーミングテスト';

        // ストリーミングレスポンスのモック設定
        when(
          () => mockAiChatService.sendMessageStream(
            messageText,
            systemPrompt: any<String>(named: 'systemPrompt'),
            conversationHistory: any<List<ChatMessage>?>(
              named: 'conversationHistory',
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const AiResponse(content: 'AI'),
            const AiResponse(content: ' から'),
            const AiResponse(content: 'の返信'),
          ]),
        );

        final notifier = container.read(chatMessagesProvider.notifier);
        await notifier.sendMessage(messageText);

        final messages = container.read(chatMessagesProvider);

        // 最終的にストリーミングが完了したメッセージが保存されることを確認
        expect(messages, hasLength(2));
        expect(messages[1].content, equals('AI からの返信'));
        expect(messages[1].sender, equals(const ChatMessageSender.ai()));
      });
    });

    group('clearMessages', () {
      test('メッセージがクリアされること', () async {
        // AI サービスのモック設定
        when(
          () => mockAiChatService.sendMessageStream(
            any<String>(),
            systemPrompt: any<String>(named: 'systemPrompt'),
            conversationHistory: any<List<ChatMessage>?>(
              named: 'conversationHistory',
            ),
          ),
        ).thenAnswer(
          (_) => Stream.value(
            const AiResponse(content: 'AIからの返信'),
          ),
        );

        // メッセージを追加
        final notifier = container.read(chatMessagesProvider.notifier);
        await notifier.sendMessage('メッセージ1');

        expect(container.read(chatMessagesProvider), hasLength(2));

        // メッセージをクリア
        notifier.clearMessages();

        expect(container.read(chatMessagesProvider), isEmpty);
      });
    });
  });

  group('Home Presenter - Suggested Replies', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('suggestedRepliesProvider', () {
      test('初期状態では空のサジェストリストが返されること', () {
        final suggestions = container.read(suggestedRepliesProvider);

        expect(suggestions, isEmpty);
      });

      test('save メソッドでサジェストを保存できること', () {
        final testSuggestions = ['質問1', '質問2', '質問3'];

        container.read(suggestedRepliesProvider.notifier).save(testSuggestions);

        final suggestions = container.read(suggestedRepliesProvider);

        expect(suggestions, equals(testSuggestions));
      });

      test('clear メソッドでサジェストをクリアできること', () {
        final testSuggestions = ['質問1', '質問2', '質問3'];

        container.read(suggestedRepliesProvider.notifier).save(testSuggestions);

        // 保存されていることを確認
        expect(
          container.read(suggestedRepliesProvider),
          equals(testSuggestions),
        );

        // クリア
        container.read(suggestedRepliesProvider.notifier).clear();

        final suggestions = container.read(suggestedRepliesProvider);

        expect(suggestions, isEmpty);
      });

      test('空のリストを保存できること', () {
        final testSuggestions = ['質問1', '質問2'];

        final notifier = container.read(suggestedRepliesProvider.notifier)
          ..save(testSuggestions);

        // 最初にサジェストを保存されていることを確認
        expect(
          container.read(suggestedRepliesProvider),
          equals(testSuggestions),
        );

        // 空のリストで上書き
        notifier.save([]);

        final suggestions = container.read(suggestedRepliesProvider);

        expect(suggestions, isEmpty);
      });
    });

    group('sendMessage - サジェスト管理', () {
      late MockAiChatService mockAiChatService;
      late MockPreferenceService mockPreferenceService;
      late ProviderContainer container;

      setUp(() {
        mockAiChatService = MockAiChatService();
        mockPreferenceService = MockPreferenceService();

        // モックの設定
        when(
          () => mockPreferenceService.getInt(any()),
        ).thenAnswer((_) async => 0);
        when(
          () => mockPreferenceService.setInt(
            any(),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockPreferenceService.getBool(any()),
        ).thenAnswer((_) async => false);
        when(
          () => mockPreferenceService.setBool(
            any(),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        container = ProviderContainer(
          overrides: [
            aiChatServiceProvider.overrideWith((ref) => mockAiChatService),
            preferenceServiceProvider.overrideWith(
              (ref) => mockPreferenceService,
            ),
            cavivaraProfileProvider.overrideWith(
              (ref) => const CavivaraProfile(
                displayName: 'テストカヴィヴァラ',
                title: 'テスト用',
                description: 'テスト用のカヴィヴァラです',
                iconPath: 'test_icon.png',
                aiPrompt: 'You are a helpful assistant.',
                tags: ['test'],
              ),
            ),
          ],
        );
      });

      tearDown(() {
        container.dispose();
      });

      test('メッセージ送信開始時に既存のサジェストがクリアされること', () async {
        final testSuggestions = ['質問1', '質問2', '質問3'];

        // 事前にサジェストを保存
        container.read(suggestedRepliesProvider.notifier).save(testSuggestions);

        // サジェストが保存されていることを確認
        expect(
          container.read(suggestedRepliesProvider),
          equals(testSuggestions),
        );

        // AIサービスのモック設定
        when(
          () => mockAiChatService.sendMessageStream(
            any<String>(),
            systemPrompt: any<String>(named: 'systemPrompt'),
            conversationHistory: any<List<ChatMessage>?>(
              named: 'conversationHistory',
            ),
          ),
        ).thenAnswer(
          (_) => Stream.value(
            const AiResponse(content: 'AIからの返信'),
          ),
        );

        // メッセージ送信
        final notifier = container.read(chatMessagesProvider.notifier);
        await notifier.sendMessage('テストメッセージ');

        // サジェストがクリアされていることを確認
        final suggestions = container.read(suggestedRepliesProvider);
        expect(suggestions, isEmpty);
      });

      test('AIからサジェスト付きレスポンスを受信した場合、サジェストが保存されること', () async {
        const messageText = 'テストメッセージ';
        final testSuggestions = ['次の質問1', '次の質問2', '次の質問3'];

        // AIサービスのモック設定
        when(
          () => mockAiChatService.sendMessageStream(
            messageText,
            systemPrompt: any<String>(named: 'systemPrompt'),
            conversationHistory: any<List<ChatMessage>?>(
              named: 'conversationHistory',
            ),
          ),
        ).thenAnswer(
          (_) => Stream.value(
            AiResponse(
              content: 'AIからの返信',
              suggestedReplies: testSuggestions,
            ),
          ),
        );

        // メッセージ送信
        final notifier = container.read(chatMessagesProvider.notifier);
        await notifier.sendMessage(messageText);

        // サジェストが保存されていることを確認
        final suggestions = container.read(suggestedRepliesProvider);
        expect(suggestions, equals(testSuggestions));
      });

      test('AIからサジェストなしレスポンスを受信した場合、サジェストは空のままであること', () async {
        const messageText = 'テストメッセージ';

        // AIサービスのモック設定（サジェストなし）
        when(
          () => mockAiChatService.sendMessageStream(
            messageText,
            systemPrompt: any<String>(named: 'systemPrompt'),
            conversationHistory: any<List<ChatMessage>?>(
              named: 'conversationHistory',
            ),
          ),
        ).thenAnswer(
          (_) => Stream.value(
            const AiResponse(content: 'AIからの返信'),
          ),
        );

        // メッセージ送信
        final notifier = container.read(chatMessagesProvider.notifier);
        await notifier.sendMessage(messageText);

        // サジェストが空であることを確認
        final suggestions = container.read(suggestedRepliesProvider);
        expect(suggestions, isEmpty);
      });

      test('ストリーミング中に複数のサジェストを受信した場合、最後のサジェストが保存されること', () async {
        const messageText = 'テストメッセージ';

        // ストリーミングレスポンスのモック設定
        when(
          () => mockAiChatService.sendMessageStream(
            messageText,
            systemPrompt: any<String>(named: 'systemPrompt'),
            conversationHistory: any<List<ChatMessage>?>(
              named: 'conversationHistory',
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const AiResponse(
              content: 'AI',
              suggestedReplies: ['質問A', '質問B'],
            ),
            const AiResponse(
              content: ' から',
              suggestedReplies: ['質問C', '質問D'],
            ),
            const AiResponse(
              content: 'の返信',
              suggestedReplies: ['最終質問1', '最終質問2', '最終質問3'],
            ),
          ]),
        );

        // メッセージ送信
        final notifier = container.read(chatMessagesProvider.notifier);
        await notifier.sendMessage(messageText);

        // 最後のサジェストが保存されていることを確認
        final suggestions = container.read(suggestedRepliesProvider);
        expect(suggestions, equals(['最終質問1', '最終質問2', '最終質問3']));
      });

      test('チャットクリア時にサジェストもクリアされること', () {
        final testSuggestions = ['質問1', '質問2', '質問3'];

        // サジェストを保存
        container.read(suggestedRepliesProvider.notifier).save(testSuggestions);

        // サジェストが保存されていることを確認
        expect(
          container.read(suggestedRepliesProvider),
          equals(testSuggestions),
        );

        // チャットをクリア
        container.read(chatMessagesProvider.notifier).clearMessages();

        // サジェストがクリアされていることを確認
        final suggestions = container.read(suggestedRepliesProvider);
        expect(suggestions, isEmpty);
      });
    });
  });
}
