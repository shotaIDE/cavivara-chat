import 'package:house_worker/data/service/auth_service.dart';
import 'package:house_worker/ui/root_presenter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debug_presenter.g.dart';

@riverpod
class DebugPresenter extends _$DebugPresenter {
  @override
  void build(Ref ref) {}

  /// ログアウト処理
  Future<void> logout() async {
    await ref.read(authServiceProvider).signOut();
    await ref.read(currentAppSessionProvider.notifier).signOut();
  }

  /// アカウント削除処理
  Future<void> deleteAccount() async {
    // 現在の実装ではサインアウトのみ
    // 将来的にはFirebase Authenticationからのアカウント削除処理を追加
    await ref.read(authServiceProvider).signOut();
    await ref.read(currentAppSessionProvider.notifier).signOut();
  }
}
