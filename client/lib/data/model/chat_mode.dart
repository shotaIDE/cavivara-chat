enum ChatMode {
  /// Function Callingでプレクトラム結社の知識を参照して回答するモード。
  ///
  /// レスポンススキーマと同時には使用できないため、返信サジェストは付与されない。
  plectrumSocietyMaster,

  /// 返信サジェストを付与して雑談する回答をするモード。
  chitChatMaster,
}
