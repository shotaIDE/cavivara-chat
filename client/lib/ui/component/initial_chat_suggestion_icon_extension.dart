import 'package:flutter/material.dart';
import 'package:house_worker/data/model/initial_chat_suggestions_config.dart';

/// [InitialChatSuggestionIcon] にUI関連の機能を拡張するExtension
extension InitialChatSuggestionIconExtension on InitialChatSuggestionIcon {
  /// サジェストのカードに表示するアイコン
  ///
  /// ここで参照した `Icons` のみがビルド時のツリーシェイクを免れるため、
  /// Remote Config から指定できるアイコンはこの対応表にあるものに限られる。
  IconData get iconData {
    return switch (this) {
      InitialChatSuggestionIcon.chat => Icons.chat_bubble_outline,
      InitialChatSuggestionIcon.queueMusic => Icons.queue_music,
      InitialChatSuggestionIcon.musicNote => Icons.music_note,
      InitialChatSuggestionIcon.libraryMusic => Icons.library_music,
      InitialChatSuggestionIcon.piano => Icons.piano,
      InitialChatSuggestionIcon.album => Icons.album,
      InitialChatSuggestionIcon.headphones => Icons.headphones,
      InitialChatSuggestionIcon.event => Icons.event,
      InitialChatSuggestionIcon.group => Icons.group,
      InitialChatSuggestionIcon.people => Icons.people,
      InitialChatSuggestionIcon.build => Icons.build,
      InitialChatSuggestionIcon.restaurantMenu => Icons.restaurant_menu,
      InitialChatSuggestionIcon.flightTakeoff => Icons.flight_takeoff,
      InitialChatSuggestionIcon.fitnessCenter => Icons.fitness_center,
      InitialChatSuggestionIcon.book => Icons.book,
      InitialChatSuggestionIcon.lightbulb => Icons.lightbulb,
      InitialChatSuggestionIcon.wbSunny => Icons.wb_sunny,
      InitialChatSuggestionIcon.movie => Icons.movie,
      InitialChatSuggestionIcon.language => Icons.language,
      InitialChatSuggestionIcon.coffee => Icons.coffee,
      InitialChatSuggestionIcon.work => Icons.work,
      InitialChatSuggestionIcon.school => Icons.school,
      InitialChatSuggestionIcon.pets => Icons.pets,
      InitialChatSuggestionIcon.celebration => Icons.celebration,
      InitialChatSuggestionIcon.savings => Icons.savings,
      InitialChatSuggestionIcon.favorite => Icons.favorite,
      InitialChatSuggestionIcon.help => Icons.help_outline,
    };
  }
}
