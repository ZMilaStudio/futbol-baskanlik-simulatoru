import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_baskanlik_app/main.dart';

void main() {
  testWidgets('boots and consumes the deterministic core public API', (
    tester,
  ) async {
    await tester.pumpWidget(const FutbolBaskanlikApp());

    expect(
      find.text('Takımı sen yönetmiyorsun. Kulübü sen yönetiyorsun.'),
      findsOneWidget,
    );
    expect(find.text('Core bağlantısı: 48 kulüp'), findsOneWidget);
  });
}
