import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap_panel/snap_panel.dart';

void main() {
  testWidgets('renders collapsed content and attaches controller',
      (WidgetTester tester) async {
    final controller = SnapPanelController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SnapPanel(
            controller: controller,
            minHeight: 80,
            maxHeight: 320,
            panel: const Text('Expanded panel'),
            collapsed: const Text('Collapsed panel'),
          ),
        ),
      ),
    );

    expect(find.text('Collapsed panel'), findsOneWidget);
    expect(find.text('Expanded panel'), findsOneWidget);
    expect(controller.isAttached, isTrue);
    expect(controller.panelState, SnapPanelState.collapsed);
  });
}
