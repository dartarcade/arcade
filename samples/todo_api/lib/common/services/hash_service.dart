import 'package:dargon2/dargon2.dart';
import 'package:injectable/injectable.dart';

@singleton
class HashService {
  Future<String> hash(String password) async {
    final result = await argon2.hashPasswordString(
      password,
      salt: Salt.newSalt(),
    );
    return result.encodedString;
  }

  Future<bool> verify({required String password, required String hash}) async {
    return argon2.verifyHashString(password, hash);
  }
}
