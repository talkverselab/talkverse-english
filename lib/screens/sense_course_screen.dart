import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/script_sync.dart';
import '../services/entitlement.dart';
import 'paywall_screen.dart';
import 'package:video_player/video_player.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../services/tts_service.dart';

/// 언어감각 익히기 — 일본어앱 정규과정(빌드 96~112)과 같은 꼴(2026-11-18 영어로 옮김). L1~L10, 급마다 외울 대화 1회 + 참고.
/// 암기 회차 = 영상 → 안내 한 줄 → 외울 대화(who·en·ko, `{글자|번호}` 같은 색 대응). 참고 = points(head·tip·sentences).
/// 데이터 `assets/data/grammar/sense_course.json` — 서버 원고(ScriptSync)가 더 새것이면 그것.
/// 내용은 간단하게 시작해 차차 늘린다 — 회차를 늘리려면 JSON 에 lessons 만 더하면 된다.
const _kDoneKey = 'sense_course_done';
const _kAsset = 'assets/data/grammar/sense_course.json';

class SenseCourse {
  static Map<String, dynamic>? _cache;
  static int _cacheRev = -1;

  /// 급(스텝) 목록·제목·순서·내용은 모두 이 파일(데이터)에서 — 코드는 틀만(사용자 지시 2026-11-23 「스텝 10까지 미리 만들고 DB 업데이트로 갱신」).
  /// 서버 원고(ScriptSync, script/en)에 새 판이 있으면 그것, 없으면 앱에 묶은 파일. 받은 판이 바뀌면 다시 읽는다.
  static Future<Map<String, dynamic>> load() async {
    final sync = ScriptSync.instance;
    await sync.init();
    if (_cache != null && _cacheRev == sync.shownRev) return _cache!;
    // loadString 은 큰 파일을 다른 isolate 에서 풀어 위젯 테스트가 멈춘다 — 바이트로 읽어 여기서 푼다.
    final raw = json.decode(await sync.load(_kAsset.substring('assets/data/'.length))) as Map<String, dynamic>;
    _cacheRev = sync.shownRev;
    return _cache = visible(raw);
  }

  /// 내용이 있는 회차·급만 남긴다 — 빈 급은 「준비 중」으로 보이지 않고 숨겨졌다가, 서버 파일에 내용이 생기면 저절로 나타난다.
  @visibleForTesting
  static Map<String, dynamic> visible(Map<String, dynamic> d) {
    bool has(Map<String, dynamic> ls) => ls['kind'] == 'ref' ? ((ls['points'] as List?) ?? const []).isNotEmpty : ((ls['sentences'] as List?) ?? const []).isNotEmpty;
    final levels = <Map<String, dynamic>>[];
    for (final lv in ((d['levels'] as List?) ?? const []).whereType<Map>()) {
      final ls = [for (final l in ((lv['lessons'] as List?) ?? const []).whereType<Map>()) if (has(l.cast<String, dynamic>())) l.cast<String, dynamic>()];
      // 참고만 남은 급은 외울 대화가 없으니 숨긴다
      if (ls.any((l) => l['kind'] != 'ref')) levels.add({...lv.cast<String, dynamic>(), 'lessons': ls});
    }
    return {...d, 'levels': levels};
  }

  @visibleForTesting
  static void debugClear() => _cache = null;

  static Future<Set<String>> done() async => ((await Prefs.getInstance()).getStringList(_kDoneKey) ?? const []).toSet();

  static Future<void> markDone(String id) async {
    final p = await Prefs.getInstance();
    final s = (p.getStringList(_kDoneKey) ?? <String>[]).toSet()..add(id);
    await p.setStringList(_kDoneKey, s.toList());
  }

  /// 모든 회차를 순서대로 (레벨, 회차) 쌍으로.
  static List<(Map<String, dynamic>, Map<String, dynamic>)> flat(Map<String, dynamic> d) => [
        for (final lv in (d['levels'] as List).cast<Map<String, dynamic>>())
          for (final ls in (lv['lessons'] as List).cast<Map<String, dynamic>>()) (lv, ls),
      ];
}

