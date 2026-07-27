import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:house_worker/data/model/chat_mode.dart';

part 'chat_mode_selection.freezed.dart';

/// ユーザーが選択した回答モードの設定
///
/// [ChatModeSelectionAuto] の場合、会話の内容に応じてどちらの [ChatMode] を
/// 使うかが自動的に決定される。
@freezed
sealed class ChatModeSelection with _$ChatModeSelection {
  const factory ChatModeSelection.auto() = ChatModeSelectionAuto;
  const factory ChatModeSelection.fixed(ChatMode mode) =
      ChatModeSelectionFixed;
}
