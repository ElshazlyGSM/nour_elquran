import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_reader_app/app/quran_app.dart';
import 'package:quran_reader_app/services/quran_store.dart';

void main() {
  testWidgets('shows quran app home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await QuranStore.create();

    await tester.pumpWidget(QuranApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('المصحف'), findsOneWidget);
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
    expect(find.text('الأذكار'), findsOneWidget);
  });
}
