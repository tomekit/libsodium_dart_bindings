@JS()
library js_test;

import 'dart:async';
import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart';
// ignore: test_library_import
import 'package:sodium/sodium.dart';
// ignore: test_library_import
import 'package:sodium/sodium.js.dart';

import 'test_runner.dart';

@JS()
@anonymous
class SodiumBrowserInit {
  external void Function(dynamic sodium) get onload;

  external factory SodiumBrowserInit({
    void Function(LibSodiumJS sodium) onload,
  });
}

class JsTestRunner extends TestRunner {
  final String sodiumJsSrc;

  JsTestRunner({
    required this.sodiumJsSrc,
    required bool isSumoTest,
  }) : super(isSumoTest: isSumoTest);

  @override
  Future<Sodium> loadSodium() async {
    final completer = Completer<LibSodiumJS>();

    setProperty(
      window,
      'sodium',
      SodiumBrowserInit(
        onload: allowInterop(completer.complete),
      ),
    );

    final script = ScriptElement()..text = sodiumJsSrc;
    document.head!.append(script);

    return SodiumInit.init(await completer.future);
  }
}