class SenseCourseScreen extends StatefulWidget {
  const SenseCourseScreen({super.key});

  @override
  State<SenseCourseScreen> createState() => _SenseCourseScreenState();
}

class _SenseCourseScreenState extends State<SenseCourseScreen> {
  Map<String, dynamic>? _data;
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await SenseCourse.load();
    final done = await SenseCourse.done();
    if (!mounted) return;
    setState(() {
      _data = d;
      _done = done;
    });
  }

  Future<void> _open(int index) async {
    // 언어감각 2급 이상은 이용권(서버 freeSenseLevels, 기본 1급만 무료 — PAYWALL_SPEC §2)
    final d = _data;
    if (d != null) {
      final lv = SenseCourse.flat(d)[index].$1;
      if (!Entitlement.senseOpen((d['levels'] as List).indexOf(lv))) {
        await PaywallScreen.show(context);
        if (mounted) setState(() {});
        return;
      }
    }
    if (!mounted) return;
    await openFull(context, (_) => SenseLessonScreen(index: index));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('언어감각 익히기'))),
      body: d == null ? const Center(child: CircularProgressIndicator()) : _body(d),
    );
  }

  Widget _body(Map<String, dynamic> d) {
    final all = SenseCourse.flat(d);
    bool isRef(Map<String, dynamic> l) => l['kind'] == 'ref';
    final next = all.indexWhere((e) => !isRef(e.$2) && !_done.contains(e.$2['id']));
    final real = all.where((e) => !isRef(e.$2)).toList();
    final children = <Widget>[
      Text(tr('영상을 보고, 대화를 통째로 외워요. 규칙은 참고에만 있어요.'),
          style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
      const SizedBox(height: 4),
      Text(trf('{0}/{1}회 마침', [real.where((e) => _done.contains(e.$2['id'])).length, real.length]),
          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
    ];
    var i = 0;
    for (final lv in (d['levels'] as List).cast<Map<String, dynamic>>()) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
        child: Row(children: [
          Expanded(
            child: Text('${lv['id']}  ${lv['title']}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          ),
          if (!Entitlement.senseOpen((d['levels'] as List).indexOf(lv))) const LockBadge(),
        ]),
      ));
      var n = 1;
      for (final ls in (lv['lessons'] as List).cast<Map<String, dynamic>>()) {
        final idx = i;
        final isDone = _done.contains(ls['id']);
        final isNext = idx == next;
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: isNext ? AppColors.washiDeep : AppColors.washi,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isNext ? AppColors.ai : AppColors.line, width: isNext ? 1.4 : 1),
            ),
            child: InkWell(
              key: ValueKey('sense-${ls['id']}'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _open(idx),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(children: [
                  SizedBox(
                    width: 44,
                    child: Text(isRef(ls) ? tr('참고') : trf('{0}회', [n]),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ai)),
                  ),
                  Expanded(
                    child: Text(ls['title'] as String,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                  ),
                  if (isDone)
                    const Icon(Icons.check_circle, color: AppColors.matcha, size: 20)
                  else if (isNext)
                    Text(tr('다음'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ai)),
                ]),
              ),
            ),
          ),
        ));
        i++;
        if (!isRef(ls)) n++;
      }
    }
    return ListView(padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)), children: children);
  }
}

/// 한 회차 — 문법 설명 → 문장. 아래 「마침 · 다음 회」 버튼.
class SenseLessonScreen extends StatefulWidget {
  final int index;
  const SenseLessonScreen({super.key, required this.index});

  @override
  State<SenseLessonScreen> createState() => _SenseLessonScreenState();
}

class _SenseLessonScreenState extends State<SenseLessonScreen> {
  List<(Map<String, dynamic>, Map<String, dynamic>)>? _all;

  @override
  void initState() {
    super.initState();
    SenseCourse.load().then((d) {
      if (mounted) setState(() => _all = SenseCourse.flat(d));
    });
  }

