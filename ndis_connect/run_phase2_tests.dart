import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  print('🚀 NDIS Connect Phase 2 - Analyze & Develop Test Suite');
  print('=====================================================\n');

  final testType = args.isNotEmpty ? args[0] : 'all';
  Map<String, Map<String, dynamic>> results;

  switch (testType) {
    case 'unit':
      results = <String, Map<String, dynamic>>{};
      results['Unit Tests'] = await runUnitTests();
      break;
    case 'widget':
      results = <String, Map<String, dynamic>>{};
      results['Widget Tests'] = await runWidgetTests();
      break;
    case 'integration':
      results = <String, Map<String, dynamic>>{};
      results['Integration Tests'] = await runIntegrationTests();
      break;
    case 'accessibility':
      results = <String, Map<String, dynamic>>{};
      results['Accessibility Tests'] = await runAccessibilityTests();
      break;
    case 'performance':
      results = <String, Map<String, dynamic>>{};
      results['Performance Tests'] = await runPerformanceTests();
      break;
    case 'security':
      results = <String, Map<String, dynamic>>{};
      results['Security Audit'] = await runSecurityAudit();
      break;
    case 'all':
    default:
      results = await runAllTests();
      break;
  }

  // Generate comprehensive report
  generateComprehensiveReport(results);
}

Future<Map<String, Map<String, dynamic>>> runAllTests() async {
  print('🧪 Running Complete Test Suite...');
  print('==================================\n');

  final results = <String, Map<String, dynamic>>{};

  // Run all test suites
  results['Unit Tests'] = await runUnitTests();
  results['Widget Tests'] = await runWidgetTests();
  results['Integration Tests'] = await runIntegrationTests();
  results['Accessibility Tests'] = await runAccessibilityTests();
  results['Performance Tests'] = await runPerformanceTests();
  results['Security Audit'] = await runSecurityAudit();

  return results;
}

Future<Map<String, dynamic>> runUnitTests() async {
  print('🔬 Running Unit Tests...');
  print('------------------------');

  try {
    final stopwatch = Stopwatch()..start();

    final result = await Process.run(
      'flutter',
      ['test', 'test/unit/', '--coverage'],
      workingDirectory: Directory.current.path,
    );

    stopwatch.stop();

    final success = result.exitCode == 0;
    final output = result.stdout.toString();
    final errors = result.stderr.toString();

    // Parse test results
    final testCount = _parseTestCount(output);
    final passedTests = _parsePassedTests(output);
    final failedTests = testCount - passedTests;

    print(output);
    if (errors.isNotEmpty) {
      print('Errors: $errors');
    }

    return {
      'success': success,
      'execution_time_ms': stopwatch.elapsedMilliseconds,
      'total_tests': testCount,
      'passed_tests': passedTests,
      'failed_tests': failedTests,
      'coverage_generated': success,
      'status': success ? 'PASS' : 'FAIL',
      'output': output,
      'errors': errors,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'status': 'ERROR',
    };
  }
}

Future<Map<String, dynamic>> runWidgetTests() async {
  print('🎨 Running Widget Tests...');
  print('---------------------------');

  try {
    final stopwatch = Stopwatch()..start();

    final result = await Process.run(
      'flutter',
      ['test', 'test/widget/'],
      workingDirectory: Directory.current.path,
    );

    stopwatch.stop();

    final success = result.exitCode == 0;
    final output = result.stdout.toString();
    final errors = result.stderr.toString();

    final testCount = _parseTestCount(output);
    final passedTests = _parsePassedTests(output);
    final failedTests = testCount - passedTests;

    print(output);
    if (errors.isNotEmpty) {
      print('Errors: $errors');
    }

    return {
      'success': success,
      'execution_time_ms': stopwatch.elapsedMilliseconds,
      'total_tests': testCount,
      'passed_tests': passedTests,
      'failed_tests': failedTests,
      'status': success ? 'PASS' : 'FAIL',
      'output': output,
      'errors': errors,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'status': 'ERROR',
    };
  }
}

Future<Map<String, dynamic>> runIntegrationTests() async {
  print('🔗 Running Integration Tests...');
  print('--------------------------------');

  try {
    final stopwatch = Stopwatch()..start();

    final result = await Process.run(
      'flutter',
      ['test', 'integration_test/'],
      workingDirectory: Directory.current.path,
    );

    stopwatch.stop();

    final success = result.exitCode == 0;
    final output = result.stdout.toString();
    final errors = result.stderr.toString();

    final testCount = _parseTestCount(output);
    final passedTests = _parsePassedTests(output);
    final failedTests = testCount - passedTests;

    print(output);
    if (errors.isNotEmpty) {
      print('Errors: $errors');
    }

    return {
      'success': success,
      'execution_time_ms': stopwatch.elapsedMilliseconds,
      'total_tests': testCount,
      'passed_tests': passedTests,
      'failed_tests': failedTests,
      'status': success ? 'PASS' : 'FAIL',
      'output': output,
      'errors': errors,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'status': 'ERROR',
    };
  }
}

