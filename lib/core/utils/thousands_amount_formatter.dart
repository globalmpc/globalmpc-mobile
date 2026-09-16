import 'package:flutter/services.dart';

class ThousandsAmountFormatter extends TextInputFormatter {
  const ThousandsAmountFormatter();

  static final _shapePattern = RegExp(r'^\d*(\.\d{0,6})?$');

  static String group(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    final len = digits.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cursorPos = newValue.selection.end.clamp(0, newValue.text.length);
    final rawCharsBeforeCursor = newValue.text
        .substring(0, cursorPos)
        .replaceAll(',', '')
        .length;
    final rawText = newValue.text.replaceAll(',', '');

    if (rawText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    if (!_shapePattern.hasMatch(rawText)) {
      return oldValue;
    }

    final dotIndex = rawText.indexOf('.');
    final intPart = dotIndex == -1 ? rawText : rawText.substring(0, dotIndex);
    final rest = dotIndex == -1 ? '' : rawText.substring(dotIndex);
    final formatted = '${group(intPart)}$rest';

    var newOffset = formatted.length;
    if (rawCharsBeforeCursor == 0) {
      newOffset = 0;
    } else {
      var nonCommaCount = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (formatted[i] != ',') nonCommaCount++;
        if (nonCommaCount == rawCharsBeforeCursor) {
          newOffset = i + 1;
          break;
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
