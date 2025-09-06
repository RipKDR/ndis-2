import 'dart:io';

void main(List<String> args) async {
  print('🧪 NDIS Connect Test Runner');
  print('============================\n');

  final testType = args.isNotEmpty ? args[0] : 'all';
  
  switch (testType) {
    case 'unit':
      await runUnitTests();
      break;
    case 'widget':
      await runWidgetTests();
      break;
    case 'integration':
      await runIntegrationTests();
      break;
    case 'accessibility':
      await runAccessibilityTests();
      break;
    case 'performance':
      await runPerformanceTests();
      break;
    case 'all':
    default:
      await runAllTests();
      break;
  }
}

Future<void> runUnitTests() async {
  print('🔬 Running Unit Tests...');
  print('------------------------');
  
  final result = await Process.run(
    'flutter',
    ['test', 'test/unit/'],
    workingDirectory: Directory.current.path,
  );
  
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }
  
  print('Unit tests completed with exit code: ${result.exitCode}\n');
}

Future<void> runWidgetTests() async {
  print('🎨 Running Widget Tests...');
  print('---------------------------');
  
  final result = await Process.run(
    'flutter',
    ['test', 'test/widget/'],
    workingDirectory: Directory.current.path,
  );
  
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }
  
  print('Widget tests completed with exit code: ${result.exitCode}\n');
}

Future<void> runIntegrationTests() async {
  print('🔗 Running Integration Tests...');
  print('--------------------------------');
  
  final result = await Process.run(
    'flutter',
    ['test', 'integration_test/'],
    workingDirectory: Directory.current.path,
  );
  
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }
  
  print('Integration tests completed with exit code: ${result.exitCode}\n');
}

Future<void> runAccessibilityTests() async {
  print('♿ Running Accessibility Tests...');
  print('----------------------------------');
  
  final result = await Process.run(
    'flutter',
    ['test', 'test/accessibility/'],
    workingDirectory: Directory.current.path,
  );
  
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }
  
  print('Accessibility tests completed with exit code: ${result.exitCode}\n');
}

Future<void> runPerformanceTests() async {
  print('⚡ Running Performance Tests...');
  print('--------------------------------');
  
  final result = await Process.run(
    'flutter',
    ['test', 'test/performance/'],
    workingDirectory: Directory.current.path,
  );
  
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('Errors: ${result.stderr}');
  }
  
  print('Performance tests completed with exit code: ${result.exitCode}\n');
}

Future<void> runAllTests() async {
  print('🚀 Running All Tests...');
  print('========================\n');
  
  final testSuites = [
    ('Unit Tests', runUnitTests),
    ('Widget Tests', runWidgetTests),
    ('Integration Tests', runIntegrationTests),
    ('Accessibility Tests', runAccessibilityTests),
    ('Performance Tests', runPerformanceTests),
  ];
  
  int totalFailures = 0;
  
  for (final (name, testFunction) in testSuites) {
    try {
      await testFunction();
    } catch (e) {
      print('❌ $name failed: $e');
      totalFailures++;
    }
  }
  
  print('📊 Test Summary');
  print('================');
  print('Total test suites: ${testSuites.length}');
  print('Failed test suites: $totalFailures');
  print('Success rate: ${((testSuites.length - totalFailures) / testSuites.length * 100).toStringAsFixed(1)}%');
  
  if (totalFailures == 0) {
    print('\n🎉 All tests passed! The app is ready for production.');
  } else {
    print('\n⚠️  Some tests failed. Please review and fix issues before production.');
  }
}