  Future<void> _finish() async {
    final all = _all!;
    if (all[widget.index].$2['kind'] == 'ref') {
      Navigator.of(context).pop(); // 참고는 기록하지 않는다
      return;
    }
    await SenseCourse.markDone(all[widget.index].$2['id'] as String);
    if (!mounted) return;
    var nextIdx = widget.index + 1;
    while (nextIdx < all.length && all[nextIdx].$2['kind'] == 'ref') {
      nextIdx++;
    }
    // 다음 회차가 잠긴 급이면(이용권) 목록으로 돌아간다 — 목록에서 누르면 결제 화면
    final levels = {for (final e in all) e.$1}.toList();
    if (nextIdx < all.length && !Entitlement.senseOpen(levels.indexOf(all[nextIdx].$1))) nextIdx = all.length;
    if (nextIdx < all.length) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SenseLessonScreen(index: nextIdx)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    if (all == null) {
      return const Scaffold(backgroundColor: AppColors.washi, body: Center(child: CircularProgressIndicator()));
    }
    final (lv, ls) = all[widget.index];
    final lessons = (lv['lessons'] as List);
    final isRef = ls['kind'] == 'ref';
    final n = lessons.take(lessons.indexOf(ls) + 1).where((l) => (l as Map)['kind'] != 'ref').length;
    final points = ((ls['points'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final memorize = ls['kind'] == 'memorize';
    final last = !all.skip(widget.index + 1).any((e) => e.$2['kind'] != 'ref');
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Text('${lv['id']} · ${isRef ? tr('참고') : trf('{0}회', [n])}  ${ls['title']}', overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: memorize ? [_Memorize(lesson: ls)] : [for (final p in points) _Point(point: p)],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
        child: FilledButton(
          key: const ValueKey('sense-finish'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.ai, minimumSize: const Size.fromHeight(48)),
          onPressed: _finish,
          child: Text(isRef ? tr('닫기') : (last ? tr('마침') : tr('마침 · 다음 회'))),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final Map<String, dynamic> point;
  const _Point({required this.point});

  @override
  Widget build(BuildContext context) {
    final sentences = (point['sentences'] as List).cast<Map<String, dynamic>>();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.washi,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: kCardShadow,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(point['head'] as String,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ai)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(8)),
          child: Text('💡 ${point['tip']}', style: const TextStyle(fontSize: 13, color: AppColors.sumi, height: 1.45)),
        ),
        const SizedBox(height: 6),
        for (final s in sentences)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SelectableText(
                    s['en'] as String,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.35),
                  ),
                  Text(s['ko'] as String,
                      style: const TextStyle(fontSize: 13, color: AppColors.ai, fontWeight: FontWeight.w600)),
                ]),
              ),
              IconButton(
                tooltip: tr('듣기'),
                icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 22),
                onPressed: () => TtsService.instance.speak(s['en'] as String),
              ),
            ]),
          ),
      ]),
    );
  }
}

/// 외울 대화 회차 — 영상 → 안내 한 줄 → 문장만(문법 설명 없음).
/// 문장 표시 `{글자|번호}` = 그 급의 문법 자리. 같은 번호는 영어·한국어에서 같은 색 — 두 말을 견줘 보게(일본어앱과 같음).
const _kMarkColors = [
  Color(0xFFD83A3A), Color(0xFF2F6FDB), Color(0xFF1E9E5A), Color(0xFFE08A00), Color(0xFF8E44AD),
  Color(0xFF00897B), Color(0xFFC2185B), Color(0xFF5D4037), Color(0xFF3949AB), Color(0xFF7CB342),
];

final _kMark = RegExp(r'\{([^|}]+)\|(\d+)\}');

/// 표시 없앤 본문(듣기용).
String plainMarked(String s) => s.replaceAllMapped(_kMark, (m) => m.group(1)!);

