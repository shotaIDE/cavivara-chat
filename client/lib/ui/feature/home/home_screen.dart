import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/chat_bubble_design.dart';
import 'package:house_worker/data/model/chat_message.dart';
import 'package:house_worker/data/repository/chat_bubble_design_repository.dart';
import 'package:house_worker/data/repository/skip_clear_chat_confirmation_repository.dart';
import 'package:house_worker/data/service/cavivara_directory_service.dart';
import 'package:house_worker/ui/component/app_drawer.dart';
import 'package:house_worker/ui/component/cavivara_avatar.dart';
import 'package:house_worker/ui/component/chat_bubble_design_extension.dart';
import 'package:house_worker/ui/component/clear_chat_confirmation_dialog.dart';
import 'package:house_worker/ui/component/suggested_reply_list.dart';
import 'package:house_worker/ui/feature/home/home_presenter.dart';
import 'package:house_worker/ui/feature/job_market/job_market_screen.dart';
import 'package:house_worker/ui/feature/resume/resume_screen.dart';
import 'package:house_worker/ui/feature/settings/settings_screen.dart';
import 'package:house_worker/ui/feature/stats/user_statistics_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.cavivaraId});

  static const defaultCavivaraId = 'cavivara_default';

  /// 対象のカヴィヴァラID
  final String cavivaraId;

  static const name = 'HomeScreen';

  static MaterialPageRoute<HomeScreen> route(String cavivaraId) =>
      MaterialPageRoute<HomeScreen>(
        builder: (_) => HomeScreen(cavivaraId: cavivaraId),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isMessageEmpty = true;

  @override
  void initState() {
    super.initState();

    _messageController.addListener(_onMessageChanged);

    unawaited(
      ref.read(updateLastTalkedCavivaraIdProvider(widget.cavivaraId).future),
    );

    ref.listenManual(awardReceivedChatStringProvider, (_, _) {
      // Providerの副作用のみを利用するため、何もしない
    });
  }

  void _onMessageChanged() {
    final isEmpty = _messageController.text.trim().isEmpty;
    if (_isMessageEmpty != isEmpty) {
      setState(() {
        _isMessageEmpty = isEmpty;
      });
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.cavivaraId != widget.cavivaraId) {
      unawaited(
        ref.read(updateLastTalkedCavivaraIdProvider(widget.cavivaraId).future),
      );
    }
  }

  @override
  void dispose() {
    _messageController
      ..removeListener(_onMessageChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cavivaraProfile = ref.watch(cavivaraByIdProvider(widget.cavivaraId));

    final title = Row(
      children: [
        CavivaraAvatar(
          size: 32,
          assetPath: cavivaraProfile.iconPath,
          cavivaraId: widget.cavivaraId,
          onTap: () => Navigator.of(context).push(
            ResumeScreen.route(widget.cavivaraId),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            cavivaraProfile.displayName,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );

    final clearButton = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: '記憶を消去する',
        child: IconButton(
          onPressed: _clearChat,
          icon: const Icon(Icons.delete_forever),
        ),
      ),
    );

    final body = Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismissKeyboard,
            child: _ChatMessageList(
              controller: _scrollController,
              onMessageSent: _onMessageSent,
              cavivaraId: widget.cavivaraId,
            ),
          ),
        ),
        _messageInput(),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: title,
        actions: [clearButton],
      ),
      drawer: AppDrawer(
        isTalkSelected: true,
        isJobMarketSelected: false,
        isAchievementSelected: false,
        onSelectTalk: () {
          Navigator.of(context).pushAndRemoveUntil(
            HomeScreen.route(widget.cavivaraId),
            (route) => false,
          );
        },
        onSelectJobMarket: () {
          Navigator.of(context).pushAndRemoveUntil(
            JobMarketScreen.route(),
            (route) => false,
          );
        },
        onSelectAchievement: () {
          Navigator.of(context).push(UserStatisticsScreen.route());
        },
        onSelectSettings: () {
          Navigator.of(context).push(SettingsScreen.route());
        },
      ),
      body: body,
    );
  }

  Future<void> _clearChat() async {
    final skipConfirmation = await ref.read(
      skipClearChatConfirmationProvider.future,
    );

    if (!skipConfirmation) {
      if (!mounted) {
        return;
      }

      final result = await showDialog<ClearChatDialogResult>(
        context: context,
        builder: (context) => const ClearChatConfirmationDialog(),
      );

      if (result == null || !result.confirmed) {
        return;
      }

      if (result.shouldSkipConfirmation) {
        await ref
            .read(skipClearChatConfirmationProvider.notifier)
            .setShouldSkip();
      }
    }

    if (!mounted) {
      return;
    }

    ref.read(chatMessagesProvider(widget.cavivaraId).notifier).clearMessages();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      ref
          .read(chatMessagesProvider(widget.cavivaraId).notifier)
          .sendMessage(message);
      _messageController.clear();
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _onMessageSent() {
    // メッセージ送信後の処理をここで行う（必要に応じて）
  }

  Widget _messageInput() {
    final isReceiving = ref.watch(
      isReceivingMessagesProvider(widget.cavivaraId),
    );
    final isSendUnavailable = _isMessageEmpty || isReceiving;

    return Container(
      padding: EdgeInsets.only(
        left: 16 + MediaQuery.of(context).viewPadding.left,
        top: 16,
        right: 16 + MediaQuery.of(context).viewPadding.right,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'メッセージを入力...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isSendUnavailable ? null : _sendMessage,
            tooltip: 'メッセージを送信',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              disabledBackgroundColor: Theme.of(
                context,
              ).colorScheme.surface,
            ),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageList extends ConsumerStatefulWidget {
  const _ChatMessageList({
    required this.controller,
    required this.onMessageSent,
    required this.cavivaraId,
  });

  final ScrollController controller;
  final VoidCallback onMessageSent;
  final String cavivaraId;

  @override
  ConsumerState<_ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends ConsumerState<_ChatMessageList> {
  bool _isAtBottom = true;
  int _previousMessageCount = 0;
  bool _previousHasStreamingMessages = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) {
      return;
    }

    final maxScrollExtent = widget.controller.position.maxScrollExtent;
    final currentPosition = widget.controller.position.pixels;
    const threshold = 100.0; // 100px以内なら「最下部」とみなす

    _isAtBottom = (maxScrollExtent - currentPosition) <= threshold;
  }

  void _scrollToBottom() {
    if (!widget.controller.hasClients) {
      return;
    }

    widget.controller.animateTo(
      widget.controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.cavivaraId));
    final hasStreamingMessages = messages.any(
      (ChatMessage message) => message.isStreaming,
    );

    // メッセージ数が増えた場合、またはストリーミングが終了した場合で、ユーザーが最下部にいる場合のみ自動スクロール
    final shouldAutoScroll =
        _isAtBottom &&
        (messages.length > _previousMessageCount ||
            (_previousHasStreamingMessages && !hasStreamingMessages));

    if (shouldAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    _previousMessageCount = messages.length;
    _previousHasStreamingMessages = hasStreamingMessages;

    if (messages.isEmpty) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: _ChatSuggestions(
          onSuggestionSelected: _sendSuggestion,
        ),
      );
    }

    return ListView.builder(
      controller: widget.controller,
      padding: EdgeInsets.only(
        left: 16 + MediaQuery.of(context).viewPadding.left,
        right: 16 + MediaQuery.of(context).viewPadding.right,
        top: 16,
        bottom: 8,
      ),
      itemCount: messages.length + 1, // サジェストリスト分を追加
      itemBuilder: (context, index) {
        // 最後のアイテムはサジェストリスト
        if (index == messages.length) {
          return _SuggestedReplySection(
            cavivaraId: widget.cavivaraId,
            onSuggestionTap: _sendSuggestion,
          );
        }

        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ChatBubble(
            message: message,
            cavivaraId: widget.cavivaraId,
          ),
        );
      },
    );
  }

  void _sendSuggestion(String message) {
    ref
        .read(chatMessagesProvider(widget.cavivaraId).notifier)
        .sendMessage(message);
    widget.onMessageSent();
  }
}

