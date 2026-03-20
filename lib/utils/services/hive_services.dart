import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static late Box<dynamic> _encryptedBox;

  static Future<void> instance() async {
    await Hive.initFlutter();
    const secureKey = 'thisIsRandomKeyForEncryption';
    const secureStorage = FlutterSecureStorage();
    // if key not exists return null
    final encryptionKeyString = await secureStorage.read(key: secureKey);
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(key: secureKey, value: base64UrlEncode(key));
    }

    final key = await secureStorage.read(key: secureKey);
    final encryptionKeyUint8List = base64Url.decode(key!);

    final box = await Hive.openBox(
      'encryptedBox_',
      encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
    );
    _encryptedBox = box;
    return;
  }

  static void delete(String key) {
    _encryptedBox.delete(key);
  }

  static void deleteAll(List<String> keys) {
    _encryptedBox.deleteAll(keys);
  }

  static T? get<T>({required String key}) {
    return _encryptedBox.get(key) as T?;
  }

  static void reset() {
    _encryptedBox.clear();
  }

  static void set<T>({required String key, required T data}) {
    _encryptedBox.put(key, data);
  }
}
