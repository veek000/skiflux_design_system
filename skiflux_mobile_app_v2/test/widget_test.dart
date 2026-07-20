import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/app/app.dart';

void main() {
  testWidgets('Home screen loads', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SkifluxMobileAppV2(),
      ),
    );
    expect(find.text('Amara Design'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
