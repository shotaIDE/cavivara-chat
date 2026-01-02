import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/user_profile.dart';
import 'package:house_worker/data/repository/has_earned_part_time_leader_reward_repository.dart';
import 'package:house_worker/data/repository/has_earned_part_timer_reward_repository.dart';
import 'package:house_worker/data/repository/received_chat_string_count_repository.dart';
import 'package:house_worker/data/repository/skip_clear_chat_confirmation_repository.dart';
import 'package:house_worker/data/service/auth_service.dart';
import 'package:house_worker/ui/feature/settings/section_header.dart';
import 'package:house_worker/ui/root_presenter.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  static const name = 'DebugScreen';

  static MaterialPageRoute<DebugScreen> route() =>
      MaterialPageRoute<DebugScreen>(
        builder: (_) => const DebugScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('デバッグ')),
      body: userProfileAsync.when(
        data: (userProfile) {
          return ListView(
            children: [
              const SectionHeader(title: 'Crashlytics'),
              const _ForceErrorTile(),
              const _ForceCrashTile(),
              const SectionHeader(title: '設定リセット'),
              const _ResetConfirmationSettingsTile(),
              const SectionHeader(title: '統計設定'),
              const _ResetReceivedChatCountAndAchievementsTile(),
              const _SetReceivedChatCountTo999Tile(),
              const _SetReceivedChatCountTo9999Tile(),
              const Divider(),
              const SectionHeader(title: 'アカウント管理'),
              _LogoutTile(ref: ref),
              if (userProfile != null)
                _DeleteAccountTile(ref: ref, userProfile: userProfile),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
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

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('ログアウト', style: TextStyle(color: Colors.red)),
      onTap: () => _showLogoutConfirmDialog(context, ref),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('本当にログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signOut();
                await ref.read(currentAppSessionProvider.notifier).signOut();
              } on Exception catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
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

class _DeleteAccountTile extends StatelessWidget {
  const _DeleteAccountTile({
    required this.ref,
    required this.userProfile,
  });

  final WidgetRef ref;
  final UserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('アカウントを削除', style: TextStyle(color: Colors.red)),
      onTap: () => _showDeleteAccountConfirmDialog(context, ref, userProfile),
    );
  }

  void _showDeleteAccountConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile userProfile,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アカウント削除'),
        content: const Text('本当にアカウントを削除しますか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              try {
                // Firebase認証からのサインアウト
                await ref.read(authServiceProvider).signOut();
                await ref.read(currentAppSessionProvider.notifier).signOut();
              } on Exception catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
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
