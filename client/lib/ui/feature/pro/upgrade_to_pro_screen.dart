import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/purchase_exception.dart';
import 'package:house_worker/data/service/purchase_pro_result.dart';

class UpgradeToProScreen extends ConsumerStatefulWidget {
  const UpgradeToProScreen({super.key});

  static const name = 'UpgradeToProScreen';

  static MaterialPageRoute<UpgradeToProScreen> route() =>
      MaterialPageRoute<UpgradeToProScreen>(
        builder: (_) => const UpgradeToProScreen(),
        settings: const RouteSettings(name: name),
        fullscreenDialog: true,
      );

  @override
  ConsumerState<UpgradeToProScreen> createState() => _UpgradeToProScreenState();
}

class _UpgradeToProScreenState extends ConsumerState<UpgradeToProScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pro版にアップグレード')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24 + MediaQuery.of(context).viewPadding.left,
          top: 24,
          right: 24 + MediaQuery.of(context).viewPadding.right,
          bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.workspace_premium,
                size: 80,
                color: Colors.amber,
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: Text(
                'Pro版の特典',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 32),
            _FeatureItem(
              icon: Icons.check_circle,
              title: '家事の登録件数が無制限に',
              description: 'フリー版では最大10件までの家事しか登録できませんが、Pro版では無制限に登録できます。',
            ),
            SizedBox(height: 16),
            _FeatureItem(
              icon: Icons.lock_clock,
              title: '今後追加される機能も使い放題',
              description: '今後追加される有料機能もすべて使えるようになります。',
              isComingSoon: true,
            ),
            SizedBox(height: 32),
            Center(
              child: Text(
                '¥980（買い切り）',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                '一度購入すれば永続的に利用可能',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            SizedBox(height: 32),
            _PurchaseButton(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    this.isComingSoon = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: isComingSoon
              ? Theme.of(context).colorScheme.onSurface.withAlpha(100)
              : Colors.green,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isComingSoon
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(100)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (isComingSoon) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '近日公開',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(100),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: isComingSoon
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(100)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchaseButton extends ConsumerStatefulWidget {
  const _PurchaseButton();

  @override
  ConsumerState<_PurchaseButton> createState() => _PurchaseButtonState();
}

class _PurchaseButtonState extends ConsumerState<_PurchaseButton> {
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(purchaseProResultProvider).isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _purchasePro,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Pro版を購入する', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _purchasePro() async {
    final bool isSucceeded;
    try {
      isSucceeded = await ref
          .read(purchaseProResultProvider.notifier)
          .purchasePro();
    } on PurchaseException catch (e) {
      e.when(
        cancelled: () {
          // ユーザーによるキャンセルは静かに処理
        },
        uncategorized: () {
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('購入処理中にエラーが発生しました')));
        },
      );
      return;
    }

    if (!mounted) {
      return;
    }

    if (!isSucceeded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('購入がキャンセルされました')));

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pro版へのアップグレードが完了しました！')));

    Navigator.of(context).pop(true);
  }
}
