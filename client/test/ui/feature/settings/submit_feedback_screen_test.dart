import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_worker/data/model/preference_key.dart';
import 'package:house_worker/data/model/user_profile.dart';
import 'package:house_worker/data/repository/feedback_email_repository.dart';
import 'package:house_worker/data/service/auth_service.dart';
import 'package:house_worker/ui/feature/settings/submit_feedback_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('SubmitFeedbackScreen - 返信用メールアドレスの保持', () {
    // ヒントの Text ウィジェットは入力済みでもツリーに残る（不透明度 0 で
    // 描画されるだけ）ため、ダミー値にはヒントと異なる文字列を使う。
    // 同一にすると find.text がヒントも拾い、入力内容の検証ができなくなる。
    const dummyEmail = 'saved.address@example.com';
    const emailFieldHint = 'your.name@example.com';
    const emailFieldLabel = '返信用メールアドレス（任意）';

    late ProviderContainer container;

    ProviderContainer createContainer() {
      return ProviderContainer(
        overrides: [
          // FirebaseAuth は未初期化の環境ではエラーになるため、モック化する
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
    }

    void setPreferences(Map<String, Object> values) {
      SharedPreferences.setMockInitialValues(values);
      SharedPreferencesAsyncPlatform.instance = values.isEmpty
          ? InMemorySharedPreferencesAsync.empty()
          : InMemorySharedPreferencesAsync.withData(values);
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SubmitFeedbackScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder findEmailField() {
      return find.ancestor(
        of: find.text(emailFieldLabel),
        matching: find.byType(Column),
      );
    }

    /// 永続化された返信用メールアドレスを、画面とは別のコンテナから読み直す
    Future<String> readStoredEmail() async {
      final newContainer = createContainer();
      final storedEmail = await newContainer.read(
        feedbackEmailRepositoryProvider.future,
      );

      // Riverpod は不要になった provider の破棄を Duration.zero の Timer で
      // 予約する。addTearDown で破棄するとテストの不変条件の検証より後になり、
      // 「A Timer is still pending」で失敗するため、ここで破棄して取り消す。
      newContainer.dispose();

      return storedEmail;
    }

    setUp(() {
      setPreferences({});
      container = createContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('保存済みの返信用メールアドレスが初期表示されること', (tester) async {
      // Arrange
      container.dispose();
      setPreferences({PreferenceKey.feedbackEmail.name: dummyEmail});
      container = createContainer();

      // Act
      await pumpScreen(tester);

      // Assert
      expect(
        find.descendant(
          of: findEmailField(),
          matching: find.text(dummyEmail),
        ),
        findsOneWidget,
      );
    });

    testWidgets('入力した返信用メールアドレスが永続化されること', (tester) async {
      // Arrange
      await pumpScreen(tester);

      // Act
      await tester.enterText(
        find.widgetWithText(TextFormField, emailFieldHint),
        dummyEmail,
      );
      await tester.pumpAndSettle();

      // Assert
      expect(await readStoredEmail(), equals(dummyEmail));
    });

    testWidgets('未入力の場合はクリアボタンが表示されないこと', (tester) async {
      // Act
      await pumpScreen(tester);

      // Assert
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('入力中はクリアボタンが表示され、押下すると入力内容と永続化データが消去されること', (
      tester,
    ) async {
      // Arrange
      container.dispose();
      setPreferences({PreferenceKey.feedbackEmail.name: dummyEmail});
      container = createContainer();
      await pumpScreen(tester);

      // Assert - クリアボタンが表示されていること
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Act
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Assert - 入力内容が消去されていること
      expect(
        find.descendant(
          of: findEmailField(),
          matching: find.text(dummyEmail),
        ),
        findsNothing,
      );

      // Assert - 永続化データが消去されていること
      expect(await readStoredEmail(), equals(''));
    });
  });
}
