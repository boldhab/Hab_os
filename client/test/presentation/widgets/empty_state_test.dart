import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/presentation/widgets/app_empty_state.dart';

void main() {
  testWidgets('AppEmptyState renders title, description and button',
      (tester) async {
    bool actionClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_rounded,
            title: 'No Items Found',
            description: 'Please add a new item.',
            actionLabel: 'Add Item',
            onAction: () => actionClicked = true,
          ),
        ),
      ),
    );

    expect(find.text('No Items Found'), findsOneWidget);
    expect(find.text('Please add a new item.'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);

    await tester.tap(find.text('Add Item'));
    await tester.pump();

    expect(actionClicked, isTrue);
  });
}