class _ChatBubble extends ConsumerWidget {
  const _ChatBubble({
    required this.message,
    required this.cavivaraId,
  });

  final ChatMessage message;
  final String cavivaraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (message.sender) {
      ChatMessageSenderUser() => _UserChatBubble(message: message),
      ChatMessageSenderAi() => _AiChatBubble(
        message: message,
        cavivaraId: cavivaraId,
      ),
      ChatMessageSenderApp() => _AppChatBubble(
        message: message,
      ),
    };
  }
}

class _ChatSuggestions extends StatelessWidget {
  const _ChatSuggestions({
    required this.onSuggestionSelected,
  });

  final ValueChanged<String> onSuggestionSelected;

  static const List<({IconData icon, String label})> _suggestions = [
    (
      icon: Icons.queue_music,
      label: 'マンドリンの演奏会の選曲会議で何を出すか迷っています',
    ),
    (
      icon: Icons.group,
      label: 'プレクトラム結社の最新の演奏会について教えて',
    ),
    (
      icon: Icons.restaurant_menu,
      label: '今晩の夜ご飯のレシピを考えて',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final title = Text(
      '質問してみましょう',
      style: Theme.of(context).textTheme.titleMedium,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 16 + MediaQuery.of(context).viewPadding.left,
              right: 16 + MediaQuery.of(context).viewPadding.right,
            ),
            child: title,
          ),
          SizedBox(
            height: 136,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              padding: EdgeInsets.only(
                left: 16 + MediaQuery.of(context).viewPadding.left,
                right: 16 + MediaQuery.of(context).viewPadding.right,
              ),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return _SuggestionCard(
                  icon: suggestion.icon,
                  label: suggestion.label,
                  onTap: () => onSuggestionSelected(suggestion.label),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemCount: _suggestions.length,
            ),
          ),
        ],
      ),
    );
  }
}

