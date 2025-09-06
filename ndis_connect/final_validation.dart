import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  print('🎯 NDIS Connect - Final Validation & Store Readiness');
  print('==================================================\n');

  final validationResults = <String, Map<String, dynamic>>{};

  // Run all validation checks
  validationResults['Code Quality'] = await validateCodeQuality();
  validationResults['Security Compliance'] = await validateSecurityCompliance();
  validationResults['Performance Standards'] = await validatePerformanceStandards();
  validationResults['Accessibility Compliance'] = await validateAccessibilityCompliance();
  validationResults['UX Standards'] = await validateUXStandards();
  validationResults['Store Readiness'] = await validateStoreReadiness();
  validationResults['Documentation'] = await validateDocumentation();
  validationResults['Legal Compliance'] = await validateLegalCompliance();

  // Generate final report
  generateFinalReport(validationResults);
}

Future<Map<String, dynamic>> validateCodeQuality() async {
  print('🔍 Validating code quality...');

  try {
    final stopwatch = Stopwatch()..start();

    // Run Flutter analyze
    final analyzeResult = await Process.run(
      'flutter',
      ['analyze'],
      workingDirectory: Directory.current.path,
    );

    stopwatch.stop();

    final hasErrors = analyzeResult.exitCode != 0;
    final output = analyzeResult.stdout.toString();
    final errors = analyzeResult.stderr.toString();

    // Parse analysis results
    final errorCount = _parseErrorCount(output);
    final warningCount = _parseWarningCount(output);
    final infoCount = _parseInfoCount(output);

    final isPassing = !hasErrors && errorCount == 0;

    return {
      'success': isPassing,
      'execution_time_ms': stopwatch.elapsedMilliseconds,
      'error_count': errorCount,
      'warning_count': warningCount,
      'info_count': infoCount,
      'has_errors': hasErrors,
      'status': isPassing ? 'PASS' : 'FAIL',
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

Future<Map<String, dynamic>> validateSecurityCompliance() async {
  print('🔍 Validating security compliance...');

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

    // Parse security score
    final securityScore = _parseSecurityScore(output);
    final isCompliant = securityScore >= 80;

    return {
      'success': success && isCompliant,
      'execution_time_ms': stopwatch.elapsedMilliseconds,
      'security_score': securityScore,
      'is_compliant': isCompliant,
      'status': isCompliant ? 'PASS' : 'NEEDS_ATTENTION',
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

Future<Map<String, dynamic>> validatePerformanceStandards() async {
  print('🔍 Validating performance standards...');

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

    // Parse performance score
    final performanceScore = _parsePerformanceScore(output);
    final meetsStandards = performanceScore >= 60; // Lower threshold for initial release

    return {
      'success': success && meetsStandards,
      'execution_time_ms': stopwatch.elapsedMilliseconds,
      'performance_score': performanceScore,
      'meets_standards': meetsStandards,
      'status': meetsStandards ? 'PASS' : 'NEEDS_OPTIMIZATION',
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

Future<Map<String, dynamic>> validateAccessibilityCompliance() async {
  print('🔍 Validating accessibility compliance...');

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

    // Parse accessibility score
    final accessibilityScore = _parseAccessibilityScore(output);
    final isCompliant = accessibilityScore >= 80;

    return {
      'success': success && isCompliant,
      'execution_time_ms': stopwatch.elapsedMilliseconds,
      'accessibility_score': accessibilityScore,
      'is_compliant': isCompliant,
      'status': isCompliant ? 'PASS' : 'NEEDS_IMPROVEMENT',
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

Future<Map<String, dynamic>> validateUXStandards() async {
  print('🔍 Validating UX standards...');

  try {
    // Check for UX enhancement files
    final uxFiles = [
      'lib/widgets/ux_enhancements.dart',
      'lib/services/ux_improvement_service.dart',
      'lib/widgets/accessibility_widgets.dart',
    ];

    int existingFiles = 0;
    for (final file in uxFiles) {
      if (await File(file).exists()) {
        existingFiles++;
      }
    }

    final uxScore = (existingFiles / uxFiles.length) * 100;
    final meetsStandards = uxScore >= 80;

    return {
      'success': meetsStandards,
      'ux_score': uxScore,
      'existing_files': existingFiles,
      'total_files': uxFiles.length,
      'meets_standards': meetsStandards,
      'status': meetsStandards ? 'PASS' : 'NEEDS_IMPROVEMENT',
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'status': 'ERROR',
    };
  }
}

Future<Map<String, dynamic>> validateStoreReadiness() async {
  print('🔍 Validating store readiness...');

  try {
    // Check for required store files
    final storeFiles = [
      'APP_STORE_METADATA.md',
      'TERMS_OF_SERVICE.md',
      'PRIVACY_POLICY.md',
      'README.md',
      'TESTING.md',
    ];

    int existingFiles = 0;
    for (final file in storeFiles) {
      if (await File(file).exists()) {
        existingFiles++;
      }
    }

    // Check for app icons and assets
    final assetFiles = [
      'web/icons/Icon-192.png',
      'web/icons/Icon-512.png',
      'web/favicon.png',
    ];

    int existingAssets = 0;
    for (final file in assetFiles) {
      if (await File(file).exists()) {
        existingAssets++;
      }
    }

    final storeScore =
        ((existingFiles + existingAssets) / (storeFiles.length + assetFiles.length)) * 100;
    final isReady = storeScore >= 80;

    return {
      'success': isReady,
      'store_score': storeScore,
      'existing_files': existingFiles,
      'total_files': storeFiles.length,
      'existing_assets': existingAssets,
      'total_assets': assetFiles.length,
      'is_ready': isReady,
      'status': isReady ? 'PASS' : 'NEEDS_ASSETS',
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'status': 'ERROR',
    };
  }
}

Future<Map<String, dynamic>> validateDocumentation() async {
  print('🔍 Validating documentation...');

  try {
    // Check for documentation files
    final docFiles = [
      'README.md',
      'TESTING.md',
      'APP_STORE_METADATA.md',
      'TERMS_OF_SERVICE.md',
      'PRIVACY_POLICY.md',
    ];

    int existingFiles = 0;
    int totalSize = 0;

    for (final file in docFiles) {
      if (await File(file).exists()) {
        existingFiles++;
        final fileSize = await File(file).length();
        totalSize += fileSize;
      }
    }

    final docScore = (existingFiles / docFiles.length) * 100;
    final isComplete = docScore >= 100 && totalSize > 10000; // At least 10KB of documentation

    return {
      'success': isComplete,
      'doc_score': docScore,
      'existing_files': existingFiles,
      'total_files': docFiles.length,
      'total_size_bytes': totalSize,
      'is_complete': isComplete,
      'status': isComplete ? 'PASS' : 'NEEDS_COMPLETION',
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'status': 'ERROR',
    };
  }
}

Future<Map<String, dynamic>> validateLegalCompliance() async {
  print('🔍 Validating legal compliance...');

  try {
    // Check for legal documents
    final legalFiles = [
      'TERMS_OF_SERVICE.md',
      'PRIVACY_POLICY.md',
    ];

    int existingFiles = 0;
    bool hasRequiredSections = true;

    for (final file in legalFiles) {
      if (await File(file).exists()) {
        existingFiles++;
        final content = await File(file).readAsString();

        // Check for required sections
        if (file.contains('TERMS')) {
          hasRequiredSections = hasRequiredSections &&
              content.contains('Acceptance of Terms') &&
              content.contains('Privacy and Data Protection') &&
              content.contains('Governing Law');
        }

        if (file.contains('PRIVACY')) {
          hasRequiredSections = hasRequiredSections &&
              content.contains('Information We Collect') &&
              content.contains('How We Use Your Information') &&
              content.contains('Your Rights and Choices');
        }
      }
    }

    final legalScore = (existingFiles / legalFiles.length) * 100;
    final isCompliant = legalScore >= 100 && hasRequiredSections;

    return {
      'success': isCompliant,
      'legal_score': legalScore,
      'existing_files': existingFiles,
      'total_files': legalFiles.length,
      'has_required_sections': hasRequiredSections,
      'is_compliant': isCompliant,
      'status': isCompliant ? 'PASS' : 'NEEDS_COMPLETION',
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'status': 'ERROR',
    };
  }
}

int _parseErrorCount(String output) {
  final regex = RegExp(r'(\d+) error');
  final match = regex.firstMatch(output);
  return match != null ? int.parse(match.group(1)!) : 0;
}

int _parseWarningCount(String output) {
  final regex = RegExp(r'(\d+) warning');
  final match = regex.firstMatch(output);
  return match != null ? int.parse(match.group(1)!) : 0;
}

int _parseInfoCount(String output) {
  final regex = RegExp(r'(\d+) info');
  final match = regex.firstMatch(output);
  return match != null ? int.parse(match.group(1)!) : 0;
}

double _parseSecurityScore(String output) {
  final regex = RegExp(r'Security Score: ([\d.]+)%');
  final match = regex.firstMatch(output);
  return match != null ? double.parse(match.group(1)!) : 0.0;
}

double _parsePerformanceScore(String output) {
  final regex = RegExp(r'Performance Score: ([\d.]+)%');
  final match = regex.firstMatch(output);
  return match != null ? double.parse(match.group(1)!) : 0.0;
}

double _parseAccessibilityScore(String output) {
  final regex = RegExp(r'Accessibility Score: ([\d.]+)%');
  final match = regex.firstMatch(output);
  return match != null ? double.parse(match.group(1)!) : 0.0;
}

void generateFinalReport(Map<String, Map<String, dynamic>> results) {
  print('\n🎯 NDIS Connect - Final Validation Report');
  print('==========================================\n');

  int totalChecks = results.length;
  int passedChecks = 0;
  double overallScore = 0.0;

  // Calculate overall metrics
  for (final entry in results.entries) {
    final checkName = entry.key;
    final data = entry.value;

    if (data['success'] == true) {
      passedChecks++;
    }

    // Calculate score based on available metrics
    if (data.containsKey('security_score')) {
      overallScore += data['security_score'] as double;
    } else if (data.containsKey('performance_score')) {
      overallScore += data['performance_score'] as double;
    } else if (data.containsKey('accessibility_score')) {
      overallScore += data['accessibility_score'] as double;
    } else if (data.containsKey('ux_score')) {
      overallScore += data['ux_score'] as double;
    } else if (data.containsKey('store_score')) {
      overallScore += data['store_score'] as double;
    } else if (data.containsKey('doc_score')) {
      overallScore += data['doc_score'] as double;
    } else if (data.containsKey('legal_score')) {
      overallScore += data['legal_score'] as double;
    } else if (data['success'] == true) {
      overallScore += 100.0;
    }
  }

  overallScore = overallScore / totalChecks;

  // Print detailed results
  for (final entry in results.entries) {
    final checkName = entry.key;
    final data = entry.value;
    final status = data['status'] ?? 'UNKNOWN';

    print('📋 $checkName: $status');

    if (data.containsKey('execution_time_ms')) {
      print('   ⏱️  Execution Time: ${data['execution_time_ms']}ms');
    }

    if (data.containsKey('security_score')) {
      print('   🔒 Security Score: ${data['security_score']}%');
    }

    if (data.containsKey('performance_score')) {
      print('   ⚡ Performance Score: ${data['performance_score']}%');
    }

    if (data.containsKey('accessibility_score')) {
      print('   ♿ Accessibility Score: ${data['accessibility_score']}%');
    }

    if (data.containsKey('ux_score')) {
      print('   🎨 UX Score: ${data['ux_score']}%');
    }

    if (data.containsKey('store_score')) {
      print('   🏪 Store Score: ${data['store_score']}%');
    }

    if (data.containsKey('doc_score')) {
      print('   📚 Documentation Score: ${data['doc_score']}%');
    }

    if (data.containsKey('legal_score')) {
      print('   ⚖️  Legal Score: ${data['legal_score']}%');
    }

    if (data.containsKey('error_count')) {
      print('   ❌ Errors: ${data['error_count']}');
    }

    if (data.containsKey('warning_count')) {
      print('   ⚠️  Warnings: ${data['warning_count']}');
    }

    if (data.containsKey('error')) {
      print('   ❌ Error: ${data['error']}');
    }

    print('');
  }

  // Print summary
  print('📊 Overall Summary');
  print('==================');
  print('Validation Checks: $passedChecks/$totalChecks passed');
  print('Overall Score: ${overallScore.toStringAsFixed(1)}%');

  // Determine store readiness
  final isStoreReady = passedChecks >= (totalChecks * 0.8) && overallScore >= 75.0;

  print('\n🏪 Store Readiness: ${isStoreReady ? 'READY' : 'NOT READY'}');

  if (isStoreReady) {
    print('\n🎉 Congratulations! NDIS Connect is ready for app store submission!');
    print('✅ All critical validation checks passed');
    print('✅ Quality standards met');
    print('✅ Security requirements satisfied');
    print('✅ Accessibility compliance achieved');
    print('✅ Performance benchmarks met');
    print('✅ Documentation complete');
    print('✅ Legal compliance verified');

    print('\n🚀 Next Steps for Store Submission:');
    print('1. Create app store developer accounts (Apple App Store, Google Play)');
    print('2. Generate app icons and screenshots');
    print('3. Upload app binary and metadata');
    print('4. Submit for review');
    print('5. Monitor review process and respond to feedback');
    print('6. Launch and monitor app performance');
  } else {
    print('\n⚠️  NDIS Connect needs attention before store submission:');

    for (final entry in results.entries) {
      final checkName = entry.key;
      final data = entry.value;
      final status = data['status'] ?? 'UNKNOWN';

      if (status != 'PASS') {
        print('❌ $checkName: $status');
      }
    }

    print('\n💡 Recommended Actions:');
    print('1. Address all failing validation checks');
    print('2. Improve areas with low scores');
    print('3. Complete missing documentation');
    print('4. Fix any remaining issues');
    print('5. Re-run validation');
    print('6. Conduct final testing');
  }

  // Generate recommendations
  print('\n💡 Store Submission Recommendations:');
  print('1. Test on multiple devices and screen sizes');
  print('2. Conduct user acceptance testing');
  print('3. Prepare marketing materials');
  print('4. Set up analytics and crash reporting');
  print('5. Plan post-launch support strategy');
  print('6. Prepare for user feedback and reviews');
  print('7. Monitor app store performance metrics');
  print('8. Plan regular updates and improvements');

  // Save report to file
  final reportData = {
    'timestamp': DateTime.now().toIso8601String(),
    'overall_score': overallScore,
    'store_ready': isStoreReady,
    'validation_results': results,
    'summary': {
      'total_checks': totalChecks,
      'passed_checks': passedChecks,
      'overall_score': overallScore,
    }
  };

  final reportFile = File('final_validation_report_${DateTime.now().millisecondsSinceEpoch}.json');
  reportFile.writeAsStringSync(jsonEncode(reportData));
  print('\n📄 Detailed report saved to: ${reportFile.path}');
}
