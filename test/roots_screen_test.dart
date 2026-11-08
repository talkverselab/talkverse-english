import 'package:english_universe/core/theme.dart';
import 'package:english_universe/screens/roots_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 뿌리 단어 패밀리 — 데이터가 읽히고, 가족 시트가 열리며, 닮은꼴이 따로 묶이는지.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  Future<void> waitFor(WidgetTester t, Finder f) async {
    for (var i = 0; i < 50 && f.evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('roots list, family sheet, lookalike group', (t) async {
    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const RootsScreen()));
    await waitFor(t, find.textContaining('어근 99개'));
    expect(find.textContaining('어근 99개'), findsOneWidget);
    await t.tap(find.textContaining('사람들 · people').first);
    await waitFor(t, find.textContaining('공공의'));
    expect(find.textContaining('공공의'), findsWidgets);
    expect(find.text('닮은꼴'), findsNothing);
    await t.tap(find.byIcon(Icons.close));
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.enterText(find.byType(TextField), 'cent');
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.textContaining('백(100)').first);
    await waitFor(t, find.text('닮은꼴'));
    expect(find.text('닮은꼴'), findsOneWidget);
    expect(find.text('단어장 밖'), findsNothing);
  });
}
