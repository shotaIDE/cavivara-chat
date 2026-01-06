import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/data/model/user_profile.dart';
import 'package:house_worker/data/service/auth_service.dart';
import 'package:house_worker/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debug_presenter.freezed.dart';
part 'debug_presenter.g.dart';

/// デバッグ画面の状態
@freezed
sealed class DebugState with _$DebugState {
  /// プロフィールがあることが確定した状態
  const factory DebugState.hasProfile({
    required UserProfile userProfile,
  }) = DebugStateHasProfile;

  /// プロフィール関連の処理中
  const factory DebugState.processing({
    required UserProfile userProfile,
  }) = DebugStateProcessing;

  /// プロフィールがない状態
  const factory DebugState.noProfile() = DebugStateNoProfile;
}

/// デバッグ画面のPresenter
@riverpod
class DebugPresenter extends _$DebugPresenter {
  @override
  Future<DebugState> build() async {
    final userProfile = await ref.watch(currentUserProfileProvider.future);
    if (userProfile == null) {
      return const DebugState.noProfile();
    }
    return DebugState.hasProfile(userProfile: userProfile);
  }

  /// ログアウト処理
  Future<void> logout() async {
    final currentState = await future;

    final userProfile = currentState.maybeWhen(
      hasProfile: (userProfile) => userProfile,
      orElse: () => null,
    );
    if (userProfile == null) {
      return;
    }

    state = AsyncData(
      DebugState.processing(userProfile: userProfile),
    );

    await ref.read(authServiceProvider).signOut();
    await ref.read(currentAppSessionProvider.notifier).signOut();
  }

  /// アカウント削除処理
  Future<void> deleteAccount() async {
    final currentState = await future;

    // 処理中状態に設定
    currentState.mapOrNull(
      hasProfile: (state) {
        this.state = AsyncData(
          DebugState.processing(userProfile: state.userProfile),
        );
      },
    );

    try {
      // 現在の実装ではサインアウトのみ
      // 将来的にはFirebase Authenticationからのアカウント削除処理を追加
      await ref.read(authServiceProvider).signOut();
      await ref.read(currentAppSessionProvider.notifier).signOut();
    } finally {
      // signOut後は画面が破棄される可能性が高いため、
      // 状態の更新は不要
    }
  }
}
