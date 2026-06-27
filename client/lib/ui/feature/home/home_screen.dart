import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/chat_bubble_design.dart';
import 'package:house_worker/data/model/chat_message.dart';
import 'package:house_worker/data/repository/skip_clear_chat_confirmation_repository.dart';
import 'package:house_worker/data/service/cavivara_profile_service.dart';
import 'package:house_worker/ui/component/animated_cavivara.dart';
import 'package:house_worker/ui/component/app_drawer.dart';
import 'package:house_worker/ui/component/cat_fur_bubble_painter.dart';
import 'package:house_worker/ui/component/chat_bubble_design_extension.dart';
import 'package:house_worker/ui/component/clear_chat_confirmation_dialog.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';
import 'package:house_worker/ui/component/suggested_reply_list.dart';
import 'package:house_worker/ui/feature/home/home_presenter.dart';
import 'package:house_worker/ui/feature/qr_scanner/qr_scanner_screen.dart';
import 'package:house_worker/ui/feature/settings/settings_screen.dart';
import 'package:house_worker/ui/feature/stats/badge_acquired_dialog.dart';
import 'package:house_worker/ui/feature/stats/user_statistics_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// スクロール位置が最下部付近かどうかを判定するピクセル単位のしきい値。
///
/// `maxScrollExtent - pixels` がこの値以下であれば「最下部付近」とみなす。
/// `_HomeScreenState._onMessageSent()` と `_ChatMessageListState._onScroll()` の
/// 両方で使用するため、ここで一元管理する。
const _scrollAtBottomThresholdSize = 100.0;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const name = 'HomeScreen';

  static MaterialPageRoute<HomeScreen> route() => MaterialPageRoute<HomeScreen>(
    builder: (_) => const HomeScreen(),
    settings: const RouteSettings(name: name),
  );

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// 画面表示時に内容が下からぬるっと浮き上がる入場アニメーションにかける時間。
  static const _entranceDuration = Duration(milliseconds: 700);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isMessageEmpty = true;
  bool _shouldShowSuggestions = false;
  Timer? _suggestionTimer;

  /// ログインボーナスがすでに有効化済みかどうか。
  ///
  /// バッジダイアログの表示後にログインボーナスを開始するため、重複起動を防ぐフラグ。
  bool _dailyBonusActivated = false;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    _messageController.addListener(_onMessageChanged);
    _messageFocusNode.addListener(_onFocusChanged);

    // 画面表示時に内容を下からぬるっと浮き上がらせる。
    _entranceController = AnimationController(
      vsync: this,
      duration: _entranceDuration,
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(_entranceFade);
    _entranceController.forward();

    // ビルド完了後にテキストフィールドにフォーカスしてキーボードを表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _messageFocusNode.requestFocus();
    });

    ref
      ..listenManual(awardFirstMessageBonusProvider, (_, _) {
        // Providerの副作用のみを利用するため、何もしない
      })
      // バッジダイアログ → ログインボーナス通知の順に表示するため、
      // ログインボーナスの有効化はバッジダイアログを閉じた後まで遅延させる。
      ..listenManual(awardFirstLaunchBadgeProvider, (_, next) {
        next.whenOrNull(
          data: (badge) {
            if (badge != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) {
                  return;
                }
                try {
                  await BadgeAcquiredDialog.show(context, earnedBadge: badge);
                } finally {
                  if (mounted) {
                    _activateDailyBonusIfNeeded();
                  }
                }
              });
            } else {
              _activateDailyBonusIfNeeded();
            }
          },
          error: (_, _) {
            _activateDailyBonusIfNeeded();
          },
        );
      });
  }

  /// ログインボーナスプロバイダーを有効化する（重複起動防止）
  void _activateDailyBonusIfNeeded() {
    if (_dailyBonusActivated) {
      return;
    }
    _dailyBonusActivated = true;
    ref.listenManual(awardDailyLoginBonusProvider, (_, _) {
      // Providerの副作用のみを利用するため、何もしない
    });
  }

  void _onFocusChanged() {
    if (_messageFocusNode.hasFocus) {
      // フォーカスが当たったら少し遅延してからサジェストを表示
      _suggestionTimer?.cancel();
      _suggestionTimer = Timer(const Duration(seconds: 1), () {
        if (mounted && _messageFocusNode.hasFocus) {
          setState(() {
            _shouldShowSuggestions = true;
          });
        }
      });
    } else {
      // フォーカスが外れたらタイマーをキャンセル
      _suggestionTimer?.cancel();
      _suggestionTimer = null;
    }
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
  void dispose() {
    _entranceController.dispose();
    _suggestionTimer?.cancel();
    _messageController
      ..removeListener(_onMessageChanged)
      ..dispose();
    _scrollController.dispose();
    _messageFocusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cavivaraProfile = ref.watch(cavivaraProfileProvider);

    final title = Row(
      children: [
        Semantics(
          label: 'カヴィヴァラさんのアイコン',
          image: true,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Transform.flip(
              flipX: true,
              child: AnimatedCavivara(
                strokeColor: Theme.of(context).colorScheme.onSurface,
                // 輪郭内側を吹き出し横のアイコンと同じ最内層グレーで塗る。
                fillColor: CatFurBubblePainter.innerSilhouetteColor(
                  Theme.of(context).brightness,
                ),
                // 画面上で約1.2px相当の線になるよう、表示サイズ(48)から
                // ソース画像座標系(幅2308)へ換算する。
                strokeWidth: 1.2 * 2308 / 48,
              ),
            ),
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

    // キーボードの表示によるビューポートの縮小量を取得する。
    // Scaffold の body 内では resizeToAvoidBottomInset により viewInsets.bottom が
    // 取り除かれてしまうため、Scaffold より上位のこのコンテキストで取得して渡す。
    final viewInsetBottom = MediaQuery.of(context).viewInsets.bottom;

    final body = Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismissKeyboard,
            child: _ChatMessageList(
              controller: _scrollController,
              onMessageSent: _onMessageSent,
              shouldShowSuggestions: _shouldShowSuggestions,
              viewInsetBottom: viewInsetBottom,
            ),
          ),
        ),
        _messageInput(),
      ],
    );

    final scaffold = Scaffold(
      appBar: AppBar(
        title: title,
        actions: [clearButton],
      ),
      drawer: AppDrawer(
        isTalkSelected: true,
        isAchievementSelected: false,
        onSelectTalk: () {
          Navigator.of(context).pushAndRemoveUntil(
            HomeScreen.route(),
            (route) => false,
          );
        },
        onSelectAchievement: () {
          Navigator.of(context).pushAndRemoveUntil(
            UserStatisticsScreen.route(),
            (route) => false,
          );
        },
        onSelectCamera: () {
          Navigator.of(context).push(QrScannerScreen.route());
        },
        onSelectSettings: () {
          Navigator.of(context).push(SettingsScreen.route());
        },
      ),
      // ドロワーを開く際にキーボードを非表示にする。
      // これにより、ドロワーを閉じた後にフォーカスが復元されてキーボードが
      // 意図せず表示されることを防ぐ。
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _dismissKeyboard();
        }
      },
      body: body,
    );

    // タイトルバーを含む画面全体を、下からぬるっと浮き上がらせる。
    return FadeTransition(
      opacity: _entranceFade,
      child: SlideTransition(
        position: _entranceSlide,
        child: scaffold,
      ),
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

    HapticFeedbackHelper.onClearChat();
    ref.read(chatMessagesProvider.notifier).clearMessages();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      HapticFeedbackHelper.onMessageSent();
      ref.read(chatMessagesProvider.notifier).sendMessage(message);
      _messageController.clear();
      _onMessageSent();
    }
  }

  void _dismissKeyboard() {
    // メッセージ入力欄の FocusNode 自体を unfocus する。
    //
    // FocusScope.of(context).unfocus() ではフォーカススコープの親側の
    // _focusedChildren しかクリアされず、TextField はスコープの
    // _focusedChildren に残り続ける。そのためドロワーを閉じた際に
    // フォーカスが復元され、キーボードが意図せず再表示されてしまう。
    // FocusNode を直接 unfocus することでスコープから確実に除去する。
    _messageFocusNode.unfocus();
  }

  void _onMessageSent() {
    if (!_scrollController.hasClients) {
      return;
    }

    // 送信前の時点ですでに最下部付近にいる場合は、_ChatMessageList 側の
    // メッセージ増加に伴う自動スクロールに委ね、animateTo の二重実行を避ける。
    // この判定は新メッセージのレイアウト前（リビルド前）に同期的に行う必要がある。
    // post-frame まで遅らせると maxScrollExtent が増加し、判定が壊れるため。
    final position = _scrollController.position;
    final isAtBottom =
        (position.maxScrollExtent - position.pixels) <=
        _scrollAtBottomThresholdSize;
    if (isAtBottom) {
      return;
    }

    // 最下部から離れている場合は、送信したメッセージとカヴィヴァラさんの
    // ローディング中メッセージが見えるよう、明示的に最下部へスクロールする。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
      );
    });
  }

  Widget _messageInput() {
    final isReceiving = ref.watch(isReceivingMessagesProvider);
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
              focusNode: _messageFocusNode,
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
    required this.shouldShowSuggestions,
    required this.viewInsetBottom,
  });

  final ScrollController controller;
  final VoidCallback onMessageSent;
  final bool shouldShowSuggestions;

  /// キーボードの表示によるビューポート下部の縮小量。
  ///
  /// Scaffold の body 内では resizeToAvoidBottomInset により MediaQuery の
  /// viewInsets.bottom が 0 に置き換えられるため、上位コンテキストの値を受け取る。
  final double viewInsetBottom;

  @override
  ConsumerState<_ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends ConsumerState<_ChatMessageList> {
  bool _isAtBottom = true;
  int _previousMessageCount = 0;
  bool _previousHasStreamingMessages = false;
  bool _previousStreamingMessageHadContent = false;
  double _previousViewInsetBottom = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.controller.hasClients) {
      return;
    }

    final maxScrollExtent = widget.controller.position.maxScrollExtent;
    final currentPosition = widget.controller.position.pixels;

    _isAtBottom =
        (maxScrollExtent - currentPosition) <= _scrollAtBottomThresholdSize;
  }

  void _scrollToBottom() {
    if (!widget.controller.hasClients) {
      return;
    }

    widget.controller.animateTo(
      widget.controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final hasStreamingMessages = messages.any(
      (ChatMessage message) => message.isStreaming,
    );

    // ストリーミング中のメッセージがコンテンツを持っているかどうか
    final streamingMessageHasContent = messages.any(
      (ChatMessage message) =>
          message.isStreaming && message.content.isNotEmpty,
    );

    // コンテンツ受信開始を検知（前回コンテンツなし→今回コンテンツあり）
    final isContentReceiveStarted =
        !_previousStreamingMessageHadContent && streamingMessageHasContent;
    // ストリーミング完了を検知（前回あり→今回なし）
    final isStreamingCompleted =
        _previousHasStreamingMessages && !hasStreamingMessages;
    // ストリーミング完了時に初めてコンテンツを受信した場合を検知
    // （ストリーミング中にコンテンツが一度も表示されず、完了時に初めて表示された場合）
    final isContentReceivedOnCompletion =
        isStreamingCompleted && !_previousStreamingMessageHadContent;

    // Haptic Feedbackを発生させる
    // 両者が同時のタイミングだったら、2回振動を優先させる
    if (isContentReceiveStarted || isContentReceivedOnCompletion) {
      unawaited(HapticFeedbackHelper.onMessageReceiveStart());
    } else if (isStreamingCompleted) {
      HapticFeedbackHelper.onMessageReceiveComplete();
    }

    // キーボードが表示されて画面が縮小したことを検知する。
    // 上位コンテキストから受け取った viewInsetBottom が増加したタイミングが
    // キーボードの出現に対応する。
    // Scaffold の resizeToAvoidBottomInset によりビューポートが縮小するが、
    // ListView のスクロール位置は自動調整されないため、明示的に最下部へ移動する必要がある。
    final currentViewInsetBottom = widget.viewInsetBottom;
    final isKeyboardAppearing =
        currentViewInsetBottom > _previousViewInsetBottom;
    _previousViewInsetBottom = currentViewInsetBottom;

    // メッセージ数が増えた場合、ストリーミングが終了した場合、またはキーボードが表示された場合で、
    // ユーザーが最下部にいる場合のみ自動スクロール
    final shouldAutoScroll =
        _isAtBottom &&
        (messages.length > _previousMessageCount ||
            isStreamingCompleted ||
            isKeyboardAppearing);

    if (shouldAutoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }

    _previousMessageCount = messages.length;
    _previousHasStreamingMessages = hasStreamingMessages;
    _previousStreamingMessageHadContent = streamingMessageHasContent;

    if (messages.isEmpty) {
      if (!widget.shouldShowSuggestions) {
        return const SizedBox.shrink();
      }
      return Align(
        alignment: Alignment.bottomCenter,
        child: _ChatSuggestions(
          onSuggestionSelected: _sendSuggestion,
        ),
      );
    }

    return ListView.builder(
      controller: widget.controller,
      itemCount: messages.length + 1, // サジェストリスト分を追加
      itemBuilder: (context, index) {
        // 最後のアイテムはサジェストリスト。
        // 上下の余白は SuggestedReplyList が内部で持つため、サジェストが
        // 存在しないときは余白も発生しない。
        if (index == messages.length) {
          return SuggestedReplyList(
            onSuggestionTap: _sendSuggestion,
          );
        }

        final message = messages[index];
        // カヴィヴァラさん(AI)の発言は猫毛様式で毛先がはみ出すため、
        // 上下の余白を広めに確保する。
        final verticalPadding = message.sender is ChatMessageSenderAi
            ? 16.0
            : 8.0;
        return Padding(
          padding: EdgeInsets.only(
            left: 16 + MediaQuery.of(context).viewPadding.left,
            right: 16 + MediaQuery.of(context).viewPadding.right,
            top: verticalPadding,
            bottom: verticalPadding,
          ),
          child: _ChatBubble(
            message: message,
          ),
        );
      },
    );
  }

  void _sendSuggestion(String message) {
    HapticFeedbackHelper.onSuggestionTap();
    ref.read(chatMessagesProvider.notifier).sendMessage(message);
    widget.onMessageSent();
  }
}

