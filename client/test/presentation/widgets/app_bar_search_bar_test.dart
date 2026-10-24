import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habos_client/presentation/widgets/app_bar_search_bar.dart';

void main() {
  testWidgets('AppBarSearchBar renders search icon and default hint text',
      (tester) async {
    bool tapped = false;

    // Set screen size large enough to test standard render
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              AppBarSearchBar(
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.text('Search tasks, projects, notes...'), findsOneWidget);

    await tester.tap(find.byType(AppBarSearchBar));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('AppBarSearchBar respects custom hintText and width',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              AppBarSearchBar(
                width: 250,
                hintText: 'Quick search anything...',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Quick search anything...'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });

  testWidgets('AppBarSearchBar adapts to compact mobile width',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              AppBarSearchBar(),
            ],
          ),
        ),
      ),
    );

    // On narrow screen (<= 380), hint defaults to 'Search...'
    expect(find.text('Search...'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
  });
}
