import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class StorageEncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _hiveKeyName = 'hive_encryption_key';
  static const String _userDataKeyName = 'user_data_key';
  static const String _sessionKeyName = 'session_key';
  static const String _biometricKeyName = 'biometric_key';

  // Generate secure encryption key
  Future<enc.Key> _generateSecureKey() async {
    return enc.Key.fromSecureRandom(32);
  }

  // Generate secure IV
  Future<enc.IV> _generateSecureIV() async {
    return enc.IV.fromSecureRandom(16);
  }

  // Get or create Hive encryption key
  Future<enc.Key> getHiveKey() async {
    try {
      final val = await _secureStorage.read(key: _hiveKeyName);
      if (val == null) {
        final key = await _generateSecureKey();
        await _secureStorage.write(key: _hiveKeyName, value: key.base64);
        return key;
      }
      return enc.Key.fromBase64(val);
    } catch (e) {
      // Fallback to generating a new key
      final key = await _generateSecureKey();
      await _secureStorage.write(key: _hiveKeyName, value: key.base64);
      return key;
    }
  }

  // Get or create user data encryption key
  Future<enc.Key> getUserDataKey() async {
    try {
      final val = await _secureStorage.read(key: _userDataKeyName);
      if (val == null) {
        final key = await _generateSecureKey();
        await _secureStorage.write(key: _userDataKeyName, value: key.base64);
        return key;
      }
      return enc.Key.fromBase64(val);
    } catch (e) {
      final key = await _generateSecureKey();
      await _secureStorage.write(key: _userDataKeyName, value: key.base64);
      return key;
    }
  }

  // Get or create session key
  Future<enc.Key> getSessionKey() async {
    try {
      final val = await _secureStorage.read(key: _sessionKeyName);
      if (val == null) {
        final key = await _generateSecureKey();
        await _secureStorage.write(key: _sessionKeyName, value: key.base64);
        return key;
      }
      return enc.Key.fromBase64(val);
    } catch (e) {
      final key = await _generateSecureKey();
      await _secureStorage.write(key: _sessionKeyName, value: key.base64);
      return key;
    }
  }

  // Encrypt sensitive data
  Future<String> encryptData(String data, {String? keyName}) async {
    try {
      final key = keyName == 'user' ? await getUserDataKey() : await getSessionKey();
      final iv = await _generateSecureIV();
      final encrypter = enc.Encrypter(enc.AES(key));

      final encrypted = encrypter.encrypt(data, iv: iv);

      // Combine IV and encrypted data
      final combined = '${iv.base64}:${encrypted.base64}';
      return combined;
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  // Decrypt sensitive data
  Future<String> decryptData(String encryptedData, {String? keyName}) async {
    try {
      final key = keyName == 'user' ? await getUserDataKey() : await getSessionKey();
      final encrypter = enc.Encrypter(enc.AES(key));

      // Split IV and encrypted data
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  // Hash sensitive data (one-way)
  String hashData(String data, {String salt = ''}) {
    final bytes = utf8.encode(data + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate secure random string
  String generateSecureToken({int length = 32}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Generate UUID v4
  String generateUUID() {
    return const Uuid().v4();
  }

  // Store encrypted sensitive data
  Future<void> storeEncryptedData(String key, String data, {String? keyName}) async {
    try {
      final encryptedData = await encryptData(data, keyName: keyName);
      await _secureStorage.write(key: key, value: encryptedData);
    } catch (e) {
      throw Exception('Failed to store encrypted data: $e');
    }
  }

  // Retrieve and decrypt sensitive data
  Future<String?> getEncryptedData(String key, {String? keyName}) async {
    try {
      final encryptedData = await _secureStorage.read(key: key);
      if (encryptedData == null) return null;

      return await decryptData(encryptedData, keyName: keyName);
    } catch (e) {
      throw Exception('Failed to retrieve encrypted data: $e');
    }
  }

  // Delete encrypted data
  Future<void> deleteEncryptedData(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw Exception('Failed to delete encrypted data: $e');
    }
  }

  // Clear all encrypted data
  Future<void> clearAllEncryptedData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear encrypted data: $e');
    }
  }

  // Validate data integrity
  bool validateDataIntegrity(String data, String hash, {String salt = ''}) {
    final calculatedHash = hashData(data, salt: salt);
    return calculatedHash == hash;
  }

  // Secure data sanitization
  String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '')
        .replaceAll(RegExp("[<>\"']"), '')
        .trim();
  }

  // Check if device supports secure storage
  Future<bool> isSecureStorageSupported() async {
    try {
      await _secureStorage.write(key: 'test_key', value: 'test_value');
      final value = await _secureStorage.read(key: 'test_key');
      await _secureStorage.delete(key: 'test_key');
      return value == 'test_value';
    } catch (e) {
      return false;
    }
  }

  // Get storage security status
  Future<Map<String, dynamic>> getSecurityStatus() async {
    try {
      final isSupported = await isSecureStorageSupported();
      final hasHiveKey = await _secureStorage.read(key: _hiveKeyName) != null;
      final hasUserDataKey = await _secureStorage.read(key: _userDataKeyName) != null;
      final hasSessionKey = await _secureStorage.read(key: _sessionKeyName) != null;

      return {
        'secureStorageSupported': isSupported,
        'hiveKeyExists': hasHiveKey,
        'userDataKeyExists': hasUserDataKey,
        'sessionKeyExists': hasSessionKey,
        'securityLevel': isSupported ? 'high' : 'medium',
        'lastChecked': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'secureStorageSupported': false,
        'hiveKeyExists': false,
        'userDataKeyExists': false,
        'sessionKeyExists': false,
        'securityLevel': 'low',
        'error': e.toString(),
        'lastChecked': DateTime.now().toIso8601String(),
      };
    }
  }

  // Rotate encryption keys (for enhanced security)
  Future<void> rotateKeys() async {
    try {
      // Generate new keys
      final newHiveKey = await _generateSecureKey();
      final newUserDataKey = await _generateSecureKey();
      final newSessionKey = await _generateSecureKey();

      // Store new keys
      await _secureStorage.write(key: _hiveKeyName, value: newHiveKey.base64);
      await _secureStorage.write(key: _userDataKeyName, value: newUserDataKey.base64);
      await _secureStorage.write(key: _sessionKeyName, value: newSessionKey.base64);
    } catch (e) {
      throw Exception('Failed to rotate keys: $e');
    }
  }

  // Biometric authentication support
  Future<void> storeBiometricKey(String key) async {
    try {
      await _secureStorage.write(key: _biometricKeyName, value: key);
    } catch (e) {
      throw Exception('Failed to store biometric key: $e');
    }
  }

  // Retrieve biometric key
  Future<String?> getBiometricKey() async {
    try {
      return await _secureStorage.read(key: _biometricKeyName);
    } catch (e) {
      return null;
    }
  }
}
