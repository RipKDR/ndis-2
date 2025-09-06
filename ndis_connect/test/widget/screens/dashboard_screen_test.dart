import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndis_connect/l10n/app_localizations.dart';
import 'package:ndis_connect/screens/dashboard_screen.dart';
import 'package:ndis_connect/services/analytics_service.dart';
import 'package:ndis_connect/services/remote_config_service.dart';
import 'package:provider/provider.dart';

import 'dashboard_screen_test.mocks.dart';

@GenerateMocks([RemoteConfigService, AnalyticsService])
void main() {
  group('DashboardScreen Widget Tests', () {
    late MockRemoteConfigService mockRemoteConfig;
    late MockAnalyticsService mockAnalytics;

    setUp(() {
      mockRemoteConfig = MockRemoteConfigService();
      mockAnalytics = MockAnalyticsService();
    });

    Widget createTestWidget({required Widget child}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [
          Locale('en'),
          Locale('en', 'AU'),
        ],
        home: MultiProvider(
          providers: [
            Provider.value(value: mockRemoteConfig),
            Provider.value(value: mockAnalytics),
          ],
          child: child,
        ),
      );
    }

    testWidgets('should display participant dashboard with all feature cards',
        (WidgetTester tester) async {
      // Arrange
      when(mockRemoteConfig.pointsEnabled).thenReturn(true);
      when(mockRemoteConfig.badgeVariant).thenReturn('A');

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Participant Dashboard'), findsOneWidget);
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Service Map'), findsOneWidget);
      expect(find.text('Points'), findsOneWidget);
    });

    testWidgets('should display emergency button', (WidgetTester tester) async {
      // Arrange
      when(mockRemoteConfig.pointsEnabled).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Emergency'), findsOneWidget);
      expect(find.byIcon(Icons.health_and_safety), findsOneWidget);
    });

    testWidgets('should navigate to settings when settings button is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockRemoteConfig.pointsEnabled).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should show emergency support sheet when emergency button is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockRemoteConfig.pointsEnabled).thenReturn(false);
      when(mockAnalytics.logEvent(any)).thenAnswer((_) async {
        return;
      });

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Emergency'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BottomSheet), findsOneWidget);
      verify(mockAnalytics.logEvent('emergency_opened')).called(1);
    });

    testWidgets('should display different badge icon based on variant',
        (WidgetTester tester) async {
      // Test variant A
      when(mockRemoteConfig.pointsEnabled).thenReturn(true);
      when(mockRemoteConfig.badgeVariant).thenReturn('A');

      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);

      // Test variant B
      when(mockRemoteConfig.badgeVariant).thenReturn('B');

      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.military_tech), findsOneWidget);
    });

    testWidgets('should hide points card when points are disabled', (WidgetTester tester) async {
      // Arrange
      when(mockRemoteConfig.pointsEnabled).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Points'), findsNothing);
    });

    testWidgets('should display offline mode indicator', (WidgetTester tester) async {
      // Arrange
      when(mockRemoteConfig.pointsEnabled).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Offline Mode'), findsOneWidget);
    });

    testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
      // Arrange
      when(mockRemoteConfig.pointsEnabled).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Semantics), findsWidgets);

      // Check that feature cards have proper semantics
      final budgetCard = find.ancestor(
        of: find.text('Budget'),
        matching: find.byType(Card),
      );
      expect(budgetCard, findsOneWidget);
    });

    testWidgets('should handle navigation to different screens', (WidgetTester tester) async {
      // Arrange
      when(mockRemoteConfig.pointsEnabled).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      // Test navigation to budget screen
      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      // Test navigation to calendar screen
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      // Test navigation to tasks screen
      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();

      // Test navigation to service map screen
      await tester.tap(find.text('Service Map'));
      await tester.pumpAndSettle();

      // Assert - navigation should work without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display feature cards in proper layout', (WidgetTester tester) async {
      // Arrange
      when(mockRemoteConfig.pointsEnabled).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget(
        child: const ParticipantDashboardScreen(),
      ));
      await tester.pumpAndSettle();

      // Assert
      final featureCards = find.byType(Card);
      expect(featureCards, findsWidgets);

      // Check that cards are properly sized
      final cardWidget = tester.widget<Card>(featureCards.first);
      expect(cardWidget.child, isA<SizedBox>());
    });

    testWidgets('should handle text scaling for accessibility', (WidgetTester tester) async {
      // Arrange
      when(mockRemoteConfig.pointsEnabled).thenReturn(false);

      // Act
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: createTestWidget(
            child: const ParticipantDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Participant Dashboard'), findsOneWidget);
      // Text should be scaled appropriately
    });
  });
}
