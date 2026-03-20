import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:uniflow_front/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app bootstrap and home page render', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final bootstrap = await AppBootstrap.create();

    await tester.pumpWidget(UniFlowApp(bootstrap: bootstrap));
    await tester.pumpAndSettle();

    expect(find.text('UniFlow 校园通知'), findsOneWidget);
  });
}
