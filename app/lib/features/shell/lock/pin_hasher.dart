import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Pure Dart utility for generating salts, hashing PINs with SHA-256,
/// and verifying submitted PINs against stored hashes.
class PinHasher {
  const PinHasher();

  /// Generates a random cryptographic salt encoded as hexadecimal.
  String generateSalt([int byteLength = 16]) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Computes a salted SHA-256 hash of the given [pin] and [salt].
  String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  /// Verifies whether [pin] hashed with [salt] matches [expectedHash].
  bool verifyPin(String pin, String salt, String expectedHash) {
    if (pin.length < 4 || pin.length > 6) {
      return false;
    }
    final computed = hashPin(pin, salt);
    return computed == expectedHash;
  }
}
