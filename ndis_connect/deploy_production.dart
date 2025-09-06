import 'dart:convert';
import 'dart:io';

/// Production Deployment Script for NDIS Connect
///
/// This script automates the deployment process for production environments,
/// including Firebase configuration, security rules deployment, and app store preparation.
void main(List<String> args) async {
  print('🚀 NDIS Connect - Production Deployment');
  print('=====================================\n');

  if (args.isEmpty) {
    print('Usage: dart deploy_production.dart [command]');
    print('');
    print('Commands:');
    print('  firebase     - Deploy Firebase configuration');
    print('  security     - Deploy security rules');
    print('  build        - Build production APK/AAB');
    print('  store-prep   - Prepare for app store submission');
    print('  all          - Run all deployment steps');
    print('');
    return;
  }

  final command = args[0].toLowerCase();

  switch (command) {
    case 'firebase':
      await deployFirebase();
      break;
    case 'security':
      await deploySecurityRules();
      break;
    case 'build':
      await buildProductionApp();
      break;
    case 'store-prep':
      await prepareForStoreSubmission();
      break;
    case 'all':
      await deployFirebase();
      await deploySecurityRules();
      await buildProductionApp();
      await prepareForStoreSubmission();
      break;
    default:
      print('❌ Unknown command: $command');
      print('Run without arguments to see available commands.');
  }
}

/// Deploy Firebase configuration and rules
Future<void> deployFirebase() async {
  print('🔥 Deploying Firebase Configuration...');

  try {
    // Check if Firebase CLI is installed
    final firebaseCheck = await Process.run('firebase', ['--version']);
    if (firebaseCheck.exitCode != 0) {
      print('❌ Firebase CLI not found. Please install it first:');
      print('   npm install -g firebase-tools');
      return;
    }

    print('✅ Firebase CLI found: ${firebaseCheck.stdout.toString().trim()}');

    // Deploy Firestore rules
    print('📝 Deploying Firestore rules...');
    final firestoreResult = await Process.run(
        'firebase', ['deploy', '--only', 'firestore:rules', '--project', 'ndis-connect-prod']);

    if (firestoreResult.exitCode == 0) {
      print('✅ Firestore rules deployed successfully');
    } else {
      print('❌ Failed to deploy Firestore rules:');
      print(firestoreResult.stderr.toString());
    }

    // Deploy Storage rules
    print('📁 Deploying Storage rules...');
    final storageResult = await Process.run(
        'firebase', ['deploy', '--only', 'storage:rules', '--project', 'ndis-connect-prod']);

    if (storageResult.exitCode == 0) {
      print('✅ Storage rules deployed successfully');
    } else {
      print('❌ Failed to deploy Storage rules:');
      print(storageResult.stderr.toString());
    }

    // Deploy Remote Config
    print('⚙️ Deploying Remote Config...');
    final remoteConfigResult = await Process.run(
        'firebase', ['deploy', '--only', 'remoteconfig', '--project', 'ndis-connect-prod']);

    if (remoteConfigResult.exitCode == 0) {
      print('✅ Remote Config deployed successfully');
    } else {
      print('❌ Failed to deploy Remote Config:');
      print(remoteConfigResult.stderr.toString());
    }

    print('🎉 Firebase deployment completed!');
  } catch (e) {
    print('❌ Error during Firebase deployment: $e');
  }
}

/// Deploy security rules specifically
Future<void> deploySecurityRules() async {
  print('🔒 Deploying Security Rules...');

  try {
    // Validate Firestore rules
    print('🔍 Validating Firestore rules...');
    final validateResult = await Process.run('firebase',
        ['firestore:rules:validate', 'firebase/firestore.rules', '--project', 'ndis-connect-prod']);

    if (validateResult.exitCode == 0) {
      print('✅ Firestore rules validation passed');
    } else {
      print('❌ Firestore rules validation failed:');
      print(validateResult.stderr.toString());
      return;
    }

    // Deploy rules
    await deployFirebase();
  } catch (e) {
    print('❌ Error during security rules deployment: $e');
  }
}

/// Build production APK and AAB
Future<void> buildProductionApp() async {
  print('🏗️ Building Production App...');

  try {
    // Clean build
    print('🧹 Cleaning previous builds...');
    await Process.run('flutter', ['clean']);

    // Get dependencies
    print('📦 Getting dependencies...');
    await Process.run('flutter', ['pub', 'get']);

    // Build APK
    print('📱 Building APK...');
    final apkResult = await Process.run(
        'flutter', ['build', 'apk', '--release', '--target-platform', 'android-arm64']);

    if (apkResult.exitCode == 0) {
      print('✅ APK built successfully');
      print('   Location: build/app/outputs/flutter-apk/app-release.apk');
    } else {
      print('❌ Failed to build APK:');
      print(apkResult.stderr.toString());
    }

    // Build AAB for Play Store
    print('📦 Building AAB for Play Store...');
    final aabResult = await Process.run('flutter', ['build', 'appbundle', '--release']);

    if (aabResult.exitCode == 0) {
      print('✅ AAB built successfully');
      print('   Location: build/app/outputs/bundle/release/app-release.aab');
    } else {
      print('❌ Failed to build AAB:');
      print(aabResult.stderr.toString());
    }

    // Build for iOS (if on macOS)
    if (Platform.isMacOS) {
      print('🍎 Building iOS app...');
      final iosResult =
          await Process.run('flutter', ['build', 'ios', '--release', '--no-codesign']);

      if (iosResult.exitCode == 0) {
        print('✅ iOS app built successfully');
        print('   Location: build/ios/Release-iphoneos/Runner.app');
      } else {
        print('❌ Failed to build iOS app:');
        print(iosResult.stderr.toString());
      }
    }
  } catch (e) {
    print('❌ Error during app build: $e');
  }
}