List<InlineSpan> markedSpans(String s, TextStyle base) {
  final out = <InlineSpan>[];
  var i = 0;
  for (final m in _kMark.allMatches(s)) {
    if (m.start > i) out.add(TextSpan(text: s.substring(i, m.start)));
    final c = _kMarkColors[(int.parse(m.group(2)!) - 1) % _kMarkColors.length];
    out.add(TextSpan(
        text: m.group(1),
        style: TextStyle(color: c, fontWeight: FontWeight.w900, decoration: TextDecoration.underline, decorationColor: c.withValues(alpha: 0.5), decorationThickness: 2)));
    i = m.end;
  }
  if (i < s.length) out.add(TextSpan(text: s.substring(i)));
  return out;
}

class _Memorize extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const _Memorize({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final sentences = (lesson['sentences'] as List).cast<Map<String, dynamic>>();
    final video = (lesson['video'] as String?) ?? '';
    const enStyle = TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.45);
    const koStyle = TextStyle(fontSize: 14, color: AppColors.sumi, height: 1.45);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // 영상 주소가 있을 때만 영상 칸을 보인다(빈 「영상 준비 중」 칸은 심사에서 미완성으로 보임 — 2026-11-22)
      if (video.isNotEmpty) ...[LessonVideo(url: video), const SizedBox(height: 12)],
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10)),
        child: Text('💡 ${lesson['note'] ?? ''}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.sumi, height: 1.45)),
      ),
      const SizedBox(height: 6),
      for (var i = 0; i < sentences.length; i++)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(color: AppColors.washi, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${i + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ai)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (sentences[i]['who'] != null) Text(sentences[i]['who'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.sumiLight)),
                Text.rich(TextSpan(style: enStyle, children: markedSpans(sentences[i]['en'] as String, enStyle))),
                const SizedBox(height: 4),
                Text.rich(TextSpan(style: koStyle, children: markedSpans(sentences[i]['ko'] as String, koStyle))),
              ]),
            ),
            IconButton(
              tooltip: tr('듣기'),
              icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 22),
              onPressed: () => TtsService.instance.speak(plainMarked(sentences[i]['en'] as String)),
            ),
          ]),
        ),
      if ((lesson['footnotes'] as List?)?.isNotEmpty ?? false) ...[
        const SizedBox(height: 16),
        Text(tr('한국어와 다른 곳만 잠깐'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.sumiLight)),
        const SizedBox(height: 4),
        for (final f in (lesson['footnotes'] as List).cast<String>())
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text('· $f', style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight, height: 1.45)),
          ),
      ],
    ]);
  }
}

/// 회차 영상 — 주소가 비었으면 「영상 준비 중」 칸, 있으면 서버에서 바로 틀기(앱에 넣지 않는다). 탭 = 재생/멈춤.
class LessonVideo extends StatefulWidget {
  final String url;
  const LessonVideo({super.key, required this.url});
  @override
  State<LessonVideo> createState() => _LessonVideoState();
}

class _LessonVideoState extends State<LessonVideo> {
  VideoPlayerController? _c;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.url.isEmpty) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c = c;
    c.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((Object e) {
      debugPrint('LessonVideo: $e');
      if (mounted) setState(() => _failed = true);
    });
    c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Widget _box(Widget child) => Container(
        key: const ValueKey('memorize-video'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        alignment: Alignment.center,
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || _failed) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _box(Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎬', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          Text(_failed ? tr('영상을 불러오지 못했어요') : tr('영상 준비 중'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        ])),
      );
    }
    final v = c.value;
    if (!v.isInitialized) return AspectRatio(aspectRatio: 16 / 9, child: _box(const CircularProgressIndicator()));
    return AspectRatio(
      aspectRatio: v.aspectRatio,
      child: GestureDetector(
        onTap: () {
          if (v.position >= v.duration) c.seekTo(Duration.zero);
          v.isPlaying ? c.pause() : c.play();
        },
        child: _box(Stack(fit: StackFit.expand, children: [
          VideoPlayer(c),
          if (!v.isPlaying) const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white70)),
          Align(alignment: Alignment.bottomCenter, child: VideoProgressIndicator(c, allowScrubbing: true)),
        ])),
      ),
    );
  }
}
