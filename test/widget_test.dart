import 'package:flutter_test/flutter_test.dart';

import 'package:safealert_mobile/main.dart';

void main() {
  testWidgets('SafeAlert app renders register screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const SafeAlertApp(initialRoute: '/register', firebaseReady: false),
    );
    await tester.pump();

    expect(find.text('SAFE'), findsOneWidget);
    expect(find.text('ALERT'), findsOneWidget);
    expect(find.text('Registrasi Pengguna'), findsOneWidget);
  });
}