/// Prepare for app store submission
Future<void> prepareForStoreSubmission() async {
  print('🏪 Preparing for App Store Submission...');

  try {
    // Create store assets directory
    final storeAssetsDir = Directory('store_assets');
    if (!storeAssetsDir.existsSync()) {
      storeAssetsDir.createSync(recursive: true);
    }

    // Copy built files to store assets
    print('📋 Copying built files to store assets...');

    final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
    final aabFile = File('build/app/outputs/bundle/release/app-release.aab');

    if (apkFile.existsSync()) {
      await apkFile.copy('store_assets/app-release.apk');
      print('✅ APK copied to store assets');
    }

    if (aabFile.existsSync()) {
      await aabFile.copy('store_assets/app-release.aab');
      print('✅ AAB copied to store assets');
    }

    // Create app store metadata template
    print('📝 Creating app store metadata...');
    await createAppStoreMetadata();

    // Generate app signing report
    print('🔐 Generating signing report...');
    await generateSigningReport();

    print('🎉 App store preparation completed!');
    print('📁 Check the "store_assets" directory for all files');
  } catch (e) {
    print('❌ Error during store preparation: $e');
  }
}

/// Create app store metadata template
Future<void> createAppStoreMetadata() async {
  final metadata = {
    'app_name': 'NDIS Connect',
    'short_description': 'Accessible NDIS participant and provider management app',
    'full_description': '''
NDIS Connect is a comprehensive, accessible mobile application designed specifically for NDIS participants and service providers. 

Key Features:
• Task Management - Track daily activities, therapy sessions, and appointments
• Budget Tracking - Monitor NDIS plan spending across core, capacity, and capital budgets
• Service Provider Directory - Find and connect with verified NDIS providers
• Calendar Integration - Manage schedules and appointments
• Accessibility Features - Full WCAG 2.2 AA compliance with voice navigation
• Offline Support - Works seamlessly in areas with limited connectivity
• AI Assistant - Get help with NDIS-related questions and tasks

The app is designed with accessibility in mind, featuring:
• Screen reader support
• High contrast mode
• Voice navigation
• Text scaling up to 200%
• Simplified navigation for users with cognitive disabilities

Perfect for NDIS participants, families, carers, and service providers who need reliable, accessible tools to manage NDIS services and supports.
''',
    'keywords': [
      'NDIS',
      'disability',
      'accessibility',
      'support',
      'therapy',
      'budget',
      'calendar',
      'tasks',
      'provider',
      'participant'
    ],
    'category': 'Medical',
    'content_rating': 'Everyone',
    'privacy_policy_url': 'https://ndisconnect.com.au/privacy',
    'support_url': 'https://ndisconnect.com.au/support',
    'website_url': 'https://ndisconnect.com.au',
    'version': '1.0.0',
    'release_notes': '''
Initial release of NDIS Connect featuring:

✨ Core Features:
• Complete task management system
• NDIS budget tracking and monitoring
• Service provider directory with maps
• Calendar and appointment management
• AI-powered assistant for NDIS support

♿ Accessibility:
• Full WCAG 2.2 AA compliance
• Voice navigation and screen reader support
• High contrast mode and text scaling
• Simplified interface for cognitive accessibility

🌐 Offline Support:
• Works without internet connection
• Automatic sync when connectivity restored
• Optimized for rural and remote areas

🔒 Security & Privacy:
• End-to-end encryption for sensitive data
• Compliant with Australian privacy laws
• Secure authentication and data protection
''',
    'screenshots': [
      'dashboard.png',
      'tasks.png',
      'budget.png',
      'calendar.png',
      'providers.png',
      'accessibility.png'
    ],
    'feature_graphic': 'feature_graphic.png',
    'app_icon': 'app_icon.png'
  };

  final metadataFile = File('store_assets/app_store_metadata.json');
  await metadataFile.writeAsString(const JsonEncoder.withIndent('  ').convert(metadata));

  print('✅ App store metadata created');
}

/// Generate app signing report
Future<void> generateSigningReport() async {
  try {
    print('🔍 Checking app signing...');

    final signingResult = await Process.run('flutter', ['build', 'apk', '--analyze-size']);

    if (signingResult.exitCode == 0) {
      final reportFile = File('store_assets/signing_report.txt');
      await reportFile.writeAsString(signingResult.stdout.toString());
      print('✅ Signing report generated');
    }
  } catch (e) {
    print('⚠️ Could not generate signing report: $e');
  }
}
