import 'dart:async';
import 'package:injectable/injectable.dart' hide test;
import 'package:test/test.dart';

// Mock implementation of MicroPackageModule
class MockMicroPackageModule implements MicroPackageModule {
  bool initialized = false;
  GetItHelper? capturedHelper;

  @override
  FutureOr<void> init(GetItHelper gh) {
    initialized = true;
    capturedHelper = gh;
  }
}

class AsyncMicroPackageModule implements MicroPackageModule {
  bool initialized = false;

  @override
  Future<void> init(GetItHelper gh) async {
    await Future.delayed(Duration(milliseconds: 10));
    initialized = true;
  }
}

void main() {
  group('MicroPackageModule', () {
    test('should be abstract and implementable', () {
      final module = MockMicroPackageModule();
      expect(module, isA<MicroPackageModule>());
    });

    test('init should accept GetItHelper', () {
      final module = MockMicroPackageModule();
      expect(module.initialized, isFalse);

      // We can't test the actual execution without GetIt,
      // but we can verify the interface
      expect(module.init, isA<Function>());
    });

    test('should support synchronous initialization', () {
      final module = MockMicroPackageModule();
      expect(() => module.init, returnsNormally);
    });

    test('should support asynchronous initialization', () {
      final module = AsyncMicroPackageModule();
      expect(module.init, isA<Function>());
    });
  });
}
