import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/model/user_profile.dart';
import 'package:house_worker/data/repository/viva_point_repository.dart';
import 'package:house_worker/data/service/auth_service.dart';
import 'package:house_worker/ui/feature/settings/settings_screen.dart';
import 'package:house_worker/ui/feature/settings/support_cavivara_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('SettingsScreen - 称号表示機能', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      container = ProviderContainer(
        overrides: [
          // AuthServiceとUserProfileをモック化
          currentUserProfileProvider.overrideWith((ref) {
            return Stream.value(
              const UserProfileWithGoogleAccount(
                id: 'test-id',
                displayName: 'Test User',
                email: 'test@example.com',
                photoUrl: null,
              ),
            );
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('称号表示タイルが表示されること', (tester) async {
      // Arrange
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // 称号表示タイルが表示されていること
      expect(find.text('応援ステータス'), findsOneWidget);
    });

    testWidgets('称号表示タイルに累計VPと現在の称号が表示されること', (tester) async {
      // Arrange - 50VPを設定
      container.dispose();
      SharedPreferences.setMockInitialValues({
        PreferenceKey.totalVivaPoint.name: 50,
      });
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
        PreferenceKey.totalVivaPoint.name: 50,
      });
      container = ProviderContainer(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) {
            return Stream.value(
              const UserProfileWithGoogleAccount(
                id: 'test-id',
                displayName: 'Test User',
                email: 'test@example.com',
                photoUrl: null,
              ),
            );
          }),
        ],
      );

      // vivaPointRepositoryの初期化を待つ
      await container.read(vivaPointRepositoryProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // 累計VPが表示されていること
      expect(find.textContaining('50VP'), findsOneWidget);

      // 称号名が表示されていること（50VPは"一人前ヴィヴァサポーター"）
      expect(find.textContaining('一人前ヴィヴァサポーター'), findsOneWidget);
    });

    testWidgets('称号表示タイルをタップすると応援画面に遷移すること', (tester) async {
      // Arrange
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - 称号表示タイルをタップ
      await tester.tap(find.text('応援ステータス'));
      await tester.pumpAndSettle();

      // Assert
      // 応援画面に遷移していること
      expect(find.text('カヴィヴァラを応援'), findsOneWidget);
      expect(find.byType(SupportCavivaraScreen), findsOneWidget);
    });

    testWidgets('0VPの場合は初心者称号が表示されること', (tester) async {
      // Arrange - 0VP（デフォルト）
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // 駆け出し称号が表示されていること
      expect(find.textContaining('駆け出しヴィヴァサポーター'), findsOneWidget);
    });
  });
}