Future<Map<String, dynamic>> runAccessibilityTests() async {
  print('♿ Running Accessibility Tests...');
  print('----------------------------------');

  try {
    final stopwatch = Stopwatch()..start();

    // Run accessibility checker
    final result = await Process.run(
      'dart',
      ['run', 'accessibility_checker.dart'],
      workingDirectory: Directory.current.path,
    );

    stopwatch.stop();

    final success = result.exitCode == 0;
    final output = result.stdout.toString();
    final errors = result.stderr.toString();

    print(output);
    if (errors.isNotEmpty) {
      print('Errors: $errors');
    }

    // Parse accessibility score from output
    final accessibilityScore = _parseAccessibilityScore(output);

    return {
      'success': success,
      'execution_time_ms': stopwatch.elapsedMilliseconds,
      'accessibility_score': accessibilityScore,
      'wcag_compliant': accessibilityScore >= 80,
      'status': accessibilityScore >= 80 ? 'PASS' : 'NEEDS_IMPROVEMENT',
      'output': output,
      'errors': errors,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'status': 'ERROR',
    };
  }
}

Future<Map<String, dynamic>> runPerformanceTests() async {
  print('⚡ Running Performance Tests...');
  print('--------------------------------');

  try {
    final stopwatch = Stopwatch()..start();

    // Run performance profiler
    final result = await Process.run(
      'dart',
      ['run', 'performance_profiler.dart'],
      workingDirectory: Directory.current.path,
    );

    stopwatch.stop();

    final success = result.exitCode == 0;
    final output = result.stdout.toString();
    final errors = result.stderr.toString();

    print(output);
    if (errors.isNotEmpty) {
      print('Errors: $errors');
    }

    // Parse performance score from output
    final performanceScore = _parsePerformanceScore(output);

    return {
      'success': success,
      'execution_time_ms': stopwatch.elapsedMilliseconds,
      'performance_score': performanceScore,
      'meets_standards': performanceScore >= 80,
      'status': performanceScore >= 80 ? 'PASS' : 'NEEDS_OPTIMIZATION',
      'output': output,
      'errors': errors,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'status': 'ERROR',
    };
  }
}

Future<Map<String, dynamic>> runSecurityAudit() async {
  print('🔒 Running Security Audit...');
  print('-----------------------------');

  try {
    final stopwatch = Stopwatch()..start();

    // Run security audit
    final result = await Process.run(
      'dart',
      ['run', 'security_audit.dart'],
      workingDirectory: Directory.current.path,
    );

    stopwatch.stop();

    final success = result.exitCode == 0;
    final output = result.stdout.toString();
    final errors = result.stderr.toString();

    print(output);
    if (errors.isNotEmpty) {
      print('Errors: $errors');
    }

    // Parse security score from output
    final securityScore = _parseSecurityScore(output);

    return {
      'success': success,
      'execution_time_ms': stopwatch.elapsedMilliseconds,
      'security_score': securityScore,
      'secure': securityScore >= 80,
      'status': securityScore >= 80 ? 'PASS' : 'NEEDS_ATTENTION',
      'output': output,
      'errors': errors,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'status': 'ERROR',
    };
  }
}

int _parseTestCount(String output) {
  final regex = RegExp(r'(\d+) tests?');
  final match = regex.firstMatch(output);
  return match != null ? int.parse(match.group(1)!) : 0;
}

int _parsePassedTests(String output) {
  final regex = RegExp(r'(\d+) passed');
  final match = regex.firstMatch(output);
  return match != null ? int.parse(match.group(1)!) : 0;
}

double _parseAccessibilityScore(String output) {
  final regex = RegExp(r'Accessibility Score: ([\d.]+)%');
  final match = regex.firstMatch(output);
  return match != null ? double.parse(match.group(1)!) : 0.0;
}

double _parsePerformanceScore(String output) {
  final regex = RegExp(r'Performance Score: ([\d.]+)%');
  final match = regex.firstMatch(output);
  return match != null ? double.parse(match.group(1)!) : 0.0;
}

double _parseSecurityScore(String output) {
  final regex = RegExp(r'Security Score: ([\d.]+)%');
  final match = regex.firstMatch(output);
  return match != null ? double.parse(match.group(1)!) : 0.0;
}

