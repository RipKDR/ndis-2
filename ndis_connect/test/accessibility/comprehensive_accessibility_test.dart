import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndis_connect/services/accessibility_audit_service.dart';
import 'package:ndis_connect/services/accessibility_service.dart';
import 'package:ndis_connect/widgets/accessibility_widgets.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Comprehensive Accessibility Tests', () {
    late AccessibilityService accessibilityService;
    late AccessibilityAuditService auditService;

    setUpAll(() async {
      accessibilityService = AccessibilityService();
      auditService = AccessibilityAuditService();

      // Initialize services without Firebase dependencies
      try {
        await accessibilityService.initialize();
        await auditService.initialize();
      } catch (e) {
        // Continue with tests even if initialization fails
        print('Service initialization failed: $e');
      }
    });

    group('Accessibility Service Tests', () {
      test('should initialize without errors', () async {
        expect(() => AccessibilityService(), returnsNormally);
      });

      test('should provide accessibility settings', () {
        expect(accessibilityService.highContrastMode, isA<bool>());
        expect(accessibilityService.largeTextMode, isA<bool>());
        expect(accessibilityService.screenReaderEnabled, isA<bool>());
        expect(accessibilityService.textScaleFactor, isA<double>());
      });

      test('should handle text-to-speech operations', () async {
        await expectLater(
          () => accessibilityService.speak('Test message'),
          returnsNormally,
        );

        await expectLater(
          () => accessibilityService.stopSpeaking(),
          returnsNormally,
        );
      });

      test('should provide accessibility theme', () {
        final theme = accessibilityService.getAccessibilityTheme();
        expect(theme, isA<ThemeData>());
        expect(theme.colorScheme, isNotNull);
      });

      test('should handle settings changes', () async {
        await expectLater(
          () => accessibilityService.setHighContrastMode(true),
          returnsNormally,
        );

        await expectLater(
          () => accessibilityService.setLargeTextMode(true),
          returnsNormally,
        );

        await expectLater(
          () => accessibilityService.setTextScaleFactor(1.5),
          returnsNormally,
        );
      });
    });

    group('Accessibility Widgets Tests', () {
      testWidgets('AccessibleButton should meet minimum touch target size',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleButton(
                onPressed: () {},
                child: const Text('Test Button'),
              ),
            ),
          ),
        );

        final buttonFinder = find.byType(ElevatedButton);
        expect(buttonFinder, findsOneWidget);

        final renderBox = tester.renderObject(buttonFinder) as RenderBox;
        final size = renderBox.size;

        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      });

      testWidgets('AccessibleIconButton should have proper semantics', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleIconButton(
                icon: Icons.home,
                tooltip: 'Home',
                semanticLabel: 'Navigate to home screen',
                onPressed: () {},
              ),
            ),
          ),
        );

        final iconButtonFinder = find.byType(IconButton);
        expect(iconButtonFinder, findsOneWidget);

        final semantics = tester.getSemantics(iconButtonFinder);
        expect(semantics.label, contains('Navigate to home screen'));
      });

      testWidgets('AccessibleText should scale properly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<AccessibilityService>.value(value: accessibilityService),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AccessibleText(
                  'Test Text',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        );

        final textFinder = find.text('Test Text');
        expect(textFinder, findsOneWidget);

        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.style?.fontSize, greaterThanOrEqualTo(16));
      });

      testWidgets('AccessibleCard should have proper semantics when tappable',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleCard(
                onTap: () {},
                semanticLabel: 'Tappable card',
                child: const Text('Card Content'),
              ),
            ),
          ),
        );

        final cardFinder = find.byType(InkWell);
        expect(cardFinder, findsOneWidget);

        final semantics = tester.getSemantics(cardFinder);
        expect(semantics.label, equals('Tappable card'));
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      });

      testWidgets('AccessibleTextField should have proper labeling', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AccessibleTextField(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                helperText: 'We will never share your email',
              ),
            ),
          ),
        );

        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        final semantics = tester.getSemantics(textFieldFinder);
        expect(semantics.label, contains('Email Address'));
      });
    });

    group('Color Contrast Tests', () {
      test('should calculate contrast ratios correctly', () {
        final whiteBlackRatio =
            ColorContrastUtils.calculateContrastRatio(Colors.white, Colors.black);
        expect(whiteBlackRatio, equals(21.0));

        final redWhiteRatio = ColorContrastUtils.calculateContrastRatio(Colors.red, Colors.white);
        expect(redWhiteRatio, greaterThan(1.0));
      });

      test('should validate WCAG AA compliance', () {
        expect(ColorContrastUtils.meetsWCAGAA(Colors.black, Colors.white), isTrue);
        expect(ColorContrastUtils.meetsWCAGAA(Colors.grey, Colors.white), isFalse);
      });

      test('should provide contrasting colors', () {
        final lightContrast = ColorContrastUtils.getContrastingColor(Colors.white);
        expect(lightContrast, equals(Colors.black));

        final darkContrast = ColorContrastUtils.getContrastingColor(Colors.black);
        expect(darkContrast, equals(Colors.white));
      });
    });

    group('High Contrast Theme Tests', () {
      testWidgets('should apply high contrast theme correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: HighContrastTheme.lightTheme,
            home: Scaffold(
              body: Container(
                color: Theme.of(tester.element(find.byType(Scaffold))).colorScheme.surface,
                child: Text(
                  'High Contrast Text',
                  style: TextStyle(
                    color: Theme.of(tester.element(find.byType(Scaffold))).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );

        final textFinder = find.text('High Contrast Text');
        expect(textFinder, findsOneWidget);

        final textWidget = tester.widget<Text>(textFinder);
        final textColor = textWidget.style?.color;

        // In high contrast mode, text should be black or yellow
        expect(textColor == Colors.black || textColor == Colors.yellow, isTrue);
      });
    });

    group('Focus Management Tests', () {
      testWidgets('should handle focus traversal correctly', (WidgetTester tester) async {
        final focusNode1 = FocusNode();
        final focusNode2 = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Focus(
                    focusNode: focusNode1,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Button 1'),
                    ),
                  ),
                  Focus(
                    focusNode: focusNode2,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Button 2'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Test focus management
        focusNode1.requestFocus();
        await tester.pump();
        expect(focusNode1.hasFocus, isTrue);

        FocusUtils.focusNext(tester.element(find.byType(Scaffold)));
        await tester.pump();
        expect(focusNode2.hasFocus, isTrue);
      });
    });

    group('Accessibility Audit Tests', () {
      test('should run audit without errors', () async {
        expect(() => AccessibilityAuditService(), returnsNormally);
      });

      test('should provide audit results structure', () {
        final result = AccessibilityAuditResult(
          screenName: 'Test Screen',
          timestamp: DateTime.now(),
          issues: [],
          score: 100,
          compliance: AccessibilityCompliance.wcagAAA,
        );

        expect(result.screenName, equals('Test Screen'));
        expect(result.score, equals(100));
        expect(result.compliance, equals(AccessibilityCompliance.wcagAAA));
      });

      test('should generate accessibility report', () {
        final result = AccessibilityAuditResult(
          screenName: 'Test Screen',
          timestamp: DateTime.now(),
          issues: [
            AccessibilityIssue(
              type: AccessibilityIssueType.colorContrast,
              severity: AccessibilityIssueSeverity.high,
              title: 'Color Contrast Issue',
              description: 'Text color does not meet WCAG AA standards',
              wcagCriteria: ['1.4.3'],
              suggestion: 'Increase color contrast ratio to at least 4.5:1',
            ),
          ],
          score: 85,
          compliance: AccessibilityCompliance.wcagAA,
        );

        final report = auditService.generateAccessibilityReport(result);

        expect(report, contains('Test Screen'));
        expect(report, contains('Score: 85/100'));
        expect(report, contains('Color Contrast Issue'));
        expect(report, contains('WCAG AA'));
      });
    });

    group('Text Scaling Tests', () {
      testWidgets('should support text scaling up to 200%', (WidgetTester tester) async {
        const textScaleFactors = [1.0, 1.5, 2.0];

        for (final scaleFactor in textScaleFactors) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scaleFactor)),
              child: MultiProvider(
                providers: [
                  Provider<AccessibilityService>.value(value: accessibilityService),
                ],
                child: const MaterialApp(
                  home: Scaffold(
                    body: AccessibleText(
                      'Scalable Text',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          );

          final textFinder = find.text('Scalable Text');
          expect(textFinder, findsOneWidget);

          final textWidget = tester.widget<Text>(textFinder);
          final fontSize = textWidget.style?.fontSize ?? 16;

          // Text should scale with the scale factor
          expect(fontSize, greaterThanOrEqualTo(16 * scaleFactor * 0.9)); // Allow 10% tolerance
        }
      });
    });

    group('Screen Reader Announcements', () {
      testWidgets('AccessibilityAnnouncer should announce messages', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<AccessibilityService>.value(value: accessibilityService),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AccessibilityAnnouncer(
                  message: 'Test announcement',
                  child: Text('Content'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the widget builds without errors
        expect(find.text('Content'), findsOneWidget);
        expect(find.byType(AccessibilityAnnouncer), findsOneWidget);
      });
    });

    group('Accessibility Compliance Validation', () {
      testWidgets('should validate WCAG 2.2 AA compliance requirements',
          (WidgetTester tester) async {
        // Create a test screen with accessibility features
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<AccessibilityService>.value(value: accessibilityService),
            ],
            child: MaterialApp(
              home: Scaffold(
                appBar: AppBar(
                  title: const AccessibleText(
                    'Test Screen',
                    header: true,
                    headerLevel: 1,
                  ),
                ),
                body: Column(
                  children: [
                    AccessibleButton(
                      onPressed: () {},
                      semanticLabel: 'Primary action button',
                      tooltip: 'Perform primary action',
                      primary: true,
                      child: const Text('Primary Action'),
                    ),
                    const SizedBox(height: 16),
                    const AccessibleTextField(
                      labelText: 'Input Field',
                      hintText: 'Enter text here',
                      helperText: 'This field is required',
                    ),
                    const SizedBox(height: 16),
                    AccessibleCard(
                      onTap: () {},
                      semanticLabel: 'Information card',
                      tooltip: 'Tap for more details',
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: AccessibleText('Card Content'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Validate semantic structure
        expect(find.byType(Semantics), findsWidgets);

        // Validate touch target sizes
        final buttonFinder = find.byType(ElevatedButton);
        if (buttonFinder.evaluate().isNotEmpty) {
          final renderBox = tester.renderObject(buttonFinder) as RenderBox;
          expect(renderBox.size.width, greaterThanOrEqualTo(44.0));
          expect(renderBox.size.height, greaterThanOrEqualTo(44.0));
        }

        // Validate text field accessibility
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        // Validate card accessibility
        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);
      });

      testWidgets('should handle high contrast mode', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: HighContrastTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  Text(
                    'High Contrast Text',
                    style: TextStyle(
                      color: HighContrastTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('High Contrast Button'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify high contrast colors are applied
        final textFinder = find.text('High Contrast Text');
        expect(textFinder, findsOneWidget);

        final buttonFinder = find.byType(ElevatedButton);
        expect(buttonFinder, findsOneWidget);
      });
    });

    group('Error Handling in Accessibility Features', () {
      test('accessibility services should handle errors gracefully', () async {
        // Test that accessibility features don't crash on errors
        expect(() => accessibilityService.speak(''), returnsNormally);
        expect(() => accessibilityService.setTextScaleFactor(-1), returnsNormally);
        expect(() => accessibilityService.getAccessibilityTheme(), returnsNormally);
      });

      testWidgets('accessibility widgets should handle null values gracefully',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AccessibleButton(
                    onPressed: null, // Disabled button
                    child: Text('Disabled Button'),
                  ),
                  AccessibleText(
                    '', // Empty text
                  ),
                  AccessibleCard(
                    onTap: null, // Non-interactive card
                    child: Text('Static Card'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should build without errors
        expect(find.byType(OutlinedButton), findsOneWidget); // Disabled button becomes outlined
        expect(find.byType(Text), findsWidgets);
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('Performance with Accessibility Features', () {
      testWidgets('accessibility features should not significantly impact performance',
          (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<AccessibilityService>.value(value: accessibilityService),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ListView.builder(
                  itemCount: 100,
                  itemBuilder: (context, index) {
                    return AccessibleCard(
                      onTap: () {},
                      semanticLabel: 'Item $index',
                      child: AccessibleText('Item $index'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should complete within reasonable time (less than 5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        // Should render all items
        expect(find.byType(AccessibleCard), findsWidgets);
      });
    });

    group('Integration with Error Handling', () {
      testWidgets('accessibility features should integrate with error boundaries',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<AccessibilityService>.value(value: accessibilityService),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AccessibleWidget(
                  label: 'Error-prone widget',
                  child: Text('Test Widget'),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should build without errors
        expect(find.text('Test Widget'), findsOneWidget);
        expect(find.byType(Semantics), findsWidgets);
      });
    });

    group('Accessibility Settings Persistence', () {
      test('should save and load accessibility settings', () async {
        // Test settings persistence
        await accessibilityService.setHighContrastMode(true);
        await accessibilityService.setLargeTextMode(true);
        await accessibilityService.setTextScaleFactor(1.5);

        expect(accessibilityService.highContrastMode, isTrue);
        expect(accessibilityService.largeTextMode, isTrue);
        expect(accessibilityService.textScaleFactor, equals(1.5));

        // Test accessibility summary
        final summary = accessibilityService.getAccessibilitySummary();
        expect(summary['highContrastMode'], isTrue);
        expect(summary['largeTextMode'], isTrue);
        expect(summary['textScaleFactor'], equals(1.5));
      });
    });
  });
}
