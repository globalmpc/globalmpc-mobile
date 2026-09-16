import 'dart:async';

import 'package:flutter/services.dart';

class SensitiveClipboard {
  SensitiveClipboard({this.clearAfter = const Duration(seconds: 30)});

  final Duration clearAfter;
  Timer? _timer;
  String? _copied;

  Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _copied = text;
    _timer?.cancel();
    _timer = Timer(clearAfter, () => unawaited(clear()));
  }

  Future<void> clear() async {
    _timer?.cancel();
    _timer = null;
    final copied = _copied;
    _copied = null;
    if (copied == null) return;
    final current = await Clipboard.getData(Clipboard.kTextPlain);
    if (current?.text == copied) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  }

  void dispose() {
    unawaited(clear());
  }
}
