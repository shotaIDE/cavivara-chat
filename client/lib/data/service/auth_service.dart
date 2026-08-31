import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:house_worker/data/model/sign_in_result.dart';
import 'package:house_worker/data/model/user_profile.dart';
import 'package:house_worker/data/service/error_report_service.dart';
import 'package:house_worker/data/service/sign_in_google_exception.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

@riverpod
AuthService authService(Ref ref) {
  return AuthService(errorReportService: ref.watch(errorReportServiceProvider));
}

@riverpod
bool isSignedIn(Ref ref) {
  final user = firebase_auth.FirebaseAuth.instance.currentUser;
  if (user == null) {
    return false;
  }

  return true;
}

@riverpod
Stream<UserProfile?> currentUserProfile(Ref ref) {
  return firebase_auth.FirebaseAuth.instance.userChanges().map((user) {
    if (user == null) {
      return null;
    }

    return UserProfile.fromFirebaseAuthUser(user);
  });
}

class AuthService {
  AuthService({required ErrorReportService errorReportService})
    : _errorReportService = errorReportService;

  final ErrorReportService _errorReportService;
  final _logger = Logger('AuthService');

  Future<SignInResult> signInWithGoogle() async {
    final firebase_auth.AuthCredential authCredential;
    try {
      authCredential = await _loginGoogle();
    } on SignInGoogleException catch (e, stack) {
      switch (e) {
        case SignInGoogleExceptionCancelled():
          _logger.warning('Google sign-in cancelled.');

          throw const SignInWithGoogleException.cancelled();
        case SignInGoogleExceptionUncategorized():
          _logger.warning('Google sign-in failed.');

          unawaited(_errorReportService.recordError(e, stack));

          throw const SignInWithGoogleException.uncategorized();
      }
    }

    final firebase_auth.UserCredential userCredential;
    try {
      userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithCredential(authCredential);
    } on firebase_auth.FirebaseAuthException catch (e, stack) {
      unawaited(_errorReportService.recordError(e, stack));

      throw const SignInWithGoogleException.uncategorized();
    }

    final user = userCredential.user!;

    _logger.info('Signed in with Google.');

    return SignInResult(
      userId: user.uid,
      isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  Future<void> linkWithGoogle() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser!;

    final firebase_auth.AuthCredential authCredential;
    try {
      authCredential = await _loginGoogle();
    } on SignInGoogleException catch (e, stack) {
      switch (e) {
        case SignInGoogleExceptionCancelled():
          _logger.warning('Google sign-in cancelled.');

          throw const LinkWithGoogleException.cancelled();
        case SignInGoogleExceptionUncategorized():
          _logger.warning('Google sign-in failed.');

          unawaited(_errorReportService.recordError(e, stack));

          throw const LinkWithGoogleException.uncategorized();
      }
    }

    try {
      await user.linkWithCredential(authCredential);
    } on firebase_auth.FirebaseAuthException catch (e, stack) {
      if (e.code == 'credential-already-in-use') {
        _logger.warning('This Google account is already in use.');

        throw const LinkWithGoogleException.alreadyInUse();
      }

      unawaited(_errorReportService.recordError(e, stack));

      throw const LinkWithGoogleException.uncategorized();
    }

    _logger.info('Linked with Google account.');
  }

  Future<SignInResult> signInWithApple() async {
    final appleAuthProvider = _getAppleAuthProvider();

    final firebase_auth.UserCredential userCredential;
    try {
      userCredential = await firebase_auth.FirebaseAuth.instance
          .signInWithProvider(appleAuthProvider);
    } on firebase_auth.FirebaseAuthException catch (e, stack) {
      if (e.code == 'canceled') {
        throw const SignInWithAppleException.cancelled();
      }

      unawaited(_errorReportService.recordError(e, stack));

      throw const SignInWithAppleException.uncategorized();
    }

    final user = userCredential.user;
    if (user == null) {
      const exception = SignInWithAppleException.uncategorized();
      unawaited(_errorReportService.recordError(exception, StackTrace.current));

      throw exception;
    }

    return SignInResult(
      userId: user.uid,
      isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  Future<void> linkWithApple() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser!;

    final appleAuthProvider = _getAppleAuthProvider();

    try {
      await user.linkWithProvider(appleAuthProvider);
    } on firebase_auth.FirebaseAuthException catch (e, stack) {
      if (e.code == 'canceled') {
        throw const LinkWithAppleException.cancelled();
      }

      if (e.code == 'credential-already-in-use') {
        throw const LinkWithAppleException.alreadyInUse();
      }

      unawaited(_errorReportService.recordError(e, stack));

      throw const LinkWithAppleException.uncategorized();
    }
  }

  Future<String> signInAnonymously() async {
    final firebase_auth.UserCredential userCredential;

    try {
      userCredential = await firebase_auth.FirebaseAuth.instance
          .signInAnonymously();
    } on firebase_auth.FirebaseAuthException catch (e, stack) {
      unawaited(_errorReportService.recordError(e, stack));

      throw const SignInAnonymouslyException();
    }

    final user = userCredential.user;
    if (user == null) {
      const exception = SignInAnonymouslyException();
      unawaited(_errorReportService.recordError(exception, StackTrace.current));

      throw exception;
    }

    _logger.info('Signed in anonymously. user ID = ${user.uid}');

    return user.uid;
  }

  Future<void> signOut() async {
    await firebase_auth.FirebaseAuth.instance.signOut();
  }

  Future<firebase_auth.AuthCredential> _loginGoogle() async {
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['https://www.googleapis.com/auth/userinfo.profile'],
      );
    } on GoogleSignInException catch (e, stack) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInGoogleException.cancelled();
      }

      unawaited(_errorReportService.recordError(e, stack));

      throw const SignInGoogleException.uncategorized();
    }

    final authentication = account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) {
      throw const SignInGoogleException.uncategorized();
    }

    _logger.info(
      'Signed in Google account: '
      'user ID = ${account.id}, '
      'display name = ${account.displayName}, '
      'photo URL = ${account.photoUrl}',
    );

    return firebase_auth.GoogleAuthProvider.credential(idToken: idToken);
  }

  firebase_auth.AppleAuthProvider _getAppleAuthProvider() {
    return firebase_auth.AppleAuthProvider()..addScope('name');
  }
}
