import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:house_worker/data/model/ai_response.dart';
import 'package:house_worker/data/model/chat_message.dart';
import 'package:house_worker/data/model/chat_mode.dart';
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

  /// チャットセッションのキャッシュ（systemPromptとChatModeの組み合わせごとに保持）
  final Map<String, ChatSession> _chatSessions = {};

  /// Response Schema定義（AIの返答形式を指定）
  ///
  /// FunctionCallingとレスポンススキーマの併用は不可なため、
  /// [ChatMode.chitChatMaster] でのみ使用する。
  ///
  /// 説明文はモデルへの入力となるため、英語で記述する。
  /// 詳細は [AIプロンプトの言語 概要設計書](../../../../doc/design/ai-prompt-language.md)
  /// を参照する。
  static final _aiResponseSchema = Schema.object(
    properties: {
      'content': Schema.string(
        description: 'Your answer text, in Japanese.',
      ),
      'suggestedReplies': Schema.array(
        description:
            'Up to 3 candidate messages, in Japanese, that the user may send '
            'next in reply to your answer. Write them from the user point of '
            'view so that the user can send them as they are.',
        items: Schema.string(),
      ),
    },
    optionalProperties: ['suggestedReplies'],
  );

  /// Gemini 2.5 Flashモデルを取得（systemPromptとChatModeを指定可能）
  ///
  /// FunctionCallingとレスポンススキーマは同時に指定できないため、
  /// [mode] に応じてどちらか一方のみをモデルに設定する。
  GenerativeModel _getModel(String systemPrompt, ChatMode mode) {
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
        // 雑談マスターモードのみ、Response Schemaを使用して構造化レスポンスを取得
        responseMimeType: switch (mode) {
          ChatMode.plectrumSocietyMaster => null,
          ChatMode.chitChatMaster => 'application/json',
        },
        responseSchema: switch (mode) {
          ChatMode.plectrumSocietyMaster => null,
          ChatMode.chitChatMaster => _aiResponseSchema,
        },
      ),
      systemInstruction: Content.system(buildSystemPrompt(systemPrompt, mode)),
      // 結社マスターモードのみ、FunctionCallingを使用する
      tools: switch (mode) {
        ChatMode.plectrumSocietyMaster => knowledgeBase.tools,
        ChatMode.chitChatMaster => null,
      },
    );
  }

  /// モデルに渡すシステムプロンプトを組み立てる
  ///
  /// 結社マスターモードでは Function Calling の利用を促す追加指示を、
  /// 雑談マスターモードでは返答サジェストの生成方針の追加指示を付与する。
  @visibleForTesting
  String buildSystemPrompt(String systemPrompt, ChatMode mode) {
    return switch (mode) {
      ChatMode.plectrumSocietyMaster => _buildPlectrumSocietySystemPrompt(
        systemPrompt,
      ),
      ChatMode.chitChatMaster => _buildChitChatSystemPrompt(systemPrompt),
    };
  }

  /// 結社マスターモードのシステムプロンプトを組み立てる
  ///
  /// カヴィヴァラのプロンプトは自身を「百科事典級の知識を持つ専門家」と規定しており、
  /// Function Calling の利用を促す指示がないとモデルは結社の公式情報も自前の知識で
  /// 答えてしまい、提供済みの関数を呼び出さない（Function Calling が働かない）。
  /// そのため、知識ベースが持つ追加指示をシステムプロンプトに追記する。
  String _buildPlectrumSocietySystemPrompt(String systemPrompt) {
    final toolInstruction = knowledgeBase.toolInstruction;
    if (toolInstruction.isEmpty) {
      return systemPrompt;
    }

    return '$systemPrompt\n\n$toolInstruction';
  }

  /// 雑談マスターモードのシステムプロンプトを組み立てる
  ///
  /// カヴィヴァラのプロンプトは語尾や口調をカヴィヴァラ自身のものに統一するよう
  /// 規定しているため、返答サジェストの視点を明示しないと、モデルはサジェストも
  /// カヴィヴァラのセリフとして生成してしまう。返答サジェストはユーザーが次に
  /// 送るメッセージとしてそのまま送信されるため、ユーザー視点で生成させる指示を
  /// システムプロンプトに追記する。
  String _buildChitChatSystemPrompt(String systemPrompt) {
    return '$systemPrompt\n\n$suggestedRepliesInstruction';
  }

  /// 返答サジェストをユーザー視点で生成させるための指示文
  ///
  /// 指示文は英語で記述し、モデルが出力する文言（返答サジェスト本体や、使わせない
  /// 語尾）は日本語のまま記述する。詳細と日本語訳は
  /// [AIプロンプトの言語 概要設計書](../../../../doc/design/ai-prompt-language.md)
  /// を参照する。
  @visibleForTesting
  static const suggestedRepliesInstruction = '''
## How to make the suggested replies (suggestedReplies)
- suggestedReplies are candidate messages that the user, having read your answer, sends to you next
- Write them in Japanese, as words the user speaks to you, in the user's first person and the user's tone
- Do not make them your own lines. Do not use the sentence endings "ヴィヴァ。" or "ヴィヴァ？"
- Make each one a short sentence of 30 Japanese characters or fewer, so that the user can tap and send it as it is
- Give 3 or fewer candidates whose contents do not overlap''';

  /// チャットメッセージをストリーミングで送信する
  ///
  /// [message] - 送信するメッセージ
  /// [systemPrompt] - 使用するシステムプロンプト（必須）
  /// [mode] - 使用する回答モード（必須）
  /// [conversationHistory] - 会話履歴（指定された場合、新しいセッションを開始してhistoryを設定）
  ///
  /// [ChatMode.chitChatMaster] の場合はResponse Schemaを使用して構造化された
  /// AIレスポンスを返し、[ChatMode.plectrumSocietyMaster] の場合はFunction Calling
  /// を使用してプレーンテキストのレスポンスを返す。
  Stream<AiResponse> sendMessageStream(
    String message, {
    required String systemPrompt,
    required ChatMode mode,
    List<ChatMessage>? conversationHistory,
  }) {
    _logger.info(
      'Send message: $message with systemPrompt hash: '
      '${systemPrompt.hashCode}, mode: $mode',
    );

    try {
      final chatSession = _createOrReuseChatSession(
        systemPrompt: systemPrompt,
        mode: mode,
        conversationHistory: conversationHistory,
      );

      return _startMessageProcessing(
        chatSession: chatSession,
        message: message,
        mode: mode,
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
    required ChatMode mode,
    List<ChatMessage>? conversationHistory,
  }) {
    if (conversationHistory != null) {
      // 会話履歴が指定された場合は新しいセッションを作成
      final model = _getModel(systemPrompt, mode);
      final history = _convertChatHistoryToContent(conversationHistory);
      return model.startChat(history: history);
    }

    // 既存のセッションを取得または新規作成
    final sessionKey = _sessionKey(systemPrompt: systemPrompt, mode: mode);
    return _chatSessions[sessionKey] ??= _getModel(
      systemPrompt,
      mode,
    ).startChat();
  }

  String _sessionKey({required String systemPrompt, required ChatMode mode}) {
    return '${systemPrompt.hashCode}_${mode.name}';
  }

  /// メッセージ処理を開始する
  Stream<AiResponse> _startMessageProcessing({
    required ChatSession chatSession,
    required String message,
    required ChatMode mode,
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
        mode: mode,
      );

      await controller.close();
    }());

    return controller.stream;
  }

  Future<void> _processResponseStream({
    required ChatSession chatSession,
    required Stream<GenerateContentResponse> responseStream,
    required StreamController<AiResponse> controller,
    required ChatMode mode,
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
      // Response Schema使用時（雑談マスターモード）は、レスポンス全体がJSON形式で
      // 返されるため、ストリーミング中のJSONテキストを蓄積する
      final jsonBuffer = StringBuffer();

      // モデルは 1 回の応答で複数の関数呼び出しを要求することがある（並行 Function
      // Calling）。1 件ずつ結果を返すと、1 件目の結果だけでモデルが回答を生成して
      // しまい、同じ問いへの回答が複数回送出されるため、応答をすべて受け取ってから
      // まとめて実行する。
      final functionCalls = <FunctionCall>[];

      await for (final chunk in responseStream) {
        functionCalls.addAll(chunk.functionCalls);

        // 関数呼び出しを要求する応答では、最終的な回答は関数の結果を返した後に
        // 生成される。この段階のテキストは「調べますね」のような前置きであり、
        // 送出すると最終的な回答とは別のテキストとして UI に残ってしまうため、
        // 関数呼び出しを検出した以降のテキストは無視して関数の実行に進む。
        if (functionCalls.isNotEmpty) {
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

        switch (mode) {
          case ChatMode.plectrumSocietyMaster:
            // Function Calling使用時はレスポンススキーマを使えないため、
            // プレーンテキストのままチャンクごとに送出する
            controller.add(AiResponse(content: text));
          case ChatMode.chitChatMaster:
            jsonBuffer.write(text);
        }
      }

      if (functionCalls.isNotEmpty) {
        await _handleFunctionCalls(
          chatSession: chatSession,
          functionCalls: functionCalls,
          controller: controller,
          mode: mode,
          functionCallDepth: functionCallDepth,
        );
        return;
      }

      if (mode == ChatMode.plectrumSocietyMaster) {
        return;
      }

      // ストリーミング完了後、JSONをパースしてAiResponseを送信
      final fullJsonText = jsonBuffer.toString();
      if (fullJsonText.isNotEmpty) {
        try {
          // JSON文字列をMapとしてパース
          final jsonMap = Map<String, dynamic>.from(
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
        } on Exception catch (e, stackTrace) {
          _logger.warning('JSONパースに失敗、テキストから抽出を試みます: $e');
          unawaited(errorReportService.recordError(e, stackTrace));

          // パースに失敗した場合、正規表現でcontentフィールドの抽出を試みる
          final extractedContent = extractContentFromJson(fullJsonText);
          controller.add(
            AiResponse(content: extractedContent),
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

  /// 要求されたすべての関数を実行し、結果をまとめてモデルに返す
  ///
  /// 関数の結果は 1 通のメッセージにまとめて送信する。1 件ずつ送信すると、
  /// モデルが未回答の関数呼び出しに対する応答を待たずに回答を生成してしまう。
  Future<void> _handleFunctionCalls({
    required ChatSession chatSession,
    required List<FunctionCall> functionCalls,
    required StreamController<AiResponse> controller,
    required ChatMode mode,
    required int functionCallDepth,
  }) async {
    final functionResponses = <FunctionResponse>[];
    for (final functionCall in functionCalls) {
      _logger.info(
        'Function call requested: ${functionCall.name} with args: '
        '${functionCall.args}',
      );

      functionResponses.add(
        FunctionResponse(
          functionCall.name,
          await _executeFunctionCall(functionCall),
        ),
      );
    }

    await _processResponseStream(
      chatSession: chatSession,
      responseStream: chatSession.sendMessageStream(
        Content.functionResponses(functionResponses),
      ),
      controller: controller,
      mode: mode,
      functionCallDepth: functionCallDepth + 1,
    );
  }

  /// 関数を 1 つ実行し、モデルに返す応答内容を取得する
  ///
  /// 1 件の失敗でターン全体を打ち切ると、成功した関数の結果もモデルに渡らず、
  /// 会話が進まなくなる。そのため、失敗した場合もその旨を応答内容として返し、
  /// 分からない旨を回答させる。
  Future<Map<String, dynamic>> _executeFunctionCall(
    FunctionCall functionCall,
  ) async {
    try {
      return await knowledgeBase.execute(
        functionName: functionCall.name,
        arguments: functionCall.args,
      );
    } on Exception catch (e, stackTrace) {
      _logger.severe('関数呼び出しの処理に失敗: ${functionCall.name}: $e');

      unawaited(errorReportService.recordError(e, stackTrace));

      return {
        'found': false,
        // モデルへの入力となる文言は、トークン数を抑えるため英語で記述する
        'message': 'The function failed to run.',
        'requestedFunction': functionCall.name,
      };
    }
  }

  /// 不完全なJSONテキストからcontentフィールドの値を抽出する
  ///
  /// AIがResponse Schemaに従わない形式で返した場合や、
  /// JSONが途中で切れている場合のフォールバック処理
  @visibleForTesting
  String extractContentFromJson(String jsonText) {
    // "content": "..." の形式でcontentフィールドを抽出
    // JSON文字列内のエスケープ文字を考慮
    final contentMatch = RegExp(
      r'"content"\s*:\s*"((?:[^"\\]|\\.)*)"',
      dotAll: true,
    ).firstMatch(jsonText);

    if (contentMatch != null) {
      final extractedContent = contentMatch.group(1) ?? jsonText;
      // JSON文字列のエスケープをデコード
      return extractedContent
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\t', '\t')
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', '\\');
    }

    // 正規表現でも抽出できなかった場合は元のテキストを使用
    _logger.fine('contentフィールドの抽出に失敗しました');
    return jsonText;
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

  /// 特定のsystemPromptのチャットセッションをクリア（全ChatMode分）
  void clearChatSession(String systemPrompt) {
    for (final mode in ChatMode.values) {
      final sessionKey = _sessionKey(systemPrompt: systemPrompt, mode: mode);
      _chatSessions.remove(sessionKey);
    }
    _logger.info(
      'Chat session cleared for systemPrompt hash: '
      '${systemPrompt.hashCode}',
    );
  }
}
