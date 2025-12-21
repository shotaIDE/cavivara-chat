const appStoreId = '000000000';

const revenueCatProjectTestApiKey = String.fromEnvironment(
  'REVENUE_CAT_PROJECT_TEST_API_KEY',
);
const revenueCatProjectGoogleApiKey = String.fromEnvironment(
  'REVENUE_CAT_PROJECT_GOOGLE_API_KEY',
);
const revenueCatProjectAppleApiKey = String.fromEnvironment(
  'REVENUE_CAT_PROJECT_APPLE_API_KEY',
);

class GoogleForm {
  static const postUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSePmERs6l3UDEo8oMwAUVTysCk13icDYy0KXG2N5KGXzVoF6Q/formResponse';

  static const bodyKey = 'entry.893089758';
  static const emailKey = 'entry.1495718762';
  static const userIdKey = 'entry.1274333669';
}
