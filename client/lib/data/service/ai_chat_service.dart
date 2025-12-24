import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:house_worker/data/model/ai_response.dart';
import 'package:house_worker/data/model/chat_message.dart';
import 'package:house_worker/data/model/send_message_exception.dart';
import 'package:house_worker/data/service/cavivara_knowledge_service.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_chat_service.g.dart';

@riverpod
AiChatService aiChatService(Ref ref) {
  return AiChatService(
    errorReportService: ref.watch(errorReportServiceProvider),
    knowledgeBase: ref.watch(cavivaraKnowledgeBaseProvider),
  );
}

class AiChatService {
  AiChatService({
    required this.errorReportService,
    required this.knowledgeBase,
  });

  final ErrorReportService errorReportService;
  final CavivaraKnowledgeBase knowledgeBase;
  final Logger _logger = Logger('AiChatService');

  /// チャットセッションのキャッシュ（systemPromptごとに保持）
  final Map<String, ChatSession> _chatSessions = {};

  /// Response Schema定義（AIの返答形式を指定）
  static final _aiResponseSchema = Schema.object(
    properties: {
      'content': Schema.string(
        description: 'AIの返答テキスト',
      ),
      'suggestedReplies': Schema.array(
        description: '次の返答候補のリスト（3〜5個）',
        items: Schema.string(),
      ),
    },
    optionalProperties: ['suggestedReplies'],
  );

