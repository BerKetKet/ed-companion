import 'package:flutter_test/flutter_test.dart';
import 'package:ed_companion/features/shell/lock/pin_hasher.dart';

void main() {
  const hasher = PinHasher();

  group('PinHasher', () {
    test('hashes and verifies correct PIN', () {
      final salt = hasher.generateSalt();
      final hash = hasher.hashPin('1234', salt);

      expect(hasher.verifyPin('1234', salt, hash), isTrue);
    });

    test('wrong PIN fails verification', () {
      final salt = hasher.generateSalt();
      final hash = hasher.hashPin('1234', salt);

      expect(hasher.verifyPin('9999', salt, hash), isFalse);
      expect(hasher.verifyPin('12345', salt, hash), isFalse);
      expect(hasher.verifyPin('123', salt, hash), isFalse);
    });

    test('two different salts give different hashes for identical PIN', () {
      final salt1 = hasher.generateSalt();
      final salt2 = hasher.generateSalt();
      expect(salt1, isNot(equals(salt2)));

      final hash1 = hasher.hashPin('5678', salt1);
      final hash2 = hasher.hashPin('5678', salt2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('supports 4 to 6 digits PINs', () {
      final salt = hasher.generateSalt();

      for (final pin in ['1234', '12345', '123456']) {
        final hash = hasher.hashPin(pin, salt);
        expect(hasher.verifyPin(pin, salt, hash), isTrue);
      }
    });

    test('rejects PINs outside 4 to 6 digit range', () {
      final salt = hasher.generateSalt();
      final hash = hasher.hashPin('123', salt);

      expect(hasher.verifyPin('123', salt, hash), isFalse);
      expect(hasher.verifyPin('1234567', salt, hash), isFalse);
    });
  });
}
