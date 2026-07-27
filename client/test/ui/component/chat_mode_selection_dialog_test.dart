import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/chat_mode.dart';
import 'package:house_worker/data/model/chat_mode_selection.dart';
import 'package:house_worker/ui/component/chat_mode_extension.dart';
import 'package:house_worker/ui/component/chat_mode_selection_dialog.dart';

void main() {
  Future<void> pumpAndOpenDialog(
    WidgetTester tester, {
    required ChatModeSelection initialSelection,
    required ValueChanged<ChatModeSelection?> onResult,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<ChatModeSelection>(
                    context: context,
                    builder: (context) => ChatModeSelectionDialog(
                      initialSelection: initialSelection,
                    ),
                  );
                  onResult(result);
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('ChatModeSelectionDialog', () {
    testWidgets('初期選択が反映されていること', (tester) async {
      await pumpAndOpenDialog(
        tester,
        initialSelection: const ChatModeSelection.fixed(
          ChatMode.plectrumSocietyMaster,
        ),
        onResult: (_) {},
      );

      final radio = tester.widget<RadioListTile<ChatModeSelection>>(
        find.widgetWithText(
          RadioListTile<ChatModeSelection>,
          ChatMode.plectrumSocietyMaster.displayName,
        ),
      );
      expect(radio.groupValue, equals(radio.value));
    });

    testWidgets('モードを選択して決定すると、選択結果が返されること', (tester) async {
      ChatModeSelection? result;

      await pumpAndOpenDialog(
        tester,
        initialSelection: const ChatModeSelection.auto(),
        onResult: (value) => result = value,
      );

      await tester.tap(find.text(ChatMode.chitChatMaster.displayName));
      await tester.pumpAndSettle();

      await tester.tap(find.text('決定'));
      await tester.pumpAndSettle();

      expect(
        result,
        equals(const ChatModeSelection.fixed(ChatMode.chitChatMaster)),
      );
    });

    testWidgets('キャンセルするとnullが返されること', (tester) async {
      var onResultCalled = false;
      ChatModeSelection? result;

      await pumpAndOpenDialog(
        tester,
        initialSelection: const ChatModeSelection.auto(),
        onResult: (value) {
          onResultCalled = true;
          result = value;
        },
      );

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(onResultCalled, isTrue);
      expect(result, isNull);
    });
  });
}
