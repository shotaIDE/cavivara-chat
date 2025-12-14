import 'package:logging/logging.dart';

enum Flavor { emulator, dev, prod }

final Flavor flavor = _getFlavor();

Flavor _getFlavor() {
  final logger = Logger('Flavor');

  const flavorString = String.fromEnvironment('FLUTTER_APP_FLAVOR');

  // 環境変数が設定されていない場合（テスト時など）はdevをデフォルトとする
  if (flavorString.isEmpty) {
    logger.info('FLUTTER_APP_FLAVOR not set, using dev as default');
    return Flavor.dev;
  }

  final flavor = Flavor.values.firstWhere(
    (value) => value.name == flavorString,
    orElse: () {
      final validFlavorNamesDescription = Flavor.values
          .map((f) => '"${f.name}"')
          .join(', ');
      throw UnimplementedError(
        'Flavor "$flavorString" is not implemented. '
        'Please specify one of the valid flavors: '
        '$validFlavorNamesDescription.',
      );
    },
  );

  logger.info('Detected flavor: ${flavor.name}');

  return flavor;
}
