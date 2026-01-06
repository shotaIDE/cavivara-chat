import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/repository/has_earned_part_time_leader_reward_repository.dart';
import 'package:house_worker/data/repository/has_earned_part_timer_reward_repository.dart';
import 'package:house_worker/data/repository/received_chat_string_count_repository.dart';
import 'package:house_worker/data/repository/skip_clear_chat_confirmation_repository.dart';
import 'package:house_worker/ui/feature/settings/debug_presenter.dart';
import 'package:house_worker/ui/feature/settings/section_header.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  static const name = 'DebugScreen';

  static MaterialPageRoute<DebugScreen> route() =>
      MaterialPageRoute<DebugScreen>(
        builder: (_) => const DebugScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('デバッグ')),
      body: ListView(
        children: const [
          SectionHeader(title: 'Crashlytics'),
          _ForceErrorTile(),
          _ForceCrashTile(),
          SectionHeader(title: '設定リセット'),
          _ResetConfirmationSettingsTile(),
          SectionHeader(title: '統計設定'),
          _ResetReceivedChatCountAndAchievementsTile(),
          _SetReceivedChatCountTo999Tile(),
          _SetReceivedChatCountTo9999Tile(),
          Divider(),
          SectionHeader(title: 'アカウント管理'),
          _LogoutTile(),
          _DeleteAccountTile(),
        ],
      ),
    );
  }
}

class _ForceCrashTile extends StatelessWidget {
  const _ForceCrashTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('強制クラッシュ'),
      onTap: () => FirebaseCrashlytics.instance.crash(),
    );
  }
}

class _ForceErrorTile extends StatelessWidget {
  const _ForceErrorTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(title: const Text('強制エラー'), onTap: () => throw Exception());
  }
}

class _ResetConfirmationSettingsTile extends ConsumerWidget {
  const _ResetConfirmationSettingsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('記憶消去の確認ダイアログの設定をリセット'),
      onTap: () async {
        await ref
            .read(skipClearChatConfirmationProvider.notifier)
            .resetForDebug();
      },
    );
  }
}

class _ResetReceivedChatCountAndAchievementsTile extends ConsumerWidget {
  const _ResetReceivedChatCountAndAchievementsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('受信チャット文字数と称号をリセット'),
      onTap: () async {
        await ref
            .read(receivedChatStringCountRepositoryProvider.notifier)
            .resetForDebug();
        await ref
            .read(hasEarnedPartTimeLeaderRewardRepositoryProvider.notifier)
            .resetForDebug();
        await ref
            .read(hasEarnedPartTimerRewardRepositoryProvider.notifier)
            .resetForDebug();
      },
    );
  }
}

class _SetReceivedChatCountTo999Tile extends ConsumerWidget {
  const _SetReceivedChatCountTo999Tile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('受信チャット文字数を999にする'),
      onTap: () async {
        await ref
            .read(receivedChatStringCountRepositoryProvider.notifier)
            .setForDebug(999);
      },
    );
  }
}

class _SetReceivedChatCountTo9999Tile extends ConsumerWidget {
  const _SetReceivedChatCountTo9999Tile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('受信チャット文字数を9999にする'),
      onTap: () async {
        await ref
            .read(receivedChatStringCountRepositoryProvider.notifier)
            .setForDebug(9999);
      },
    );
  }
}

class _LogoutTile extends ConsumerWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debugPresenterProvider);
    final isProcessing = state.maybeMap(
      loading: (_) => true,
      orElse: () => false,
    );
    final isEnabled =
        state.asData?.value.maybeWhen(
          hasProfile: (_) => true,
          orElse: () => false,
        ) ??
        false;

    return Skeletonizer(
      enabled: isProcessing,
      child: ListTile(
        leading: Icon(
          Icons.logout,
          color: isEnabled ? Colors.red : Colors.grey,
        ),
        title: Text(
          'ログアウト',
          style: TextStyle(color: isEnabled ? Colors.red : Colors.grey),
        ),
        enabled: isEnabled,
        onTap: isEnabled ? () => _showLogoutConfirmDialog(context, ref) : null,
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('本当にログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(debugPresenterProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ログアウトに失敗しました: $e')),
                  );
                }
              }
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountTile extends ConsumerWidget {
  const _DeleteAccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debugPresenterProvider);
    final isProcessing = state.maybeMap(
      loading: (_) => true,
      orElse: () => false,
    );
    final enabled =
        state.asData?.value.maybeWhen(
          hasProfile: (_) => true,
          orElse: () => false,
        ) ??
        false;

    return Skeletonizer(
      enabled: isProcessing,
      child: ListTile(
        leading: Icon(
          Icons.delete_forever,
          color: enabled ? Colors.red : Colors.grey,
        ),
        title: Text(
          'アカウントを削除',
          style: TextStyle(color: enabled ? Colors.red : Colors.grey),
        ),
        enabled: enabled,
        onTap: enabled
            ? () => _showDeleteAccountConfirmDialog(context, ref)
            : null,
      ),
    );
  }

  void _showDeleteAccountConfirmDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('アカウント削除'),
        content: const Text('本当にアカウントを削除しますか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(debugPresenterProvider.notifier).deleteAccount();
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('アカウント削除に失敗しました: $e')),
                  );
                }
              }
            },
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }
}
