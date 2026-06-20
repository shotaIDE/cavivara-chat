import 'dart:async';

import 'package:characters/characters.dart';
import 'package:house_worker/data/model/chat_message.dart';
import 'package:house_worker/data/model/send_message_exception.dart';
import 'package:house_worker/data/model/supporter_title.dart';
import 'package:house_worker/data/repository/has_earned_part_time_leader_reward_repository.dart';
import 'package:house_worker/data/repository/has_earned_part_timer_reward_repository.dart';
import 'package:house_worker/data/repository/login_bonus_granted_dates_repository.dart';
import 'package:house_worker/data/repository/received_chat_string_count_repository.dart';
import 'package:house_worker/data/repository/sent_chat_string_count_repository.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:house_worker/data/service/ai_chat_service.dart';
import 'package:house_worker/data/service/cavivara_profile_service.dart';
import 'package:house_worker/ui/component/heads_up_notification_presenter.dart';
import 'package:house_worker/ui/component/supporter_title_extension.dart';
import 'package:house_worker/ui/feature/stats/cavivara_reward.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_presenter.g.dart';

/// チャットメッセージのリストを管理するプロバイダー
@riverpod
class ChatMessages extends _$ChatMessages {
  @override
  List<ChatMessage> build() => [];

  /// ユーザーメッセージを追加し、AIからの返信を取得する
  /// [content] - 送信するメッセージ内容
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) {
      return;
    }

    // メッセージ送信開始時に既存のサジェストをクリア
    ref.read(suggestedRepliesProvider.notifier).clear();

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
    final cavivaraProfile = ref.read(cavivaraProfileProvider);
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
        ref.read(suggestedRepliesProvider.notifier).save(lastSuggestedReplies);
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
    ref.read(suggestedRepliesProvider.notifier).clear();

    // AIサービスのセッションキャッシュもクリア
    final cavivaraProfile = ref.read(cavivaraProfileProvider);
    ref.read(aiChatServiceProvider).clearChatSession(cavivaraProfile.aiPrompt);
  }
}

/// AIがメッセージを受信中かどうかを返すプロバイダー
@riverpod
bool isReceivingMessages(Ref ref) {
  final messages = ref.watch(chatMessagesProvider);
  return messages.any((message) => message.isStreaming);
}

/// サジェストリストを管理するプロバイダー
@riverpod
class SuggestedReplies extends _$SuggestedReplies {
  @override
  List<String> build() => [];

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

/// 初回メッセージボーナスのVP
const _firstMessageBonusVP = 10;

@riverpod
class AwardFirstMessageBonus extends _$AwardFirstMessageBonus {
  @override
  void build() {
    // vivaPointRepositoryへの依存関係を作成し、参照を保持
    ref.watch(vivaPointRepositoryProvider);
    final vivaPointRepository = ref.read(vivaPointRepositoryProvider.notifier);

    ref.listen(
      sentChatStringCountRepositoryProvider,
      (previous, next) {
        final previousValue = previous?.whenOrNull(data: (value) => value);
        final currentValue = next.whenOrNull(data: (value) => value);

        // 初回メッセージ送信を検知（0から1以上への変化）
        if (previousValue == 0 && currentValue != null && currentValue > 0) {
          _handleFirstMessageSent(vivaPointRepository);
        }
      },
    );
  }

  Future<void> _handleFirstMessageSent(
    VivaPointRepository vivaPointRepository,
  ) async {
    // ボーナスを付与
    final currentVP = await ref.read(vivaPointRepositoryProvider.future);
    final newTotalVP = currentVP + _firstMessageBonusVP;
    await vivaPointRepository.setPoint(newTotalVP);

    // 新しい称号を取得
    final newTitle = SupporterTitleLogic.fromTotalVP(newTotalVP);

    // 通知を表示
    ref
        .read(headsUpNotificationProvider.notifier)
        .showFirstMessageBonus(
          earnedVP: _firstMessageBonusVP,
          newTitleName: newTitle.displayName,
        );
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

/// ログインボーナスで付与するVP
const _dailyLoginBonusVP = 1;

/// 1日1回のログインボーナスを付与するプロバイダー。
///
/// 画面表示などでこのプロバイダーが監視されたタイミングで、当日がまだ付与済み
/// でなければVPを付与し、アプリ内通知を表示する。付与した日付は
/// [LoginBonusGrantedDatesRepository]で配列として永続化し、同一日付に対する
/// 重複付与を防ぐ。
@riverpod
class AwardDailyLoginBonus extends _$AwardDailyLoginBonus {
  @override
  void build() {
    unawaited(_tryAwardDailyLoginBonus());
  }

  Future<void> _tryAwardDailyLoginBonus() async {
    final grantedDates = await ref.read(
      loginBonusGrantedDatesRepositoryProvider.future,
    );

    // 日付単位で比較するため、時刻部分を切り捨てた当日の日付を求める
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 当日がすでに付与済みの日付に含まれる場合は何もしない
    final hasGrantedToday = grantedDates.any(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );
    if (hasGrantedToday) {
      return;
    }

    // VPを付与
    final currentVP = await ref.read(vivaPointRepositoryProvider.future);
    final newTotalVP = currentVP + _dailyLoginBonusVP;
    await ref.read(vivaPointRepositoryProvider.notifier).setPoint(newTotalVP);

    // 付与日を記録
    await ref
        .read(loginBonusGrantedDatesRepositoryProvider.notifier)
        .add(today);

    // 通知を表示
    ref
        .read(headsUpNotificationProvider.notifier)
        .showDailyLoginBonus(earnedVP: _dailyLoginBonusVP);
  }
}
