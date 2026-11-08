import 'package:english_universe/screens/word_freq_screen.dart' show EnWord;
import 'package:english_universe/widgets/flashcards.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 공용 플래시카드 엔진(네 앱 같은 엔진) — 상자 오르내림, 판 구성, 저장.
void main() {
  EnWord w(int i) => EnWord(rank: i, word: 'w$i', ko: '뜻$i', pos: 'n.', level: 'R1', picturable: false);
  final deck = [for (var i = 1; i <= 50; i++) w(i)];

  test('round, mark, save and reload', () async {
    SharedPreferences.setMockInitialValues({});
    final e = await FlashcardEngine.load('t');
    final r1 = e.round(deck);
    expect(r1.length, 20);
    expect(r1.first.word, 'w1'); // 처음엔 새 카드가 덱 순서대로
    e.mark('w1', true);
    e.mark('w2', false);
    expect(e.boxOf('w1'), 1);
    expect(e.boxOf('w2'), 0);
    for (var i = 0; i < 5; i++) {
      e.mark('w1', true);
    }
    expect(e.boxOf('w1'), FlashcardEngine.maxBox); // 상자 4에서 멈춤
    await e.save();
    final e2 = await FlashcardEngine.load('t');
    expect(e2.boxOf('w1'), FlashcardEngine.maxBox);
    expect(e2.mastered, 1);
    final r2 = e2.round(deck);
    expect(r2.first.word, 'w2'); // 모르는 카드(상자 0)가 먼저
    expect(r2.map((x) => x.word), isNot(contains('w1'))); // 다 외운 카드는 뒤로 밀려 이번 판엔 없음
    expect(await FlashcardEngine.load('other').then((x) => x.started), 0); // 덱마다 따로
  });
}
