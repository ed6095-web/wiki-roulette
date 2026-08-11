import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wiki_roulette/core/widgets/core_widgets.dart';

void main() {
  testWidgets('GlassCard renders child content', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text('Glass Content Test'),
          ),
        ),
      ),
    );

    expect(find.text('Glass Content Test'), findsOneWidget);
  });

  testWidgets('XpProgressBar renders level and progress', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: XpProgressBar(
            progress: 0.5,
            currentXp: 500,
            nextLevelXp: 1000,
            level: 3,
          ),
        ),
      ),
    );

    expect(find.text('LEVEL 3'), findsOneWidget);
    expect(find.text('500 / 1.0k XP'), findsOneWidget);
  });

  testWidgets('AppErrorState renders message and retry button', (WidgetTester tester) async {
    bool retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorState(
            message: 'Network error occurred',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Network error occurred'), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);

    await tester.tap(find.text('TRY AGAIN'));
    expect(retried, true);
  });
}
