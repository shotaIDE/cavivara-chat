import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_session.freezed.dart';

@freezed
sealed class AppSession with _$AppSession {
  const AppSession._();

  factory AppSession.signedIn() = AppSessionSignedIn;

  factory AppSession.notSignedIn() = AppSessionNotSignedIn;
}
