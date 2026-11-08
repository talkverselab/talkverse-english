import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../screens/word_freq_screen.dart' show EnWord;
import '../services/tts_service.dart';
import 'english_decor.dart';

/// 단어 플래시카드 엔진 — 영어·토익·토익스피킹·OPIc 네 앱이 **같은 엔진 하나**를 쓴다(사용자 지시 2026-11-08
/// "모든 앱에 플래쉬카드 루트단어 엔진은 한 모델 사용"). 앱마다 다른 것은 덱(낱말 목록)과 덱 id 뿐.
/// 간이 라이트너: 상자 0~4. 「알아요」 → 상자 +1, 「몰라요」 → 상자 0 + 이번 판 뒤에 한 번 더. 한 판 = 상자 낮은 순 20장.
class FlashcardEngine {
  final String deckId;
  final Map<String, int> boxes;
  FlashcardEngine._(this.deckId, this.boxes);

  static const maxBox = 4;
  static const roundSize = 20;
  static String _key(String deck) => 'flash_$deck';

  static Future<FlashcardEngine> load(String deckId) async {
    final p = await SharedPreferences.getInstance();
    final m = <String, int>{};
    for (final e in p.getStringList(_key(deckId)) ?? const <String>[]) {
      final i = e.lastIndexOf('=');
      if (i > 0) m[e.substring(0, i)] = int.tryParse(e.substring(i + 1)) ?? 0;
    }
    return FlashcardEngine._(deckId, m);
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key(deckId), [for (final e in boxes.entries) '${e.key}=${e.value}']);
  }

  int boxOf(String w) => boxes[w] ?? -1; // -1 = 아직 안 본 카드

  /// 이번 판: 본 적 있는 카드 중 상자가 낮은 것 → 새 카드(덱 순서) 순으로 [size] 장. 다 외운(상자 4) 카드는 맨 뒤.
  List<EnWord> round(List<EnWord> deck, {int size = roundSize}) {
    final seen = deck.where((w) => boxOf(w.word) >= 0 && boxOf(w.word) < maxBox).toList()..sort((a, b) => boxOf(a.word).compareTo(boxOf(b.word)));
    final fresh = deck.where((w) => boxOf(w.word) < 0).toList();
    final done = deck.where((w) => boxOf(w.word) >= maxBox).toList();
    final reviewShare = seen.length.clamp(0, size ~/ 2);
    return [...seen.take(reviewShare), ...fresh, ...seen.skip(reviewShare), ...done].take(size).toList();
  }

  void mark(String w, bool known) => boxes[w] = known ? (boxOf(w) < 0 ? 1 : (boxOf(w) + 1).clamp(0, maxBox)) : 0;

  int get mastered => boxes.values.where((b) => b >= maxBox).length;
  int get started => boxes.length;
}

/// 플래시카드 화면 — 앞면 낱말(누르면 발음), 탭하면 뒷면 뜻. 「몰라요 / 알아요」.
class FlashcardScreen extends StatefulWidget {
  final String title;
  final String deckId;
  final List<EnWord> deck;
  const FlashcardScreen({super.key, required this.title, required this.deckId, required this.deck});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  FlashcardEngine? _eng;
  List<EnWord> _queue = [];
  int _pos = 0;
  bool _back = false;
  int _known = 0, _again = 0;
  final Set<String> _requeued = {};

  @override
  void initState() {
    super.initState();
    FlashcardEngine.load(widget.deckId).then((e) {
      if (!mounted) return;
      setState(() {
        _eng = e;
        _queue = e.round(widget.deck);
      });
      _speak();
    });
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _speak() {
    if (_pos < _queue.length) TtsService.instance.speak(_queue[_pos].word);
  }

  Future<void> _answer(bool known) async {
    final w = _queue[_pos];
    _eng!.mark(w.word, known);
    if (known) {
      _known++;
    } else {
      _again++;
      if (_requeued.add(w.word)) _queue.add(w); // 이번 판 끝에 한 번 더
    }
    await _eng!.save();
    if (!mounted) return;
    setState(() {
      _pos++;
      _back = false;
    });
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    final e = _eng;
    final done = e != null && _pos >= _queue.length;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800))),
      body: e == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : _queue.isEmpty
              ? Center(child: Text(tr('카드가 없어요')))
              : done
                  ? _Summary(known: _known, again: _again, mastered: e.mastered, started: e.started, total: widget.deck.length, onAgain: () {
                      setState(() {
                        _queue = e.round(widget.deck);
                        _pos = 0;
                        _known = _again = 0;
                        _requeued.clear();
                      });
                      _speak();
                    })
                  : Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.paddingOf(context).bottom),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          Text('${_pos + 1} / ${_queue.length}', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text(trf('외운 카드 {0} / {1}', [e.mastered, widget.deck.length]), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                        ]),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(value: (_pos) / _queue.length, color: AppColors.beni, backgroundColor: AppColors.line, minHeight: 3),
                        const SizedBox(height: 16),
                        Expanded(child: _Card(word: _queue[_pos], back: _back, box: e.boxOf(_queue[_pos].word), onFlip: () => setState(() => _back = !_back))),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _answer(false),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.sakuraDeep), shape: const StadiumBorder()),
                              child: Text(tr('몰라요'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.sakuraDeep)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _answer(true),
                              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.beni, shape: const StadiumBorder()),
                              child: Text(tr('알아요'), style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ]),
                      ]),
                    ),
    );
  }
}

class _Card extends StatelessWidget {
  final EnWord word;
  final bool back;
  final int box;
  final VoidCallback onFlip;
  const _Card({required this.word, required this.back, required this.box, required this.onFlip});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: back ? AppColors.washiDeep : AppColors.washi,
      shape: RoundedRectangleBorder(side: const BorderSide(color: AppColors.line), borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onFlip,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: GradText(word.word, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1)))),
              const SizedBox(width: 6),
              IconButton(icon: const Icon(Icons.volume_up, color: AppColors.beni), onPressed: () => TtsService.instance.speak(word.word)),
            ]),
            if (word.pos.isNotEmpty) Text(word.pos, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: back
                  ? Text(word.ko, key: const ValueKey('b'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.4))
                  : Text(tr('탭해서 뜻 보기'), key: const ValueKey('f'), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ),
            const SizedBox(height: 16),
            Text(box < 0 ? tr('새 카드') : trf('상자 {0}', [box]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int known, again, mastered, started, total;
  final VoidCallback onAgain;
  const _Summary({required this.known, required this.again, required this.mastered, required this.started, required this.total, required this.onAgain});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            GradText('$known / ${known + again}', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(trf('알아요 {0} · 몰라요 {1}', [known, again]), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
            const SizedBox(height: 4),
            Text(trf('본 카드 {0} · 외운 카드 {1} / 전체 {2}', [started, mastered, total]), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 20),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.beni, shape: const StadiumBorder()), onPressed: onAgain, child: Text(tr('한 판 더'))),
          ]),
        ),
      );
}

/// 덱을 불러와서 [FlashcardScreen] 을 연다(앱마다 덱만 다르다).
class FlashcardDeck extends StatelessWidget {
  final String title;
  final String deckId;
  final Future<List<EnWord>> Function() loader;
  const FlashcardDeck({super.key, required this.title, required this.deckId, required this.loader});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<EnWord>>(
        future: loader(),
        builder: (context, s) => s.hasData
            ? FlashcardScreen(title: title, deckId: deckId, deck: s.data!)
            : const Scaffold(backgroundColor: AppColors.washi, body: Center(child: CircularProgressIndicator(color: AppColors.beni))),
      );
}
