import 'package:hashlib/hashlib.dart';
import 'package:hashlib/random.dart';
import 'package:injectable/injectable.dart';

@singleton
class HashService {
  const HashService();

  String hash(String password) {
    return argon2id(password.codeUnits, randomString(16).codeUnits).encoded();
  }

  bool verify(String password, String hash) {
    return argon2Verify(hash, password.codeUnits);
  }
}