  /// Gemini 2.5 Flashモデルを取得（systemPromptを指定可能）
  GenerativeModel _getModel(String systemPrompt) {
    return FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        // ランダム性を制御（0.0-1.0、低い値ほど決定的、高い値ほど創造的）
        temperature: 0.7,
        // 上位P%の確率質量から選択（nucleus sampling）
        topP: 0.8,
        // 上位K個の候補から選択（long tail除去）
        topK: 40,
        // 生成する最大トークン数
        maxOutputTokens: 2048,
        // Response Schemaを使用して構造化レスポンスを取得
        responseMimeType: 'application/json',
        responseSchema: _aiResponseSchema,
      ),
      systemInstruction: Content.system(systemPrompt),
      // TODO(ide): FunctionCallingとレスポンススキーマの併用は不可なので、一旦レスポンススキーマを優先
      // tools: knowledgeBase.tools,
    );
  }

  /// チャットメッセージをストリーミングで送信する
  ///
  /// [message] - 送信するメッセージ
  /// [systemPrompt] - 使用するシステムプロンプト（必須）
  /// [conversationHistory] - 会話履歴（指定された場合、新しいセッションを開始してhistoryを設定）
  ///
  /// Response Schemaを使用して構造化されたAIレスポンスを返す
  Stream<AiResponse> sendMessageStream(
    String message, {
    required String systemPrompt,
    List<ChatMessage>? conversationHistory,
  }) {
    _logger.info(
      'Send message: $message with systemPrompt hash: '
      '${systemPrompt.hashCode}',
    );

    try {
      final chatSession = _createOrReuseChatSession(
        systemPrompt: systemPrompt,
        conversationHistory: conversationHistory,
      );

      return _startMessageProcessing(
        chatSession: chatSession,
        message: message,
      );
    } catch (e, stackTrace) {
      _logger.severe('ストリーミングチャットメッセージの送信に失敗: $e');
      unawaited(errorReportService.recordError(e, stackTrace));
      throw SendMessageException.uncategorized(
        message: '$e',
      );
    }
  }

  ChatSession _createOrReuseChatSession({
    required String systemPrompt,
    List<ChatMessage>? conversationHistory,
  }) {
    if (conversationHistory != null) {
      // 会話履歴が指定された場合は新しいセッションを作成
      final model = _getModel(systemPrompt);
      final history = _convertChatHistoryToContent(conversationHistory);
      return model.startChat(history: history);
    }

    // 既存のセッションを取得または新規作成
    final sessionKey = systemPrompt.hashCode.toString();
    return _chatSessions[sessionKey] ??= _getModel(systemPrompt).startChat();
  }

  /// メッセージ処理を開始する
  Stream<AiResponse> _startMessageProcessing({
    required ChatSession chatSession,
    required String message,
  }) {
    final controller = StreamController<AiResponse>();

    unawaited(() async {
      final responseStream = chatSession.sendMessageStream(
        Content.text(message),
      );

      await _processResponseStream(
        chatSession: chatSession,
        responseStream: responseStream,
        controller: controller,
      );

      await controller.close();
    }());

    return controller.stream;
  }

  Future<void> _processResponseStream({
    required ChatSession chatSession,
    required Stream<GenerateContentResponse> responseStream,
    required StreamController<AiResponse> controller,
    int functionCallDepth = 0,
  }) async {
    // 関数呼び出しの最大深度を制限（無限再帰を防ぐ）
    const maxFunctionCallDepth = 10;

    if (functionCallDepth > maxFunctionCallDepth) {
      _logger.warning(
        'Function call depth limit exceeded ($maxFunctionCallDepth). '
        'Stopping further function calls to prevent infinite recursion.',
      );
      controller.addError(
        const SendMessageException.uncategorized(
          message: '関数呼び出しの深度制限を超過しました。処理を停止します。',
        ),
      );
      return;
    }
    try {
      // Response Schema使用時は、レスポンス全体がJSON形式で返される
      // ストリーミング中のJSONテキストを蓄積
      final jsonBuffer = StringBuffer();

      await for (final chunk in responseStream) {
        final functionCalls = chunk.functionCalls;
        if (functionCalls.isNotEmpty) {
          for (final functionCall in functionCalls) {
            await _handleFunctionCall(
              chatSession: chatSession,
              functionCall: functionCall,
              controller: controller,
              functionCallDepth: functionCallDepth,
            );
          }
          continue;
        }

        final text = chunk.text;
        if (text == null) {
          _logger.warning('AIからの応答チャンクがnullです');
          continue;
        }

        if (text.isEmpty) {
          continue;
        }

        _logger.info('応答チャンクを受信: $text');
        jsonBuffer.write(text);
      }

      // ストリーミング完了後、JSONをパースしてAiResponseを送信
      final fullJsonText = jsonBuffer.toString();
      if (fullJsonText.isNotEmpty) {
        try {
          // JSON文字列をMapとしてパース
          final jsonMap = Map<String, dynamic>.from(
            // dart:convertを使用してJSONをパース
            const JsonDecoder().convert(fullJsonText) as Map<dynamic, dynamic>,
          );

          final aiResponse = AiResponse.fromJson(jsonMap);
          _logger.info(
            '構造化レスポンスをパース: '
            'content="${aiResponse.content}", '
            'suggestedReplies=${aiResponse.suggestedReplies}',
          );

          // パースしたAiResponseを送信
          controller.add(aiResponse);
        } on Exception catch (e) {
          _logger.warning('JSONパースに失敗、テキストとして扱います: $e');
          // パースに失敗した場合は、テキストをそのままcontentとして扱う
          controller.add(
            AiResponse(content: fullJsonText),
          );
        }
      }
    } on SocketException catch (e) {
      _logger.severe('Network error occurred during response processing: $e');

      controller.addError(const SendMessageException.noNetwork());
    } on Exception catch (e, stackTrace) {
      _logger.severe('Failed to process response stream: $e');

      unawaited(errorReportService.recordError(e, stackTrace));

      controller.addError(
        SendMessageException.uncategorized(
          message: 'Failed to process response stream: $e',
        ),
      );
    }
  }

  Future<void> _handleFunctionCall({
    required ChatSession chatSession,
    required FunctionCall functionCall,
    required StreamController<AiResponse> controller,
    required int functionCallDepth,
  }) async {
    _logger.info(
      'Function call requested: ${functionCall.name} with args: '
      '${functionCall.args}',
    );

    try {
      final arguments = _resolveFunctionArguments(functionCall);
      final responsePayload = await knowledgeBase.execute(
        functionName: functionCall.name,
        arguments: arguments,
      );

      final functionResponseContent = Content.functionResponse(
        functionCall.name,
        responsePayload,
      );

      await _processResponseStream(
        chatSession: chatSession,
        responseStream: chatSession.sendMessageStream(functionResponseContent),
        controller: controller,
        functionCallDepth: functionCallDepth + 1,
      );
    } on Exception catch (e, stackTrace) {
      _logger.severe('関数呼び出しの処理に失敗: ${functionCall.name}: $e');

      unawaited(errorReportService.recordError(e, stackTrace));

      controller.addError(
        SendMessageException.uncategorized(
          message: '関数呼び出しの処理に失敗しました: $e',
        ),
      );
    }
  }

  Map<String, dynamic> _resolveFunctionArguments(FunctionCall functionCall) {
    return functionCall.args;
  }

  /// ChatMessageのリストをFirebase AI用のContentリストに変換
  List<Content> _convertChatHistoryToContent(List<ChatMessage> history) {
    return history
        .map((message) {
          return switch (message.sender) {
            ChatMessageSenderUser() => Content.text(message.content),
            ChatMessageSenderAi() => Content.model([TextPart(message.content)]),
            // アプリメッセージはAIモデルに送信される会話の一部となることを意図していないため、
            // チャット履歴から除外
            ChatMessageSenderApp() => null,
          };
        })
        .nonNulls
        .toList();
  }

  /// 特定のsystemPromptのチャットセッションをクリア
  void clearChatSession(String systemPrompt) {
    final sessionKey = systemPrompt.hashCode.toString();
    _chatSessions.remove(sessionKey);
    _logger.info(
      'Chat session cleared for systemPrompt hash: '
      '${systemPrompt.hashCode}',
    );
  }

  /// 全てのチャットセッションをクリア
  void clearAllChatSessions() {
    _chatSessions.clear();
    _logger.info('All chat sessions cleared');
  }
}