/// 動的サジェストセクション
class _SuggestedReplySection extends StatelessWidget {
  const _SuggestedReplySection({
    required this.cavivaraId,
    required this.onSuggestionTap,
  });

  final String cavivaraId;
  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return SuggestedReplyList(
      cavivaraId: cavivaraId,
      onSuggestionTap: onSuggestionTap,
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final indicatorIcon = Icon(
      icon,
      color: Theme.of(context).colorScheme.primary,
    );
    final bodyText = Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

    return SizedBox(
      width: 240,
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                indicatorIcon,
                bodyText,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserChatBubble extends ConsumerWidget {
  const _UserChatBubble({
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designAsync = ref.watch(chatBubbleDesignRepositoryProvider);
    final design = designAsync.value ?? ChatBubbleDesign.corporateStandard;

    final textColor = Theme.of(context).colorScheme.onPrimaryContainer;
    final bodyText = Text(
      message.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: textColor,
      ),
    );
    final timeText = _TimestampText(timestamp: message.timestamp);
    final bubbleColor = Theme.of(context).colorScheme.primaryContainer;
    final bubble = design.buildBubble(
      context: context,
      messageType: MessageType.user,
      backgroundColor: bubbleColor,
      child: bodyText,
    );

    final bubbleWithPointer = design.shouldWithPointer
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              bubble,
              Positioned(
                right: -10,
                top: 12,
                child: _BubblePointer(
                  color: bubbleColor,
                  direction: _BubblePointerDirection.right,
                ),
              ),
            ],
          )
        : bubble;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 4,
      children: [
        timeText,
        Skeletonizer(
          enabled: designAsync.isLoading,
          child: bubbleWithPointer,
        ),
      ],
    );
  }
}

