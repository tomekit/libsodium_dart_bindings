@TestOn('dart-vm')

import 'dart:ffi';

import 'package:mocktail/mocktail.dart';
import 'package:sodium/src/api/sodium_exception.dart';
import 'package:sodium/src/ffi/api/sumo/sign_sumo_ffi.dart';
import 'package:sodium/src/ffi/bindings/libsodium.ffi.dart';
import 'package:test/test.dart';

import '../../../../secure_key_fake.dart';
import '../../pointer_test_helpers.dart';

class MockSodiumFFI extends Mock implements LibSodiumFFI {}

void main() {
  final mockSodium = MockSodiumFFI();

  late SignSumoFFI sut;

  setUpAll(() {
    registerPointers();
    registerFallbackValue(nullptr);
  });

  setUp(() {
    reset(mockSodium);

    mockAllocArray(mockSodium);

    sut = SignSumoFFI(mockSodium);
  });

  group('methods', () {
    setUp(() {
      when(() => mockSodium.crypto_sign_publickeybytes()).thenReturn(5);
      when(() => mockSodium.crypto_sign_secretkeybytes()).thenReturn(5);
      when(() => mockSodium.crypto_sign_seedbytes()).thenReturn(5);
    });

    group('skToSeed', () {
      test('asserts if secretKey is invalid', () {
        expect(
          () => sut.skToSeed(SecureKeyFake.empty(10)),
          throwsA(isA<RangeError>()),
        );

        verify(() => mockSodium.crypto_sign_secretkeybytes());
      });

      test('calls crypto_sign_ed25519_sk_to_seed with correct arguments', () {
        when(
          () => mockSodium.crypto_sign_ed25519_sk_to_seed(
            any(),
            any(),
          ),
        ).thenReturn(0);

        final secretKey = List.generate(5, (index) => 30 + index);

        sut.skToSeed(SecureKeyFake(secretKey));

        verifyInOrder([
          () => mockSodium.sodium_allocarray(5, 1),
          () => mockSodium.sodium_mprotect_readwrite(any(that: isNot(nullptr))),
          () => mockSodium.sodium_mprotect_readonly(
                any(that: hasRawData(secretKey)),
              ),
          () => mockSodium.crypto_sign_ed25519_sk_to_seed(
                any(that: isNot(nullptr)),
                any(that: hasRawData<UnsignedChar>(secretKey)),
              ),
          () => mockSodium.sodium_mprotect_noaccess(any(that: isNot(nullptr))),
        ]);
      });

      test('returns seed of the secret key', () {
        final seed = List.generate(5, (index) => 100 - index);
        when(
          () => mockSodium.crypto_sign_ed25519_sk_to_seed(
            any(),
            any(),
          ),
        ).thenAnswer((i) {
          fillPointer(i.positionalArguments.first as Pointer, seed);
          return 0;
        });

        final result = sut.skToSeed(SecureKeyFake.empty(5));

        expect(result.extractBytes(), seed);

        verify(() => mockSodium.sodium_free(any())).called(1);
      });

      test('throws exception on failure', () {
        when(
          () => mockSodium.crypto_sign_ed25519_sk_to_seed(
            any(),
            any(),
          ),
        ).thenReturn(1);

        expect(
          () => sut.skToSeed(SecureKeyFake.empty(5)),
          throwsA(isA<SodiumException>()),
        );

        verify(() => mockSodium.sodium_free(any())).called(2);
      });
    });

    group('skToPk', () {
      test('asserts if secretKey is invalid', () {
        expect(
          () => sut.skToPk(SecureKeyFake.empty(10)),
          throwsA(isA<RangeError>()),
        );

        verify(() => mockSodium.crypto_sign_secretkeybytes());
      });

      test('calls crypto_sign_ed25519_sk_to_pk with correct arguments', () {
        when(
          () => mockSodium.crypto_sign_ed25519_sk_to_pk(
            any(),
            any(),
          ),
        ).thenReturn(0);

        final secretKey = List.generate(5, (index) => 30 + index);

        sut.skToPk(SecureKeyFake(secretKey));

        verifyInOrder([
          () => mockSodium.sodium_allocarray(5, 1),
          () => mockSodium.sodium_mprotect_readonly(
                any(that: hasRawData(secretKey)),
              ),
          () => mockSodium.crypto_sign_ed25519_sk_to_pk(
                any(that: isNot(nullptr)),
                any(that: hasRawData<UnsignedChar>(secretKey)),
              ),
        ]);
      });

      test('returns the public key of the secret key', () {
        final publicKey = List.generate(5, (index) => 100 - index);
        when(
          () => mockSodium.crypto_sign_ed25519_sk_to_pk(
            any(),
            any(),
          ),
        ).thenAnswer((i) {
          fillPointer(i.positionalArguments.first as Pointer, publicKey);
          return 0;
        });

        final result = sut.skToPk(SecureKeyFake.empty(5));

        expect(result, publicKey);

        verify(() => mockSodium.sodium_free(any())).called(2);
      });

      test('throws exception on failure', () {
        when(
          () => mockSodium.crypto_sign_ed25519_sk_to_pk(
            any(),
            any(),
          ),
        ).thenReturn(1);

        expect(
          () => sut.skToPk(SecureKeyFake.empty(5)),
          throwsA(isA<SodiumException>()),
        );

        verify(() => mockSodium.sodium_free(any())).called(2);
      });
    });
  });
}
