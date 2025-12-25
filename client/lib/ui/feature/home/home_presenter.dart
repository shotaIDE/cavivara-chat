import 'dart:async';

import 'package:characters/characters.dart';
import 'package:house_worker/data/model/chat_message.dart';
import 'package:house_worker/data/model/send_message_exception.dart';
import 'package:house_worker/data/repository/has_earned_part_time_leader_reward_repository.dart';
import 'package:house_worker/data/repository/has_earned_part_timer_reward_repository.dart';
import 'package:house_worker/data/repository/last_talked_cavivara_id_repository.dart';
import 'package:house_worker/data/repository/received_chat_string_count_repository.dart';
import 'package:house_worker/data/repository/sent_chat_string_count_repository.dart';
import 'package:house_worker/data/service/ai_chat_service.dart';
import 'package:house_worker/data/service/cavivara_directory_service.dart';
import 'package:house_worker/ui/component/heads_up_notification_presenter.dart';
import 'package:house_worker/ui/feature/stats/cavivara_reward.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_presenter.g.dart';

/// 指定されたカヴィヴァラIDのチャットメッセージのリストを管理するプロバイダー
@riverpod
class ChatMessages extends _$ChatMessages {
  @override
  List<ChatMessage> build(String cavivaraId) => [];

  /// ユーザーメッセージを追加し、AIからの返信を取得する
  /// [content] - 送信するメッセージ内容
  /// [cavivaraId] - 対象のカヴィヴァラID（このプロバイダーのパラメーターから自動取得）
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) {
      return;
    }

    // メッセージ送信開始時に既存のサジェストをクリア
    ref.read(suggestedRepliesProvider(cavivaraId).notifier).clear();

    // 簡単なID生成（DateTime + hashCode）
    final now = DateTime.now();
    final userMessageId = '${now.millisecondsSinceEpoch}_${content.hashCode}';

    final userMessage = ChatMessage(
      id: userMessageId,
      content: content,
      sender: const ChatMessageSender.user(),
      timestamp: now,
    );

    // ユーザーメッセージを追加
    state = [...state, userMessage];

    unawaited(
      ref
          .read(sentChatStringCountRepositoryProvider.notifier)
          .add(content.characters.length),
    );

    final aiChatService = ref.read(aiChatServiceProvider);

    // カヴィヴァラのプロフィールを取得してAI用プロンプトを使用
    final cavivaraProfile = ref.read(cavivaraByIdProvider(cavivaraId));
    final systemPrompt = cavivaraProfile.aiPrompt;

    // 現在のチャット履歴を取得（AIサービスに会話履歴として渡すため）
    final conversationHistory = state.where((msg) => !msg.isStreaming).toList();

    final aiMessageId = '${DateTime.now().millisecondsSinceEpoch}_ai';
    final thinkingMessage = ChatMessage(
      id: aiMessageId,
      content: '',
      sender: const ChatMessageSender.ai(),
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    state = [...state, thinkingMessage];

    void updateAiMessage(ChatMessage Function(ChatMessage message) transform) {
      final currentMessages = state;
      final hasMessage = currentMessages.any(
        (message) => message.id == aiMessageId,
      );
      if (!hasMessage) {
        return;
      }

      state = [
        for (final message in currentMessages)
          if (message.id == aiMessageId) transform(message) else message,
      ];
    }

    var hasError = false;
    var buffer = '';
    var lastSuggestedReplies = <String>[];
    try {
      final responseStream = aiChatService.sendMessageStream(
        content,
        systemPrompt: systemPrompt,
        conversationHistory: conversationHistory,
      );

      await for (final aiResponse in responseStream) {
        final chunk = aiResponse.content;
        if (chunk.isEmpty) {
          continue;
        }

        if (buffer.isEmpty) {
          buffer = chunk;
        } else if (chunk.length >= buffer.length && chunk.startsWith(buffer)) {
          buffer = chunk;
        } else {
          buffer += chunk;
        }

        updateAiMessage(
          (message) => message.copyWith(
            content: buffer,
            timestamp: DateTime.now(),
          ),
        );

        // 最新のサジェストを保持
        lastSuggestedReplies = aiResponse.suggestedReplies;
      }
    } on SendMessageException catch (e) {
      hasError = true;

      switch (e) {
        case SendMessageExceptionNoNetwork():
          updateAiMessage(
            (message) => message.copyWith(
              content: 'カヴィヴァラさんに声が届きませんでした。ネットワークの接続状況を確認してください。',
              sender: const ChatMessageSender.app(),
              timestamp: DateTime.now(),
              isStreaming: false,
            ),
          );

        case SendMessageExceptionUncategorized(message: final errorMessage):
          updateAiMessage(
            (message) => message.copyWith(
              content: '原因不明のエラーが発生しました。カヴィヴァラさんが疲れているのかもしれません: $errorMessage',
              sender: const ChatMessageSender.app(),
              timestamp: DateTime.now(),
              isStreaming: false,
            ),
          );
      }
    } on Exception catch (e) {
      hasError = true;
      // TODO(ide): ここは不要なはずなので削除を検討する。テストがパスしなくなる
      updateAiMessage(
        (message) => message.copyWith(
          content: 'エラーが発生しました: $e',
          sender: const ChatMessageSender.app(),
          timestamp: DateTime.now(),
          isStreaming: false,
        ),
      );
    }

    if (!hasError) {
      updateAiMessage(
        (message) => message.copyWith(
          isStreaming: false,
          timestamp: DateTime.now(),
        ),
      );

      // サジェストを保存
      if (lastSuggestedReplies.isNotEmpty) {
        ref
            .read(suggestedRepliesProvider(cavivaraId).notifier)
            .save(lastSuggestedReplies);
      }

      if (buffer.isNotEmpty) {
        unawaited(
          ref
              .read(receivedChatStringCountRepositoryProvider.notifier)
              .add(buffer.characters.length),
        );
      }
    }
  }

  /// チャット履歴をクリアする
  void clearMessages() {
    state = [];

    // サジェストもクリア
    ref.read(suggestedRepliesProvider(cavivaraId).notifier).clear();

    // AIサービスのセッションキャッシュもクリア
    final cavivaraProfile = ref.read(cavivaraByIdProvider(cavivaraId));
    ref.read(aiChatServiceProvider).clearChatSession(cavivaraProfile.aiPrompt);
  }
}

