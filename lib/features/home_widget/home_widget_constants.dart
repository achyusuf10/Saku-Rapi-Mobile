/// Constants for Android Home Widget integration.
///
/// All SharedPreferences keys, widget names, and URI scheme constants
/// shared between Flutter and native Android sides.
class HomeWidgetConstants {
  HomeWidgetConstants._();

  // --- Widget Identity ---

  /// Android AppWidgetProvider class name (without package).
  static const String androidWidgetName = 'SakuRapiWidgetProvider';

  /// Qualified Android widget name (with package).
  static const String androidQualifiedName =
      'app.sakurapi.com.widget.SakuRapiWidgetProvider';

  // --- SharedPreferences Keys ---

  /// Key for serialized wallet data JSON.
  static const String walletDataKey = 'wallet_data';

  /// Prefix for widget config (per appWidgetId).
  /// Full key: `widget_config_{appWidgetId}`
  static const String configKeyPrefix = 'widget_config_';

  /// Prefix for wallet display index (per appWidgetId).
  /// Full key: `widget_index_{appWidgetId}`
  static const String indexKeyPrefix = 'widget_index_';

  /// Prefix for balance visibility toggle (per appWidgetId).
  /// Full key: `widget_balance_visible_{appWidgetId}`
  static const String balanceVisibleKeyPrefix = 'widget_balance_visible_';

  // --- Deep Link URI ---

  /// URI scheme for widget deep links.
  static const String uriScheme = 'sakurapi';

  /// URI host for widget actions.
  static const String uriHost = 'action';

  /// Query parameter keys.
  static const String paramType = 'type';
  static const String paramWalletId = 'walletId';

  /// Action types for quick action buttons.
  static const String actionManual = 'manual';
  static const String actionSpeech = 'speech';
  static const String actionOcr = 'ocr';
  static const String actionText = 'text';

  // --- iOS App Group (future use) ---
  static const String iosAppGroupId = 'group.app.sakurapi.com';
}
