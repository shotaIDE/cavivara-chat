import 'package:house_worker/data/model/cavivara_profile.dart';
import 'package:house_worker/data/model/cavivara_profiles_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cavivara_profile_service.g.dart';

/// カヴィヴァラのプロフィールを提供するプロバイダー
@riverpod
CavivaraProfile cavivaraProfile(Ref ref) {
  return CavivaraProfilesData.defaultCavivara;
}
