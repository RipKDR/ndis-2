enum Environment { development, staging, production }

class AppConfig {
  // Change this to Environment.production for production deployment
  static const Environment _environment = Environment.production;

  static Environment get environment => _environment;

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;

  // Firebase project IDs
  static String get firebaseProjectId {
    switch (_environment) {
      case Environment.development:
        return 'ndis-connect-dev';
      case Environment.staging:
        return 'ndis-connect-staging';
      case Environment.production:
        return 'ndis-connect-prod';
    }
  }

  // API endpoints
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        return 'https://dev-api.ndisconnect.com.au';
      case Environment.staging:
        return 'https://staging-api.ndisconnect.com.au';
      case Environment.production:
        return 'https://api.ndisconnect.com.au';
    }
  }

  // Feature flags
  static bool get enableAnalytics => isProduction || isStaging;
  static bool get enableCrashlytics => isProduction || isStaging;
  static bool get enableRemoteConfig => true;
  static bool get enableOfflineSync => true;

  // Debug settings
  static bool get enableDebugLogs => isDevelopment;
  static bool get enablePerformanceMonitoring => isProduction;
}
