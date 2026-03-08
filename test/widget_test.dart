import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';

import 'package:inference_gunslinger/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const InferenceGunslingerApp());
    await tester.pump();

    expect(find.text('Inference Gunslinger'), findsNothing); // title is in AppBar, not shown
    expect(find.text('Model: '), findsOneWidget);
    expect(find.text('FIRE (Space)'), findsOneWidget);
  });
}
