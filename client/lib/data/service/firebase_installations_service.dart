import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_installations_service.g.dart';

/// Firebase Installation ID (FID) を取得する
@riverpod
Future<String> firebaseInstallationId(Ref ref) {
  return FirebaseInstallations.instance.getId();
}