/// 指定されたカヴィヴァラIDでAIがメッセージを受信中かどうかを返すプロバイダー
@riverpod
bool isReceivingMessages(Ref ref, String cavivaraId) {
  final messages = ref.watch(chatMessagesProvider(cavivaraId));
  return messages.any((message) => message.isStreaming);
}

/// 指定されたカヴィヴァラIDのチャット履歴をクリアするヘルパー関数
@riverpod
void clearChatMessages(Ref ref, String cavivaraId) {
  ref.read(chatMessagesProvider(cavivaraId).notifier).clearMessages();
}

/// 全てのチャット履歴をクリアするヘルパー関数
@riverpod
void clearAllChatMessages(Ref ref) {
  final directory = ref.read(cavivaraDirectoryProvider);
  final aiChatService = ref.read(aiChatServiceProvider);

  // 各カヴィヴァラのチャットをクリア
  for (final profile in directory) {
    ref.read(chatMessagesProvider(profile.id).notifier).clearMessages();
  }

  // AIサービスの全セッションをクリア
  aiChatService.clearAllChatSessions();
}

/// 最後に話したカヴィヴァラIDを更新する
@riverpod
Future<void> updateLastTalkedCavivaraId(Ref ref, String cavivaraId) async {
  final notifier = ref.read(lastTalkedCavivaraIdProvider.notifier);
  await notifier.updateId(cavivaraId);
}

/// 指定されたカヴィヴァラIDのサジェストリストを管理するプロバイダー
@riverpod
class SuggestedReplies extends _$SuggestedReplies {
  @override
  List<String> build(String cavivaraId) => [];

  /// サジェストリストを保存
  // ignore: use_setters_to_change_properties
  void save(List<String> suggestions) {
    state = suggestions;
  }

  /// サジェストをクリア
  void clear() {
    state = [];
  }
}

@riverpod
class AwardReceivedChatString extends _$AwardReceivedChatString {
  @override
  void build() {
    ref.listen(
      receivedChatStringCountRepositoryProvider,
      (previous, next) {
        final previousValue = previous?.whenOrNull(data: (value) => value);
        final currentValue = next.whenOrNull(data: (value) => value);
        if (currentValue == null) {
          return;
        }

        _handleReceivedChatStringCountUpdate(
          previous: previousValue,
          current: currentValue,
        );
      },
    );
  }

  Future<void> _handleReceivedChatStringCountUpdate({
    required int? previous,
    required int current,
  }) async {
    final newlyAchieved = CavivaraReward.highestAchieved(current);
    if (newlyAchieved == null) {
      return;
    }

    final hasEarned = await _checkIfRewardEarned(newlyAchieved);

    if (hasEarned) {
      return;
    }

    await _markRewardAsEarned(newlyAchieved);

    ref.read(headsUpNotificationProvider.notifier).show(newlyAchieved);
  }

  Future<bool> _checkIfRewardEarned(CavivaraReward reward) async {
    switch (reward) {
      case CavivaraReward.partTimer:
        return await ref.read(
          hasEarnedPartTimerRewardRepositoryProvider.future,
        );

      case CavivaraReward.leader:
        return await ref.read(
          hasEarnedPartTimeLeaderRewardRepositoryProvider.future,
        );
    }
  }

  Future<void> _markRewardAsEarned(CavivaraReward reward) async {
    switch (reward) {
      case CavivaraReward.partTimer:
        await ref
            .read(hasEarnedPartTimerRewardRepositoryProvider.notifier)
            .markAsEarned();

      case CavivaraReward.leader:
        await ref
            .read(hasEarnedPartTimeLeaderRewardRepositoryProvider.notifier)
            .markAsEarned();
    }
  }
}
