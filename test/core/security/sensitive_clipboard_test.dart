import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/security/sensitive_clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String? clipboard;

  setUp(() {
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
            return null;
          }
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': clipboard};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  const phrase = 'alpha bravo charlie delta echo foxtrot';

  testWidgets('clears the copied phrase after the delay', (tester) async {
    final sensitive = SensitiveClipboard();
    await sensitive.copy(phrase);
    expect(clipboard, phrase);

    await tester.pump(const Duration(seconds: 29));
    expect(clipboard, phrase);

    await tester.pump(const Duration(seconds: 1));
    await tester.idle();
    expect(clipboard, '');
  });

  testWidgets('clears the copied phrase when disposed before the delay', (
    tester,
  ) async {
    final sensitive = SensitiveClipboard();
    await sensitive.copy(phrase);

    sensitive.dispose();
    await tester.idle();

    expect(clipboard, '');
  });

  testWidgets('leaves newer clipboard content alone', (tester) async {
    final sensitive = SensitiveClipboard();
    await sensitive.copy(phrase);
    clipboard = 'something the user copied later';

    sensitive.dispose();
    await tester.idle();

    expect(clipboard, 'something the user copied later');
  });
}
