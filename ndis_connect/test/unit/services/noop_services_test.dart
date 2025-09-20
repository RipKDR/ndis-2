import 'package:flutter_test/flutter_test.dart';
import 'package:ndis_connect/services/analytics_service.dart';
import 'package:ndis_connect/services/remote_config_service.dart';

void main() {
  test('AnalyticsService.logEvent is no-op when Firebase missing', () async {
    final analytics = AnalyticsService();

    // Should not throw even if FirebaseAnalytics is unavailable in the test env.
    await analytics.logEvent('test_event', params: {'a': 'b'});
  });

  test('RemoteConfigService returns defaults when null passed', () {
    final rc = RemoteConfigService(null);

    expect(rc.pointsEnabled, equals(true));
    expect(rc.aiAssistLevel, equals('basic'));
    expect(rc.badgeVariant, equals('A'));
    expect(rc.remindersFunctionUrl, equals(''));
  });
}
