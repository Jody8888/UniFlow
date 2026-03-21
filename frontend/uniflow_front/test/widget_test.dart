import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app bootstrap and home page render', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final bootstrap = await AppBootstrap.create();

    await tester.pumpWidget(UniFlowApp(bootstrap: bootstrap));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('UniFlow У԰֪ͨ'), findsWidgets);
  });
}
