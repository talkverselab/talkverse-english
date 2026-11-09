import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/english_decor.dart';
import '../widgets/word_sheet.dart';
import 'word_freq_screen.dart' show EnWord, WordList;
import '../core/embed_env.dart';

/// 뿌리(라틴·그리스 어근) 단어 패밀리 — 일본어앱 「패밀리 한자」(발음부) 자리의 영어 층(사용자 지시 2026-11-08).
/// 어근 카드(절벽 구간별) → 가족 시트: 낱말을 앞가지·어근·뒷가지로 색을 나눠 보이고, 조각이 뜻이 되는 한 줄(힌트).
/// 데이터 `assets/data/roots/roots_en.json`(`tools/roots_en.py`). 단어장(2,494어)에 있는 낱말은 누르면 단어 시트, 밖 낱말은 회색.
class RootsScreen extends StatefulWidget {
  const RootsScreen({super.key});

  @override
  State<RootsScreen> createState() => _RootsScreenState();
}

class RootWord {
  final String w, pre, core, suf, hint, ko, pos, lw;
  final int rank;
  final String level;
  final bool outside;
  /// 닮은꼴 — 어근이 같아 보이지만 다른 뿌리(`tools/roots_en.py` 가 힌트로 판정해 `l` 에 넣는다).
  final bool lookalike;
  const RootWord({required this.w, required this.pre, required this.core, required this.suf, required this.hint, required this.ko, required this.pos, required this.lw, required this.rank, required this.level, required this.outside, required this.lookalike});
  factory RootWord.fromJson(Map<String, dynamic> j) {
    final p = (j['parts'] as List).cast<String>();
    return RootWord(w: j['w'], pre: p[0], core: p[1], suf: p[2], hint: j['hint'] ?? '', ko: j['ko'] ?? '', pos: j['pos'] ?? '', lw: j['lw'] ?? '', rank: j['rank'] ?? 0, level: j['level'] ?? '', outside: j['x'] == true, lookalike: j['l'] == true);
  }
}

class RootFamily {
  final String root, origin, meaning, ko, level;
  final List<String> forms;
  final List<RootWord> words;
  final int best;
  const RootFamily({required this.root, required this.origin, required this.meaning, required this.ko, required this.level, required this.forms, required this.words, required this.best});
  factory RootFamily.fromJson(Map<String, dynamic> j) => RootFamily(
        root: j['root'],
        origin: j['origin'],
        meaning: j['meaning'],
        ko: j['ko'],
        level: j['level'],
        forms: (j['forms'] as List).cast<String>(),
        words: [for (final w in j['words'] as List) RootWord.fromJson(w as Map<String, dynamic>)],
        best: j['best'] ?? 99999,
      );
  int get inside => words.where((w) => !w.outside).length;
  String get originKo => origin == 'G' ? '그리스' : '라틴';
}

const Map<String, Color> _levelColors = {'R1': AppColors.beni, 'R2': AppColors.kinDeep, 'R3': AppColors.matcha, 'R4': AppColors.sakuraDeep, 'X': AppColors.muted};
const _levelLabel = {'ALL': '전체', 'R1': 'R1', 'R2': 'R2', 'R3': 'R3', 'R4': 'R4', 'X': '밖'};

class _RootsScreenState extends State<RootsScreen> {
  List<RootFamily> _roots = const [];
  Map<String, EnWord> _dict = const {};
  bool _loading = true;
  String _query = '';
  String _level = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(assetPath('assets/data/roots/roots_en.json'));
    final j = json.decode(raw) as Map<String, dynamic>;
    final roots = [for (final r in j['roots'] as List) RootFamily.fromJson(r as Map<String, dynamic>)];
    final words = await WordList.load();
    final dict = <String, EnWord>{};
    for (final w in words) {
      dict.putIfAbsent(w.word.toLowerCase(), () => w);
    }
    if (!mounted) return;
    setState(() {
      _roots = roots;
      _dict = dict;
      _loading = false;
    });
  }

  List<RootFamily> get _filtered {
    final base = _level == 'ALL' ? _roots : _roots.where((r) => r.level == _level).toList();
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base.where((r) => r.root.contains(q) || r.meaning.contains(q) || r.ko.contains(q) || r.forms.any((f) => f.contains(q)) || r.words.any((w) => w.w.contains(q) || w.ko.contains(q))).toList();
  }

  void _openFamily(RootFamily r) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.washi,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, controller) => SingleChildScrollView(controller: controller, child: _FamilySheet(root: r, dict: _dict)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final totalWords = _roots.fold(0, (s, r) => s + r.inside);
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('뿌리 단어 패밀리'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          const Text('LATIN · GREEK ROOTS', style: TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 2)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumi),
                  decoration: InputDecoration(
                    hintText: tr('port · 운반 · support'),
                    hintStyle: const TextStyle(color: AppColors.sumiLight, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.beni),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.washiDeep,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.line)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.beni, width: 1.5)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  const SealStamp(text: 'Root', size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(trf('어근 {0}개 · 절벽 단어 {1}어 커버', [_roots.length, totalWords]), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sumi, letterSpacing: 0.5)),
                  ),
                  Text(tr('탭 → 단어 가족'), style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
                ]),
              ),
              Container(
                color: AppColors.washiDeep,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final k in ['ALL', 'R1', 'R2', 'R3', 'R4', 'X'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _LevelChip(
                            label: k == 'ALL' ? tr('전체') : '${tr(_levelLabel[k]!)} · ${_roots.where((r) => r.level == k).length}',
                            color: _levelColors[k] ?? AppColors.sumi,
                            selected: _level == k,
                            onTap: () => setState(() => _level = k),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const AsanohaDivider(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => GridView.builder(
                    padding: EdgeInsets.fromLTRB(16, 10, 16, 24 + bottomInset(context)),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (c.maxWidth / 250).floor().clamp(1, 4),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 78,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _RootCard(root: list[i], onTap: () => _openFamily(list[i])),
                  ),
                ),
              ),
            ]),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _LevelChip({required this.label, required this.color, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: selected ? color : AppColors.washi, border: Border.all(color: color, width: selected ? 1.5 : 0.8), borderRadius: BorderRadius.circular(17)),
          child: Text(label, style: TextStyle(color: selected ? AppColors.washi : color, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      );
}

class _RootCard extends StatelessWidget {
  final RootFamily root;
  final VoidCallback onTap;
  const _RootCard({required this.root, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = _levelColors[root.level] ?? AppColors.sumi;
    return Container(
      decoration: BoxDecoration(color: AppColors.washi, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Row(children: [
              SealStamp(text: root.root, size: 50, color: root.origin == 'G' ? AppColors.matcha : null),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${root.ko} · ${root.meaning}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.sumi)),
                  const SizedBox(height: 2),
                  Text(root.forms.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.sumiLight)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 4, runSpacing: 2, clipBehavior: Clip.hardEdge, children: [
                    _Badge(text: tr(_levelLabel[root.level] ?? root.level), color: c),
                    _Badge(text: root.originKo, color: AppColors.muted),
                    _Badge(text: trf('가족 {0}어', [root.words.length]), color: AppColors.sumiLight),
                  ]),
                ]),
              ),
              const Icon(Icons.chevron_right, color: AppColors.sumiLight, size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), border: Border.all(color: color.withValues(alpha: 0.6)), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
      );
}

