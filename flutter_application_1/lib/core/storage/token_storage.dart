import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage();

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteToken() async {
    return _storage.delete(key: _accessTokenKey);
  }
}
