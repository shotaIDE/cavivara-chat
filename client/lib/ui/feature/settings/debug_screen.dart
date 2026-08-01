import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/app_badge.dart';
import 'package:house_worker/data/model/remote_config_snapshot.dart';
import 'package:house_worker/data/repository/earned_badges_repository.dart';
import 'package:house_worker/data/repository/login_bonus_granted_dates_repository.dart';
import 'package:house_worker/data/repository/skip_clear_chat_confirmation_repository.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:house_worker/data/service/remote_config_service.dart';
import 'package:house_worker/ui/feature/code_scanner/badge_acquired_screen.dart';
import 'package:house_worker/ui/feature/code_scanner/code_scanner_presenter.dart';
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
          SectionHeader(title: 'VP設定'),
          _ResetVPTile(),
          _SetVPToCustomValueTile(),
          _ResetLoginBonusTile(),
          SectionHeader(title: 'バッジ設定'),
          _SimulatePlectrumConcertVol11Tile(),
          _ResetEarnedBadgesTile(),
          Divider(),
          SectionHeader(title: 'アカウント管理'),
          _LogoutTile(),
          _DeleteAccountTile(),
          Divider(),
          SectionHeader(title: 'Remote Config'),
          _RemoteConfigSection(),
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

class _ResetLoginBonusTile extends ConsumerWidget {
  const _ResetLoginBonusTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('ログインボーナスの付与状態をリセット'),
      onTap: () async {
        await ref
            .read(loginBonusGrantedDatesRepositoryProvider.notifier)
            .resetForDebug();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログインボーナスの付与状態をリセットしました')),
          );
        }
      },
    );
  }
}

class _SimulatePlectrumConcertVol11Tile extends ConsumerWidget {
  const _SimulatePlectrumConcertVol11Tile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('結社公演Vol.11の獲得画面に遷移 (バッジ付与)'),
      subtitle: const Text('二次元コードを読み取った場合と同じ処理を実行する'),
      onTap: () async {
        // 二次元コードの読み取りと同じ処理を実行し、バッジとVPを付与する。
        final result = await ref
            .read(codeScannerPresenterProvider.notifier)
            .handleScannedValue(plectrumConcertVol11CodeUrl);

        if (!context.mounted) {
          return;
        }

        switch (result) {
          case CodeScanResult.earnedNewBadge:
            await Navigator.of(context).push(
              BadgeAcquiredScreen.route(
                badge: AppBadge.plectrumConcertVol11,
                earnedVP: codeScanEventBonusVP,
              ),
            );
          case CodeScanResult.alreadyEarned:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('このバッジはすでに獲得済みです')),
            );
          case CodeScanResult.notMatched:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('対象の二次元コードではありません')),
            );
        }
      },
    );
  }
}

class _ResetEarnedBadgesTile extends ConsumerWidget {
  const _ResetEarnedBadgesTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('獲得済みバッジをリセット (獲得なしに戻す)'),
      onTap: () async {
        await ref.read(earnedBadgesRepositoryProvider.notifier).resetForDebug();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('獲得済みバッジをリセットしました')),
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

/// Remote Config の現在値を一覧表示するセクション
class _RemoteConfigSection extends ConsumerWidget {
  const _RemoteConfigSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(remoteConfigSnapshotProvider);
    if (snapshot == null) {
      return const ListTile(
        title: Text('値を取得できません'),
        subtitle: Text('Firebase の初期化に失敗している可能性がある'),
      );
    }

    // 見出しと左右の位置を揃えるため、SectionHeader と同じ余白の求め方をする
    final safeAreaLeftPadding = MediaQuery.of(context).padding.left;
    final safeAreaRightPadding = MediaQuery.of(context).padding.right;

    // 値は起動時に有効化されたものであり、公開直後の値は次回起動まで反映されない。
    // 「コンソールで公開したのに変わらない」と誤解しないよう明示する。
    final note = Padding(
      padding: EdgeInsets.only(
        left: safeAreaLeftPadding > 0 ? safeAreaLeftPadding : 16.0,
        right: safeAreaRightPadding > 0 ? safeAreaRightPadding : 16.0,
      ),
      child: Text(
        '表示しているのは起動時に有効化された値です。公開直後の値を確認するにはアプリを再起動してください。',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        note,
        _RemoteConfigFetchStateTile(snapshot: snapshot),
        for (final parameter in snapshot.parameters)
          _RemoteConfigParameterTile(parameter: parameter),
      ],
    );
  }
}

class _RemoteConfigFetchStateTile extends StatelessWidget {
  const _RemoteConfigFetchStateTile({required this.snapshot});

  final RemoteConfigSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final stateLabel = switch (snapshot.lastFetchState) {
      RemoteConfigFetchState.notFetchedYet => '未フェッチ',
      RemoteConfigFetchState.success => '成功',
      RemoteConfigFetchState.failure => '失敗',
      RemoteConfigFetchState.throttled => 'レート制限',
    };

    final lastFetchTime = snapshot.lastFetchTime;
    final timeLabel = lastFetchTime == null
        ? 'なし'
        : _formatDateTime(lastFetchTime);

    return ListTile(
      title: const Text('最終フェッチ'),
      subtitle: Text('$stateLabel（$timeLabel）'),
    );
  }
}

class _RemoteConfigParameterTile extends StatelessWidget {
  const _RemoteConfigParameterTile({required this.parameter});

  final RemoteConfigParameter parameter;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = _sourceLabel(parameter.source);
    final valueLabel = parameter.value.isEmpty
        ? '(空)'
        : _toSingleLine(parameter.value);

    return ListTile(
      title: Text(parameter.key.name),
      subtitle: Text(
        '$sourceLabel / $valueLabel',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showValueDialog(context),
    );
  }

  void _showValueDialog(BuildContext context) {
    final value = parameter.value;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(parameter.key.name),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  '取得元: ${_sourceLabel(parameter.source)}',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                SelectableText(value.isEmpty ? '(空)' : value),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            // 値が空の場合はコピーする内容がないため押せないようにする
            onPressed: value.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('値をコピーしました')),
                    );
                  },
            child: const Text('コピー'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

String _sourceLabel(RemoteConfigValueSource source) {
  return switch (source) {
    RemoteConfigValueSource.remote => 'Remote Config',
    RemoteConfigValueSource.appDefault => 'アプリ既定値',
    RemoteConfigValueSource.notSet => '未設定',
  };
}

final _consecutiveWhitespacePattern = RegExp(r'\s+');

/// 改行を含む値を一覧に収めるため、連続する空白を 1 つにまとめて 1 行にする
String _toSingleLine(String value) {
  return value.replaceAll(_consecutiveWhitespacePattern, ' ').trim();
}

String _formatDateTime(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final second = dateTime.second.toString().padLeft(2, '0');

  return '${dateTime.year}/$month/$day $hour:$minute:$second';
}
