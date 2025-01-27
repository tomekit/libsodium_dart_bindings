@TestOn('js')

import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:sodium/src/api/sodium_exception.dart';
import 'package:sodium/src/js/api/sumo/scalarmult_sumo_js.dart';
import 'package:sodium/src/js/bindings/js_error.dart';
import 'package:sodium/src/js/bindings/sodium.js.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

import '../../../../secure_key_fake.dart';
import '../../../../test_constants_mapping.dart';

class MockLibSodiumJS extends Mock implements LibSodiumJS {}

void main() {
  final mockSodium = MockLibSodiumJS();

  late ScalarmultSumoJS sut;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    reset(mockSodium);

    sut = ScalarmultSumoJS(mockSodium);
  });

  testConstantsMapping([
    Tuple3(
      () => mockSodium.crypto_scalarmult_BYTES,
      () => sut.bytes,
      'bytes',
    ),
    Tuple3(
      () => mockSodium.crypto_scalarmult_SCALARBYTES,
      () => sut.scalarBytes,
      'scalarBytes',
    ),
  ]);

  group('methods', () {
    setUp(() {
      when(() => mockSodium.crypto_scalarmult_BYTES).thenReturn(5);
      when(() => mockSodium.crypto_scalarmult_SCALARBYTES).thenReturn(10);
    });

    group('base', () {
      test('asserts if n is invalid', () {
        expect(
          () => sut.base(n: SecureKeyFake.empty(5)),
          throwsA(isA<RangeError>()),
        );

        verify(() => mockSodium.crypto_scalarmult_SCALARBYTES);
      });

      test('calls crypto_scalarmult_base with correct arguments', () {
        when(
          () => mockSodium.crypto_scalarmult_base(
            any(),
          ),
        ).thenReturn(Uint8List(0));

        final n = List.generate(10, (index) => index);

        sut.base(n: SecureKeyFake(n));

        verify(() => mockSodium.crypto_scalarmult_base(Uint8List.fromList(n)));
      });

      test('returns public key data', () {
        final q = List.generate(5, (index) => 100 - index);
        when(
          () => mockSodium.crypto_scalarmult_base(
            any(),
          ),
        ).thenReturn(Uint8List.fromList(q));

        final result = sut.base(
          n: SecureKeyFake.empty(10),
        );

        expect(result, q);
      });

      test('throws exception on failure', () {
        when(
          () => mockSodium.crypto_scalarmult_base(
            any(),
          ),
        ).thenThrow(JsError());

        expect(
          () => sut.base(
            n: SecureKeyFake.empty(10),
          ),
          throwsA(isA<SodiumException>()),
        );
      });
    });

    group('call', () {
      test('asserts if n is invalid', () {
        expect(
          () => sut(
            n: SecureKeyFake.empty(5),
            p: Uint8List(5),
          ),
          throwsA(isA<RangeError>()),
        );

        verify(() => mockSodium.crypto_scalarmult_SCALARBYTES);
      });

      test('asserts if p is invalid', () {
        expect(
          () => sut(
            n: SecureKeyFake.empty(10),
            p: Uint8List(10),
          ),
          throwsA(isA<RangeError>()),
        );

        verifyInOrder([
          () => mockSodium.crypto_scalarmult_SCALARBYTES,
          () => mockSodium.crypto_scalarmult_BYTES,
        ]);
      });

      test('calls crypto_scalarmult with correct arguments', () {
        when(
          () => mockSodium.crypto_scalarmult(
            any(),
            any(),
          ),
        ).thenReturn(Uint8List(0));

        final n = List.generate(10, (index) => index);
        final p = List.generate(5, (index) => index * 2);

        sut(
          n: SecureKeyFake(n),
          p: Uint8List.fromList(p),
        );

        verify(
          () => mockSodium.crypto_scalarmult(
            Uint8List.fromList(n),
            Uint8List.fromList(p),
          ),
        );
      });

      test('returns shared key data', () {
        final q = List.generate(5, (index) => 100 - index);
        when(
          () => mockSodium.crypto_scalarmult(
            any(),
            any(),
          ),
        ).thenReturn(Uint8List.fromList(q));

        final result = sut(
          n: SecureKeyFake.empty(10),
          p: Uint8List(5),
        );

        expect(result.extractBytes(), q);
      });

      test('throws exception on failure', () {
        when(
          () => mockSodium.crypto_scalarmult(
            any(),
            any(),
          ),
        ).thenThrow(JsError());

        expect(
          () => sut(
            n: SecureKeyFake.empty(10),
            p: Uint8List(5),
          ),
          throwsA(isA<SodiumException>()),
        );
      });
    });
  });
}