void generateComprehensiveReport(Map<String, Map<String, dynamic>> results) {
  print('\n📊 NDIS Connect Phase 2 - Comprehensive Test Report');
  print('===================================================\n');

  int totalSuites = results.length;
  int passedSuites = 0;
  int totalTests = 0;
  int passedTests = 0;
  double overallScore = 0.0;

  // Calculate overall metrics
  for (final entry in results.entries) {
    final suiteName = entry.key;
    final data = entry.value;

    if (data['success'] == true) {
      passedSuites++;
    }

    if (data.containsKey('total_tests')) {
      totalTests += data['total_tests'] as int;
      passedTests += data['passed_tests'] as int;
    }

    if (data.containsKey('accessibility_score')) {
      overallScore += data['accessibility_score'] as double;
    } else if (data.containsKey('performance_score')) {
      overallScore += data['performance_score'] as double;
    } else if (data.containsKey('security_score')) {
      overallScore += data['security_score'] as double;
    } else if (data.containsKey('total_tests') && data.containsKey('passed_tests')) {
      final testScore = (data['passed_tests'] as int) / (data['total_tests'] as int) * 100;
      overallScore += testScore;
    }
  }

  overallScore = totalSuites > 0 ? overallScore / totalSuites : 0.0;

  // Print detailed results
  for (final entry in results.entries) {
    final suiteName = entry.key;
    final data = entry.value;
    final status = data['status'] ?? 'UNKNOWN';

    print('📋 $suiteName: $status');

    if (data.containsKey('execution_time_ms')) {
      print('   ⏱️  Execution Time: ${data['execution_time_ms']}ms');
    }

    if (data.containsKey('total_tests')) {
      print('   🧪 Tests: ${data['passed_tests']}/${data['total_tests']} passed');
    }

    if (data.containsKey('accessibility_score')) {
      print('   ♿ Accessibility Score: ${data['accessibility_score']}%');
    }

    if (data.containsKey('performance_score')) {
      print('   ⚡ Performance Score: ${data['performance_score']}%');
    }

    if (data.containsKey('security_score')) {
      print('   🔒 Security Score: ${data['security_score']}%');
    }

    if (data.containsKey('error')) {
      print('   ❌ Error: ${data['error']}');
    }

    print('');
  }

  // Print summary
  print('📊 Overall Summary');
  print('==================');
  print('Test Suites: $passedSuites/$totalSuites passed');
  print('Total Tests: $passedTests/$totalTests passed');
  print('Overall Score: ${overallScore.toStringAsFixed(1)}%');

  // Determine readiness
  final isReadyForProduction =
      passedSuites == totalSuites && overallScore >= 80 && passedTests == totalTests;

  print('\n🎯 Production Readiness: ${isReadyForProduction ? 'READY' : 'NOT READY'}');

  if (isReadyForProduction) {
    print(
        '\n🎉 Congratulations! The app meets all Phase 2 requirements and is ready for production.');
    print('✅ All test suites passed');
    print('✅ Quality standards met');
    print('✅ Security requirements satisfied');
    print('✅ Accessibility compliance achieved');
    print('✅ Performance benchmarks met');
  } else {
    print('\n⚠️  The app needs attention before production release:');

    for (final entry in results.entries) {
      final suiteName = entry.key;
      final data = entry.value;
      final status = data['status'] ?? 'UNKNOWN';

      if (status != 'PASS') {
        print('❌ $suiteName: $status');
      }
    }

    print('\n💡 Next Steps:');
    print('1. Fix failing tests and address issues');
    print('2. Improve areas with low scores');
    print('3. Re-run the test suite');
    print('4. Conduct manual testing');
    print('5. Prepare for app store submission');
  }

  // Generate recommendations
  print('\n💡 Recommendations for Store Submission:');
  print('1. Create app store assets (icons, screenshots, descriptions)');
  print('2. Prepare privacy policy and terms of service');
  print('3. Set up app store developer accounts');
  print('4. Configure app store metadata');
  print('5. Test on multiple devices and screen sizes');
  print('6. Conduct user acceptance testing');
  print('7. Prepare marketing materials');
  print('8. Set up analytics and crash reporting');

  // Save report to file
  final reportData = {
    'timestamp': DateTime.now().toIso8601String(),
    'overall_score': overallScore,
    'production_ready': isReadyForProduction,
    'test_suites': results,
    'summary': {
      'total_suites': totalSuites,
      'passed_suites': passedSuites,
      'total_tests': totalTests,
      'passed_tests': passedTests,
    }
  };

  final reportFile = File('test_report_${DateTime.now().millisecondsSinceEpoch}.json');
  reportFile.writeAsStringSync(jsonEncode(reportData));
  print('\n📄 Detailed report saved to: ${reportFile.path}');
}
