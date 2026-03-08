// ignore_for_file: avoid_classes_with_only_static_members

import 'package:flutter/services.dart';

/// Haptic Feedbackを提供するヘルパークラス
///
/// ChatGPTアプリのような操作感を実現するために、
/// 様々なインタラクションに応じたHaptic Feedbackを提供する
abstract final class HapticFeedbackHelper {
  /// ボタンタップ時の軽いフィードバック
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// メニュー選択、ドロワー開閉時の中程度のフィードバック
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// 削除操作など重要なアクション時の強いフィードバック
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// リスト項目選択、ラジオボタン切り替え時のフィードバック
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// メッセージ送信時のフィードバック
  static void onMessageSent() {
    HapticFeedback.lightImpact();
  }

  /// サジェストボタンタップ時のフィードバック
  static void onSuggestionTap() {
    HapticFeedback.lightImpact();
  }

  /// ナビゲーションメニュー項目タップ時のフィードバック
  static void onNavigationTap() {
    HapticFeedback.selectionClick();
  }

  /// チャット履歴クリア時のフィードバック
  static void onClearChat() {
    HapticFeedback.heavyImpact();
  }

  /// ダイアログ表示時のフィードバック
  static void onDialogShow() {
    HapticFeedback.mediumImpact();
  }

  /// 成功時のフィードバック（コピー完了など）
  static void onSuccess() {
    HapticFeedback.lightImpact();
  }

  /// エラー時のフィードバック
  static void onError() {
    HapticFeedback.heavyImpact();
  }

  /// スイッチ切り替え時のフィードバック
  static void onToggle() {
    HapticFeedback.selectionClick();
  }

  /// メッセージ受信開始時のフィードバック（2回振動）
  static Future<void> onMessageReceiveStart() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await HapticFeedback.heavyImpact();
  }

  /// メッセージ受信完了時のフィードバック（1回振動）
  static void onMessageReceiveComplete() {
    HapticFeedback.heavyImpact();
  }
}