/// 가족 시트 — 어근 머리 + 낱말마다 앞가지·어근·뒷가지 색 분해 + 힌트. 단어장 낱말은 누르면 단어 시트.
class _FamilySheet extends StatelessWidget {
  final RootFamily root;
  final Map<String, EnWord> dict;
  const _FamilySheet({required this.root, required this.dict});

  @override
  Widget build(BuildContext context) {
    final real = root.words.where((w) => !w.lookalike).toList();
    final look = root.words.where((w) => w.lookalike).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset(context)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SealStamp(text: root.root, size: 76, color: root.origin == 'G' ? AppColors.matcha : null),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GradText(root.ko, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(height: 4),
                Text('${root.originKo} · ${root.meaning}', style: const TextStyle(fontSize: 12, color: AppColors.sumiLight, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(trf('모양 {0} · {1}어', [root.forms.join(', '), root.words.length]), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
            ),
            IconButton(icon: const Icon(Icons.close, color: AppColors.sumi), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 14),
          const BrushDivider(height: 2),
          const SizedBox(height: 6),
          for (final w in real) _WordRow(word: w, entry: dict[w.lw.toLowerCase()] ?? dict[w.w.toLowerCase()]),
          if (look.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              _Badge(text: tr('닮은꼴'), color: AppColors.sakuraDeep),
              const SizedBox(width: 8),
              Expanded(child: Text(tr('같은 뿌리처럼 보이지만 다른 뿌리인 낱말'), style: const TextStyle(fontSize: 11, color: AppColors.sumiLight))),
            ]),
            const SizedBox(height: 4),
            for (final w in look) _WordRow(word: w, entry: dict[w.lw.toLowerCase()] ?? dict[w.w.toLowerCase()], dim: true),
          ],
          const SizedBox(height: 10),
          Text(tr('💡 앞가지(연한 글자)와 뒷가지를 떼면 어근이 남아요. 어근 뜻 + 앞가지 뜻 = 낱말 뜻.'), style: const TextStyle(fontSize: 11, color: AppColors.sumiLight, height: 1.5)),
        ]),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  final RootWord word;
  final EnWord? entry;
  final bool dim;
  const _WordRow({required this.word, required this.entry, this.dim = false});

  @override
  Widget build(BuildContext context) {
    final w = word;
    final e = entry;
    final coreColor = dim ? AppColors.muted : AppColors.beni;
    final sideColor = dim ? AppColors.muted.withValues(alpha: 0.7) : AppColors.sumiLight;
    final lvColor = _levelColors[w.level] ?? AppColors.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: e == null ? null : () => showWordSheet(context, e),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
            decoration: BoxDecoration(
              color: w.outside || dim ? AppColors.washiDeep : AppColors.washi,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(children: [
                          if (w.pre.isNotEmpty) TextSpan(text: w.pre, style: TextStyle(color: sideColor, fontWeight: FontWeight.w500)),
                          TextSpan(text: w.core, style: TextStyle(color: coreColor, fontWeight: FontWeight.w900)),
                          if (w.suf.isNotEmpty) TextSpan(text: w.suf, style: TextStyle(color: sideColor, fontWeight: FontWeight.w500)),
                        ]),
                        style: const TextStyle(fontSize: 19, height: 1.1, color: AppColors.sumi),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (w.outside)
                      _Badge(text: tr('단어장 밖'), color: AppColors.muted)
                    else ...[
                      _Badge(text: w.level, color: lvColor),
                      const SizedBox(width: 4),
                      Text(trf('{0}위', [w.rank]), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                    ],
                  ]),
                  if ((e?.ko ?? w.ko).isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(e?.ko ?? w.ko, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                  ],
                  if (w.hint.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(w.hint, style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight, height: 1.35)),
                  ],
                ]),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.volume_up, size: 18, color: AppColors.beni),
                onPressed: () => TtsService.instance.speak(w.w),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
