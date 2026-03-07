import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/repository/first_message_bonus_repository.dart';
import 'package:house_worker/data/repository/has_earned_part_time_leader_reward_repository.dart';
import 'package:house_worker/data/repository/has_earned_part_timer_reward_repository.dart';
import 'package:house_worker/data/repository/received_chat_string_count_repository.dart';
import 'package:house_worker/data/repository/sent_chat_string_count_repository.dart';
import 'package:house_worker/data/repository/skip_clear_chat_confirmation_repository.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
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
          _ResetSentChatCountTile(),
          Divider(),
          SectionHeader(title: 'VP設定'),
          _ResetVPTile(),
          _SetVPToCustomValueTile(),
          _ResetFirstMessageBonusTile(),
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

class _ResetVPTile extends ConsumerWidget {
  const _ResetVPTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('VPをリセット (0に戻す)'),
      onTap: () async {
        await ref.read(vivaPointRepositoryProvider.notifier).reset();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('VPを0にリセットしました')),
          );
        }
      },
    );
  }
}

class _SetVPToCustomValueTile extends ConsumerWidget {
  const _SetVPToCustomValueTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentVP = ref.watch(vivaPointRepositoryProvider).asData?.value ?? 0;

    return ListTile(
      title: const Text('VPを任意の値に設定'),
      subtitle: Text('現在: $currentVP VP'),
      onTap: () => _showSetVPDialog(context, ref, currentVP),
    );
  }

  void _showSetVPDialog(BuildContext context, WidgetRef ref, int currentVP) {
    final controller = TextEditingController(text: currentVP.toString());

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('VPを設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'VP',
                hintText: '0以上の整数を入力',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickSetButton(label: '0', value: 0, controller: controller),
                _QuickSetButton(label: '9', value: 9, controller: controller),
                _QuickSetButton(label: '29', value: 29, controller: controller),
                _QuickSetButton(label: '69', value: 69, controller: controller),
                _QuickSetButton(
                  label: '149',
                  value: 149,
                  controller: controller,
                ),
                _QuickSetButton(
                  label: '299',
                  value: 299,
                  controller: controller,
                ),
                _QuickSetButton(
                  label: '500',
                  value: 500,
                  controller: controller,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              final value = int.tryParse(controller.text);
              if (value == null || value < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('0以上の整数を入力してください')),
                );
                return;
              }
              await ref
                  .read(vivaPointRepositoryProvider.notifier)
                  .setPoint(value);
              if (context.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('VPを$valueに設定しました')),
                );
              }
            },
            child: const Text('設定'),
          ),
        ],
      ),
    );
  }
}

class _ResetSentChatCountTile extends ConsumerWidget {
  const _ResetSentChatCountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('送信チャット文字数をリセット'),
      onTap: () async {
        await ref
            .read(sentChatStringCountRepositoryProvider.notifier)
            .resetForDebug();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('送信チャット文字数をリセットしました')),
          );
        }
      },
    );
  }
}

class _ResetFirstMessageBonusTile extends ConsumerWidget {
  const _ResetFirstMessageBonusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('初回メッセージボーナス受取状態をリセット'),
      onTap: () async {
        await ref
            .read(firstMessageBonusRepositoryProvider.notifier)
            .resetForDebug();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('初回メッセージボーナスをリセットしました')),
          );
        }
      },
    );
  }
}

class _QuickSetButton extends StatelessWidget {
  const _QuickSetButton({
    required this.label,
    required this.value,
    required this.controller,
  });

  final String label;
  final int value;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => controller.text = value.toString(),
      child: Text(label),
    );
  }
}
