import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpc_mining_app/features/onboarding/splash_screen.dart';

void main() {
  testWidgets('splash paints without errors before the window has a size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size.zero),
          child: SplashScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
