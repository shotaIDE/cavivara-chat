const appStoreId = '000000000';

/// 利用規約ページの URL
const termsOfServiceUrl =
    'https://tricolor-fright-c89.notion.site/3a935dfd37af805a85d2e826048770d2';

/// プライバシーポリシーページの URL
const privacyPolicyUrl =
    'https://tricolor-fright-c89.notion.site/29e35dfd37af80059ab2eb1cf50e1058';

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
