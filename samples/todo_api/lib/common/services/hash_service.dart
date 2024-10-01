import 'dart:isolate';

import 'package:hashlib/hashlib.dart';
import 'package:hashlib/random.dart';
import 'package:injectable/injectable.dart';

@singleton
class HashService {
  const HashService();

  Future<String> hash(String password) {
    // We use Isolates to improve performance as hashing is computationally expensive
    return Isolate.run(
      () => argon2id(password.codeUnits, randomString(16).codeUnits).encoded(),
    );
  }

  Future<bool> verify(String password, String hash) {
    return Isolate.run(
      () => argon2Verify(hash, password.codeUnits),
    );
  }
}
