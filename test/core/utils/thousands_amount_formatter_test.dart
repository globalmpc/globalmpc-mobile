import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/core/utils/thousands_amount_formatter.dart';

void main() {
  const f = ThousandsAmountFormatter();

  TextEditingValue apply(
    String oldText,
    int oldOffset,
    String newText,
    int newOffset,
  ) {
    return f.formatEditUpdate(
      TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldOffset),
      ),
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      ),
    );
  }

  test('groups typed digits with cursor at end', () {
    var v = apply('', 0, '9', 1);
    expect(v.text, '9');
    v = apply(v.text, v.selection.end, '${v.text}9', v.selection.end + 1);
    v = apply(v.text, v.selection.end, '${v.text}9', v.selection.end + 1);
    expect(v.text, '999');
    v = apply(v.text, v.selection.end, '${v.text}9', v.selection.end + 1);
    expect(v.text, '9,999');
    expect(v.selection.end, v.text.length);
  });

  test('999999999 -> 999,999,999', () {
    final result = f.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '999999999',
        selection: TextSelection.collapsed(offset: 9),
      ),
    );
    expect(result.text, '999,999,999');
    expect(result.selection.end, 11);
  });

  test('preserves decimal typing', () {
    final result = f.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '1234.5',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    expect(result.text, '1,234.5');
  });

  test('rejects a second dot', () {
    final oldValue = const TextEditingValue(
      text: '1,234.5',
      selection: TextSelection.collapsed(offset: 7),
    );
    final result = f.formatEditUpdate(
      oldValue,
      const TextEditingValue(
        text: '1,234.5.',
        selection: TextSelection.collapsed(offset: 8),
      ),
    );
    expect(result.text, oldValue.text);
  });

  test('cursor stays anchored when inserting a digit in the middle', () {
    final result = f.formatEditUpdate(
      const TextEditingValue(
        text: '12,345',
        selection: TextSelection.collapsed(offset: 2),
      ),
      const TextEditingValue(
        text: '129,345',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    expect(result.text, '129,345');
    expect(result.selection.end, 3);
  });

  test('backspace across a comma-adjacent boundary keeps digits correct', () {
    final result = f.formatEditUpdate(
      const TextEditingValue(
        text: '1,234',
        selection: TextSelection.collapsed(offset: 1),
      ),
      const TextEditingValue(
        text: ',234',
        selection: TextSelection.collapsed(offset: 0),
      ),
    );
    expect(result.text, '234');
    expect(result.selection.end, 0);
  });

  test('caps at 6 decimal digits', () {
    final oldValue = const TextEditingValue(
      text: '1.123456',
      selection: TextSelection.collapsed(offset: 8),
    );
    final result = f.formatEditUpdate(
      oldValue,
      const TextEditingValue(
        text: '1.1234567',
        selection: TextSelection.collapsed(offset: 9),
      ),
    );
    expect(result.text, oldValue.text);
  });
}