class _ChatBubble extends ConsumerWidget {
  const _ChatBubble({
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (message.sender) {
      ChatMessageSenderUser() => _UserChatBubble(message: message),
      ChatMessageSenderAi() => _AiChatBubble(
        message: message,
      ),
      ChatMessageSenderApp() => _AppChatBubble(
        message: message,
      ),
    };
  }
}

class _ChatSuggestions extends StatefulWidget {
  const _ChatSuggestions({
    required this.onSuggestionSelected,
  });

  final ValueChanged<String> onSuggestionSelected;

  @override
  State<_ChatSuggestions> createState() => _ChatSuggestionsState();
}

class _ChatSuggestionsState extends State<_ChatSuggestions>
    with SingleTickerProviderStateMixin {
  static const List<({IconData icon, String label})> _allSuggestions = [
    // カヴィヴァラ・マンドリン関連
    (
      icon: Icons.queue_music,
      label: 'マンドリンの演奏会の選曲会議で何を出すか迷っているヴィヴァ',
    ),
    (
      icon: Icons.group,
      label: 'プレクトラム結社の最新の演奏会について教えて',
    ),
    (
      icon: Icons.music_note,
      label: 'マンドリンの練習方法を教えてヴィヴァ',
    ),
    (
      icon: Icons.library_music,
      label: 'マンドリンオーケストラのおすすめ曲は？',
    ),
    (
      icon: Icons.piano,
      label: 'トレモロを綺麗に弾くコツを教えて',
    ),
    (
      icon: Icons.event,
      label: '演奏会のプログラム構成のアドバイスをくださいヴィヴァ',
    ),
    (
      icon: Icons.headphones,
      label: 'マンドリンの歴史について教えて',
    ),
    (
      icon: Icons.build,
      label: 'マンドリンの弦の張り替え方を教えて',
    ),
    (
      icon: Icons.album,
      label: 'イタリアのマンドリン曲でおすすめは？',
    ),
    (
      icon: Icons.people,
      label: 'アンサンブルで合わせるコツを教えてヴィヴァ',
    ),
    // 一般的な質問
    (
      icon: Icons.restaurant_menu,
      label: '今晩の夜ご飯のレシピを考えて',
    ),
    (
      icon: Icons.flight_takeoff,
      label: '週末のお出かけスポットを教えてヴィヴァ',
    ),
    (
      icon: Icons.fitness_center,
      label: '家でできる簡単なストレッチを教えて',
    ),
    (
      icon: Icons.book,
      label: 'おすすめの本を紹介して',
    ),
    (
      icon: Icons.lightbulb,
      label: '集中力を高める方法を教えて',
    ),
    (
      icon: Icons.wb_sunny,
      label: '朝のルーティンのおすすめを教えてヴィヴァ',
    ),
    (
      icon: Icons.movie,
      label: '最近観た映画のおすすめを教えて',
    ),
    (
      icon: Icons.language,
      label: '効果的な語学学習の方法を教えて',
    ),
    (
      icon: Icons.coffee,
      label: 'リラックスできる休日の過ごし方は？',
    ),
    (
      icon: Icons.work,
      label: '仕事の効率を上げるコツを教えてヴィヴァ',
    ),
  ];

  /// 表示するサジェストの数
  static const _displayCount = 3;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final List<({IconData icon, String label})> _selectedSuggestions;

  @override
  void initState() {
    super.initState();

    // ランダムに3つのサジェストをピックアップ
    final random = Random();
    final shuffled = List.of(_allSuggestions)..shuffle(random);
    _selectedSuggestions = shuffled.take(_displayCount).toList();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // 表示されたら即座にアニメーション開始
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(
      '質問してみましょう',
      style: Theme.of(context).textTheme.titleMedium,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
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
                  final suggestion = _selectedSuggestions[index];
                  return _SuggestionCard(
                    icon: suggestion.icon,
                    label: suggestion.label,
                    onTap: () => widget.onSuggestionSelected(suggestion.label),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemCount: _selectedSuggestions.length,
              ),
            ),
          ],
        ),
      ),
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
          onTap: () {
            HapticFeedbackHelper.onSuggestionTap();
            onTap();
          },
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

