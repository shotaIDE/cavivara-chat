import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/chat_mode.dart';
import 'package:house_worker/data/model/chat_mode_selection.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/repository/chat_mode_selection_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('ChatModeSelectionRepository', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('初期状態', () {
      test('永続化データがない場合は自動選択が返されること', () async {
        final selection = await container.read(
          chatModeSelectionRepositoryProvider.future,
        );

        expect(selection, equals(const ChatModeSelection.auto()));
      });

      test('永続化データが存在する場合は永続化された値で初期化されること', () async {
        container.dispose();
        SharedPreferences.setMockInitialValues({
          PreferenceKey.chatModeSelection.name:
              ChatMode.plectrumSocietyMaster.name,
        });
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.withData({
              PreferenceKey.chatModeSelection.name:
                  ChatMode.plectrumSocietyMaster.name,
            });
        container = ProviderContainer();

        final selection = await container.read(
          chatModeSelectionRepositoryProvider.future,
        );

        expect(
          selection,
          equals(
            const ChatModeSelection.fixed(ChatMode.plectrumSocietyMaster),
          ),
        );
      });
    });

    group('保存', () {
      test('自動選択を保存できること', () async {
        await container
            .read(chatModeSelectionRepositoryProvider.notifier)
            .save(const ChatModeSelection.fixed(ChatMode.chitChatMaster));

        await container
            .read(chatModeSelectionRepositoryProvider.notifier)
            .save(const ChatModeSelection.auto());

        final selection = await container.read(
          chatModeSelectionRepositoryProvider.future,
        );
        expect(selection, equals(const ChatModeSelection.auto()));
      });

      test('固定モードを保存できること', () async {
        await container
            .read(chatModeSelectionRepositoryProvider.notifier)
            .save(const ChatModeSelection.fixed(ChatMode.chitChatMaster));

        final selection = await container.read(
          chatModeSelectionRepositoryProvider.future,
        );
        expect(
          selection,
          equals(const ChatModeSelection.fixed(ChatMode.chitChatMaster)),
        );
      });

      test('保存した内容が永続化されること', () async {
        await container
            .read(chatModeSelectionRepositoryProvider.notifier)
            .save(
              const ChatModeSelection.fixed(ChatMode.plectrumSocietyMaster),
            );

        final newContainer = ProviderContainer();
        addTearDown(newContainer.dispose);
        final selection = await newContainer.read(
          chatModeSelectionRepositoryProvider.future,
        );

        expect(
          selection,
          equals(
            const ChatModeSelection.fixed(ChatMode.plectrumSocietyMaster),
          ),
        );
      });
    });
  });
}
