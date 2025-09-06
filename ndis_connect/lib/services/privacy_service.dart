import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  // Privacy settings keys
  static const String _privacySettingsKey = 'privacy_settings';
  static const String _dataCollectionKey = 'data_collection_consent';
  static const String _analyticsKey = 'analytics_consent';
  static const String _crashReportingKey = 'crash_reporting_consent';
  static const String _personalizationKey = 'personalization_consent';
  static const String _locationTrackingKey = 'location_tracking_consent';
  static const String _biometricDataKey = 'biometric_data_consent';
  static const String _dataRetentionKey = 'data_retention_settings';

  // Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Privacy settings model
  Map<String, dynamic> getDefaultPrivacySettings() {
    return {
      'dataCollection': false,
      'analytics': false,
      'crashReporting': false,
      'personalization': false,
      'locationTracking': false,
      'biometricData': false,
      'dataRetentionDays': 365,
      'autoDeleteData': false,
      'shareDataWithThirdParties': false,
      'marketingCommunications': false,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  // Get current privacy settings
  Future<Map<String, dynamic>> getPrivacySettings() async {
    try {
      final settingsJson = _prefs.getString(_privacySettingsKey);
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
        return settings;
      }
      return getDefaultPrivacySettings();
    } catch (e) {
      return getDefaultPrivacySettings();
    }
  }

  // Update privacy settings
  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    try {
      final updatedSettings = {
        ...settings,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await _prefs.setString(_privacySettingsKey, jsonEncode(updatedSettings));
      
      // Log privacy settings change
      await _logPrivacyEvent('settings_updated', updatedSettings);
    } catch (e) {
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  // Get specific consent
  Future<bool> getConsent(String consentType) async {
    try {
      final settings = await getPrivacySettings();
      return settings[consentType] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  // Set specific consent
  Future<void> setConsent(String consentType, bool value) async {
    try {
      final settings = await getPrivacySettings();
      settings[consentType] = value;
      await updatePrivacySettings(settings);
      
      // Log consent change
      await _logPrivacyEvent('consent_changed', {
        'consentType': consentType,
        'value': value,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to set consent: $e');
    }
  }

  // Data collection consent
  Future<bool> getDataCollectionConsent() async {
    return await getConsent('dataCollection');
  }

  Future<void> setDataCollectionConsent(bool consent) async {
    await setConsent('dataCollection', consent);
  }

  // Analytics consent
  Future<bool> getAnalyticsConsent() async {
    return await getConsent('analytics');
  }

  Future<void> setAnalyticsConsent(bool consent) async {
    await setConsent('analytics', consent);
  }

  // Crash reporting consent
  Future<bool> getCrashReportingConsent() async {
    return await getConsent('crashReporting');
  }

  Future<void> setCrashReportingConsent(bool consent) async {
    await setConsent('crashReporting', consent);
  }

  // Personalization consent
  Future<bool> getPersonalizationConsent() async {
    return await getConsent('personalization');
  }

  Future<void> setPersonalizationConsent(bool consent) async {
    await setConsent('personalization', consent);
  }

  // Location tracking consent
  Future<bool> getLocationTrackingConsent() async {
    return await getConsent('locationTracking');
  }

  Future<void> setLocationTrackingConsent(bool consent) async {
    await setConsent('locationTracking', consent);
  }

  // Biometric data consent
  Future<bool> getBiometricDataConsent() async {
    return await getConsent('biometricData');
  }

  Future<void> setBiometricDataConsent(bool consent) async {
    await setConsent('biometricData', consent);
  }

  // Data retention settings
  Future<int> getDataRetentionDays() async {
    try {
      final settings = await getPrivacySettings();
      return settings['dataRetentionDays'] as int? ?? 365;
    } catch (e) {
      return 365;
    }
  }

  Future<void> setDataRetentionDays(int days) async {
    try {
      final settings = await getPrivacySettings();
      settings['dataRetentionDays'] = days;
      await updatePrivacySettings(settings);
    } catch (e) {
      throw Exception('Failed to set data retention days: $e');
    }
  }

  // Auto-delete data setting
  Future<bool> getAutoDeleteData() async {
    return await getConsent('autoDeleteData');
  }

  Future<void> setAutoDeleteData(bool autoDelete) async {
    await setConsent('autoDeleteData', autoDelete);
  }

  // Third-party data sharing consent
  Future<bool> getShareDataWithThirdPartiesConsent() async {
    return await getConsent('shareDataWithThirdParties');
  }

  Future<void> setShareDataWithThirdPartiesConsent(bool consent) async {
    await setConsent('shareDataWithThirdParties', consent);
  }

  // Marketing communications consent
  Future<bool> getMarketingCommunicationsConsent() async {
    return await getConsent('marketingCommunications');
  }

  Future<void> setMarketingCommunicationsConsent(bool consent) async {
    await setConsent('marketingCommunications', consent);
  }

  // Request all consents (for initial setup)
  Future<Map<String, bool>> requestAllConsents() async {
    final consents = <String, bool>{};
    
    consents['dataCollection'] = await getDataCollectionConsent();
    consents['analytics'] = await getAnalyticsConsent();
    consents['crashReporting'] = await getCrashReportingConsent();
    consents['personalization'] = await getPersonalizationConsent();
    consents['locationTracking'] = await getLocationTrackingConsent();
    consents['biometricData'] = await getBiometricDataConsent();
    consents['autoDeleteData'] = await getAutoDeleteData();
    consents['shareDataWithThirdParties'] = await getShareDataWithThirdPartiesConsent();
    consents['marketingCommunications'] = await getMarketingCommunicationsConsent();
    
    return consents;
  }

  // Bulk consent update
  Future<void> updateAllConsents(Map<String, bool> consents) async {
    try {
      final settings = await getPrivacySettings();
      
      for (final entry in consents.entries) {
        settings[entry.key] = entry.value;
      }
      
      await updatePrivacySettings(settings);
      
      // Log bulk consent update
      await _logPrivacyEvent('bulk_consent_update', consents);
    } catch (e) {
      throw Exception('Failed to update all consents: $e');
    }
  }

  // Reset all privacy settings to defaults
  Future<void> resetPrivacySettings() async {
    try {
      final defaultSettings = getDefaultPrivacySettings();
      await updatePrivacySettings(defaultSettings);
      
      // Log privacy reset
      await _logPrivacyEvent('privacy_reset', defaultSettings);
    } catch (e) {
      throw Exception('Failed to reset privacy settings: $e');
    }
  }

  // Export user data (GDPR compliance)
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final privacySettings = await getPrivacySettings();
      final consentHistory = await getConsentHistory();
      
      return {
        'privacySettings': privacySettings,
        'consentHistory': consentHistory,
        'exportDate': DateTime.now().toIso8601String(),
        'dataTypes': [
          'privacy_settings',
          'consent_history',
          'user_preferences',
        ],
      };
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }

  // Delete user data (GDPR compliance)
  Future<void> deleteUserData() async {
    try {
      // Clear all privacy settings
      await _prefs.remove(_privacySettingsKey);
      
      // Clear consent history
      await _clearConsentHistory();
      
      // Log data deletion
      await _logPrivacyEvent('data_deleted', {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'user_request',
      });
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  // Get consent history
  Future<List<Map<String, dynamic>>> getConsentHistory() async {
    try {
      final historyJson = _prefs.getString('consent_history');
      if (historyJson != null) {
        final history = jsonDecode(historyJson) as List<dynamic>;
        return history.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Log privacy event
  Future<void> _logPrivacyEvent(String eventType, Map<String, dynamic> data) async {
    try {
      final history = await getConsentHistory();
      
      final event = {
        'eventType': eventType,
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      };
      
      history.add(event);
      
      // Keep only last 100 events
      if (history.length > 100) {
        history.removeRange(0, history.length - 100);
      }
      
      await _prefs.setString('consent_history', jsonEncode(history));
    } catch (e) {
      // Silently fail for privacy logging
    }
  }

  // Clear consent history
  Future<void> _clearConsentHistory() async {
    try {
      await _prefs.remove('consent_history');
    } catch (e) {
      // Silently fail
    }
  }

  // Check if data should be collected based on consent
  Future<bool> shouldCollectData(String dataType) async {
    try {
      switch (dataType) {
        case 'analytics':
          return await getAnalyticsConsent();
        case 'crash_reporting':
          return await getCrashReportingConsent();
        case 'location':
          return await getLocationTrackingConsent();
        case 'biometric':
          return await getBiometricDataConsent();
        case 'personalization':
          return await getPersonalizationConsent();
        default:
          return await getDataCollectionConsent();
      }
    } catch (e) {
      return false;
    }
  }

  // Get privacy compliance status
  Future<Map<String, dynamic>> getPrivacyComplianceStatus() async {
    try {
      final settings = await getPrivacySettings();
      final history = await getConsentHistory();
      
      return {
        'isCompliant': true, // Add compliance checks here
        'consentCount': history.length,
        'lastConsentUpdate': settings['lastUpdated'],
        'dataRetentionDays': settings['dataRetentionDays'],
        'autoDeleteEnabled': settings['autoDeleteData'],
        'thirdPartySharing': settings['shareDataWithThirdParties'],
        'complianceLevel': 'high', // Calculate based on settings
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isCompliant': false,
        'error': e.toString(),
        'lastChecked': DateTime.now().toIso8601String(),
      };
    }
  }

  // Validate privacy settings
  Future<bool> validatePrivacySettings() async {
    try {
      final settings = await getPrivacySettings();
      
      // Check required fields
      final requiredFields = [
        'dataCollection',
        'analytics',
        'crashReporting',
        'personalization',
        'locationTracking',
        'biometricData',
        'dataRetentionDays',
        'autoDeleteData',
        'shareDataWithThirdParties',
        'marketingCommunications',
      ];
      
      for (final field in requiredFields) {
        if (!settings.containsKey(field)) {
          return false;
        }
      }
      
      // Validate data retention days
      final retentionDays = settings['dataRetentionDays'] as int?;
      if (retentionDays == null || retentionDays < 1 || retentionDays > 3650) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get privacy summary for user
  Future<Map<String, dynamic>> getPrivacySummary() async {
    try {
      final settings = await getPrivacySettings();
      final compliance = await getPrivacyComplianceStatus();
      
      return {
        'dataCollectionEnabled': settings['dataCollection'] as bool? ?? false,
        'analyticsEnabled': settings['analytics'] as bool? ?? false,
        'crashReportingEnabled': settings['crashReporting'] as bool? ?? false,
        'personalizationEnabled': settings['personalization'] as bool? ?? false,
        'locationTrackingEnabled': settings['locationTracking'] as bool? ?? false,
        'biometricDataEnabled': settings['biometricData'] as bool? ?? false,
        'dataRetentionDays': settings['dataRetentionDays'] as int? ?? 365,
        'autoDeleteEnabled': settings['autoDeleteData'] as bool? ?? false,
        'thirdPartySharingEnabled': settings['shareDataWithThirdParties'] as bool? ?? false,
        'marketingCommunicationsEnabled': settings['marketingCommunications'] as bool? ?? false,
        'complianceLevel': compliance['complianceLevel'],
        'lastUpdated': settings['lastUpdated'],
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
}
