import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaplig/features/home/widgets/kids_mode_exit_dialog.dart';

void main() {
  testWidgets('entered pin değerini doğrulama callbackine gönderir', (
    tester,
  ) async {
    String? submittedPin;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  KidsModeExitDialog.show(
                    context,
                    verifyPin: (pin) async {
                      submittedPin = pin;
                      return null;
                    },
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Doğrula'));
    await tester.pumpAndSettle();

    expect(submittedPin, '1234');
    expect(find.text('Çocuk Profilinden Çık'), findsNothing);
  });
}
