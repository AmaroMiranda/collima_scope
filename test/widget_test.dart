import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:collima_scope/app/app.dart';

void main() {
  testWidgets('Home screen mostra o título do app', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(child: CollimaScopeApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('CollimaScope'), findsWidgets);
  });
}
