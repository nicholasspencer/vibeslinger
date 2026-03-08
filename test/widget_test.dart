import 'package:flutter_test/flutter_test.dart';

import 'package:inference_gunslinger/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const InferenceGunslingerApp());
    await tester.pump();

    expect(find.text('Inference Gunslinger'), findsNothing); // title is in AppBar, not shown
    expect(find.text('Model: '), findsOneWidget);
    expect(find.text('FIRE (Space)'), findsOneWidget);
  });
}
