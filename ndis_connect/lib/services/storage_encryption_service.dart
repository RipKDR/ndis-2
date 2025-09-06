import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageEncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<enc.Key> getHiveKey() async {
    final val = await _secureStorage.read(key: 'hive_key');
    if (val == null) {
      final key = enc.Key.fromSecureRandom(32);
      await _secureStorage.write(key: 'hive_key', value: key.base64);
      return key;
    }
    return enc.Key.fromBase64(val);
  }
}