class _UserChatBubble extends StatelessWidget {
  const _UserChatBubble({
    required this.message,
  });

  /// ユーザーの発言は社内標準様式で表示する。
  static const ChatBubbleDesign _design = ChatBubbleDesign.corporateStandard;

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bodyText = Text(
      message.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
    final bubbleColor = Theme.of(context).colorScheme.primaryContainer;
    final bubble = _design.buildBubble(
      context: context,
      backgroundColor: bubbleColor,
      child: bodyText,
      seed: message.id.hashCode,
    );

    final bubbleWithPointer = _design.shouldWithPointer
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
        bubbleWithPointer,
      ],
    );
  }
}

class _AiChatBubble extends ConsumerWidget {
  const _AiChatBubble({
    required this.message,
  });

  final ChatMessage message;

  /// カヴィヴァラさん(AI)の発言は毛並み(猫毛様式)で表示する。
  static const ChatBubbleDesign _design = ChatBubbleDesign.catFur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cavivaraProfile = ref.watch(cavivaraProfileProvider);
    final textColor = CatFurBubblePainter.recommendedForegroundColor(
      Theme.of(context).brightness,
    );
    final indicatorColor = Theme.of(context).colorScheme.primary;

    Widget bodyText;
    if (message.isStreaming && message.content.isEmpty) {
      // 考え中は、返答を生成している様子を文字列のスケルトンで表現する。
      final skeletonTextStyle = Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: textColor);
      bodyText = Skeletonizer(
        child: Text(
          '${cavivaraProfile.displayName}が考えています',
          style: skeletonTextStyle,
        ),
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

    final bubbleColor = Theme.of(context).colorScheme.surfaceContainer;

    final bubble = _design.buildBubble(
      context: context,
      backgroundColor: bubbleColor,
      child: bodyText,
      seed: message.id.hashCode,
    );

    final bubbleWithPointer = _design.shouldWithPointer
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

    final avatar = Semantics(
      label: 'カヴィヴァラさんのアイコン',
      image: true,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Transform.flip(
          flipX: true,
          child: AnimatedCavivara(
            strokeColor: Theme.of(context).colorScheme.onSurface,
            // 輪郭内側を吹き出しの最内層グレーと同じ色で塗りつぶす。
            fillColor: CatFurBubblePainter.innerSilhouetteColor(
              Theme.of(context).brightness,
            ),
            // 画面上で約1.2px相当の線になるよう、表示サイズ(56)から
            // ソース画像座標系(幅2308)へ換算する。
            strokeWidth: 1.2 * 2308 / 56,
          ),
        ),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(width: 8),
          Flexible(
            // アイコンに対して吹き出しを少し下げつつ、上下の余白を揃える。
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: bubbleWithPointer,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppChatBubble extends StatelessWidget {
  const _AppChatBubble({
    required this.message,
  });

  /// アプリ(システム)の発言は社内標準様式で表示する。
  static const ChatBubbleDesign _design = ChatBubbleDesign.corporateStandard;

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bodyText = Text(
      message.content,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
      ),
    );
    final bubbleColor = Theme.of(
      context,
    ).colorScheme.surfaceContainer.withAlpha(100);
    final bubble = _design.buildBubble(
      context: context,
      backgroundColor: bubbleColor,
      child: bodyText,
      seed: message.id.hashCode,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 4,
      children: [
        Expanded(child: bubble),
      ],
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
