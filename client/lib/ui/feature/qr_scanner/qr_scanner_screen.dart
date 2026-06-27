import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/data/model/app_badge.dart';
import 'package:house_worker/ui/component/haptic_feedback_helper.dart';
import 'package:house_worker/ui/feature/qr_scanner/badge_acquired_screen.dart';
import 'package:house_worker/ui/feature/qr_scanner/qr_scanner_presenter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QRコードを読み取る画面。
///
/// イベント会場のQRコードを読み取り、対象のURLと一致した場合にバッジとVPを付与する。
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  static const name = 'QrScannerScreen';

  static MaterialPageRoute<QrScannerScreen> route() =>
      MaterialPageRoute<QrScannerScreen>(
        builder: (_) => const QrScannerScreen(),
        settings: const RouteSettings(name: name),
      );

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  // QRコードのみを対象とし、不要なフォーマットの検出を避ける。
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  // 連続検出による多重処理を防ぐためのフラグ。
  bool _isHandling = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 読み取り処理(handleScannedValue)の途中でプロバイダーが破棄されないよう、
    // 画面が表示されている間はプレゼンターを監視して生存させる。
    ref.watch(qrScannerPresenterProvider);

    final scanWindowSize = MediaQuery.sizeOf(context).width * 0.7;

    final scanner = MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
    );

    // 読み取り範囲を示すガイド枠。
    final guideFrame = Center(
      child: Container(
        width: scanWindowSize,
        height: scanWindowSize,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 3,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    final guideText = Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 48 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Text(
          'イベント会場のQRコードを枠内に収めてください',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコードを読み取る'),
      ),
      body: Stack(
        children: [
          scanner,
          guideFrame,
          guideText,
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandling) {
      return;
    }

    final rawValue = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    setState(() {
      _isHandling = true;
    });

    final result = await ref
        .read(qrScannerPresenterProvider.notifier)
        .handleScannedValue(rawValue);

    if (!mounted) {
      return;
    }

    switch (result) {
      case QrScanResult.earnedNewBadge:
        HapticFeedbackHelper.lightImpact();
        // 読み取り画面はスタックから取り除き、祝福画面に置き換える。
        await Navigator.of(context).pushReplacement(
          BadgeAcquiredScreen.route(
            badge: AppBadge.plectrumConcertVol11,
            earnedVP: qrEventBonusVP,
          ),
        );
      case QrScanResult.alreadyEarned:
        _showMessageAndResume('このバッジはすでに獲得済みです');
      case QrScanResult.notMatched:
        _showMessageAndResume('対象のQRコードではありません');
    }
  }

  /// メッセージを表示し、再び読み取りを受け付ける状態に戻す。
  void _showMessageAndResume(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      _isHandling = false;
    });
  }
}
