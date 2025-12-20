import 'package:house_worker/data/model/preference_key.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preference_service.g.dart';

@riverpod
PreferenceService preferenceService(Ref ref) {
  return PreferenceService();
}

class PreferenceService {
  Future<bool?> getBool(PreferenceKey key) {
    final preferences = SharedPreferencesAsync();
    return preferences.getBool(key.name);
  }

  Future<void> setBool(
    PreferenceKey key, {
    required bool value,
  }) async {
    final preferences = SharedPreferencesAsync();
    await preferences.setBool(key.name, value);
  }

  Future<String?> getString(PreferenceKey key) {
    final preferences = SharedPreferencesAsync();
    return preferences.getString(key.name);
  }

  Future<void> setString(PreferenceKey key, {required String value}) async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(key.name, value);
  }

  Future<int?> getInt(PreferenceKey key) {
    final preferences = SharedPreferencesAsync();
    return preferences.getInt(key.name);
  }

  Future<void> setInt(PreferenceKey key, {required int value}) async {
    final preferences = SharedPreferencesAsync();
    await preferences.setInt(key.name, value);
  }

  Future<List<String>?> getStringList(PreferenceKey key) {
    final preferences = SharedPreferencesAsync();
    return preferences.getStringList(key.name);
  }

  Future<void> setStringList(
    PreferenceKey key, {
    required List<String> value,
  }) async {
    final preferences = SharedPreferencesAsync();
    await preferences.setStringList(key.name, value);
  }

  Future<void> remove(PreferenceKey key) async {
    final preferences = SharedPreferencesAsync();
    await preferences.remove(key.name);
  }
}