class _AiChatBubble extends ConsumerWidget {
  const _AiChatBubble({
    required this.message,
    required this.cavivaraId,
  });

  final ChatMessage message;
  final String cavivaraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cavivaraProfile = ref.watch(cavivaraByIdProvider(cavivaraId));
    final designAsync = ref.watch(chatBubbleDesignRepositoryProvider);
    final design = designAsync.value ?? ChatBubbleDesign.corporateStandard;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final indicatorColor = Theme.of(context).colorScheme.primary;

    Widget bodyText;
    if (message.isStreaming && message.content.isEmpty) {
      bodyText = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${cavivaraProfile.displayName}が考え中…',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
            ),
          ),
        ],
      );
    } else {
      final textWidget = Text(
        message.content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
        ),
      );

      if (message.isStreaming) {
        bodyText = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: textWidget),
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              ),
            ),
          ],
        );
      } else {
        bodyText = textWidget;
      }
    }

    final timeText = _TimestampText(timestamp: message.timestamp);

    final bubbleColor = Theme.of(context).colorScheme.surfaceContainer;

    final bubble = design.buildBubble(
      context: context,
      messageType: MessageType.ai,
      backgroundColor: bubbleColor,
      child: bodyText,
    );

    final bubbleWithPointer = design.shouldWithPointer
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              bubble,
              Positioned(
                left: -10,
                top: 12,
                child: _BubblePointer(
                  color: bubbleColor,
                  direction: _BubblePointerDirection.left,
                ),
              ),
            ],
          )
        : bubble;

    final avatar = CavivaraAvatar(
      assetPath: cavivaraProfile.iconPath,
      cavivaraId: cavivaraId,
      onTap: () => Navigator.of(context).push(
        ResumeScreen.route(cavivaraId),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: 8),
          Flexible(
            child: Skeletonizer(
              enabled: designAsync.isLoading,
              child: bubbleWithPointer,
            ),
          ),
          if (!message.isStreaming || message.content.isNotEmpty) ...[
            const SizedBox(width: 4),
            Align(
              alignment: Alignment.bottomCenter,
              child: timeText,
            ),
          ],
        ],
      ),
    );
  }
}

class _AppChatBubble extends ConsumerWidget {
  const _AppChatBubble({
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designAsync = ref.watch(chatBubbleDesignRepositoryProvider);
    final design = designAsync.value ?? ChatBubbleDesign.corporateStandard;

    final bodyText = Text(
      message.content,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
      ),
    );
    final bubbleColor = Theme.of(
      context,
    ).colorScheme.surfaceContainer.withAlpha(100);
    final timeText = _TimestampText(
      timestamp: message.timestamp,
    );
    final bubble = design.buildBubble(
      context: context,
      messageType: MessageType.system,
      backgroundColor: bubbleColor,
      child: bodyText,
    );

    final expanded = Expanded(
      child: Skeletonizer(
        enabled: designAsync.isLoading,
        child: bubble,
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 4,
      children: [
        expanded,
        timeText,
      ],
    );
  }
}

class _TimestampText extends StatelessWidget {
  const _TimestampText({
    required this.timestamp,
  });

  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
      ),
    );
  }
}

enum _BubblePointerDirection { left, right }

class _BubblePointer extends StatelessWidget {
  const _BubblePointer({
    required this.color,
    required this.direction,
  });

  final Color color;
  final _BubblePointerDirection direction;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePointerPainter(
        color: color,
        direction: direction,
      ),
      size: const Size(10, 8),
    );
  }
}

class _BubblePointerPainter extends CustomPainter {
  _BubblePointerPainter({
    required this.color,
    required this.direction,
  });

  final Color color;
  final _BubblePointerDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path;
    switch (direction) {
      case _BubblePointerDirection.left:
        path = Path()
          ..moveTo(size.width, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height)
          ..close();
      case _BubblePointerDirection.right:
        path = Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height)
          ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePointerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.direction != direction;
  }
}
