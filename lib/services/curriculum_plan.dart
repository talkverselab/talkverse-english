import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/embed_env.dart';

/// 토크버스 커리큘럼 단계 목록(CURRICULUM_SPEC §12, 사용자 지시 2026-11-23 「내용도 모두 DB 에서 · 5단계까지」).
/// 단계·제목·편 목록은 앱이 정하지 않는다 — 서버 `GET https://talkverse.uk/api/curriculum/en` 이 주고,
/// 오프라인 기본값은 묶음 `assets/curriculum_en.json`. 서버 rev 가 더 크면 받아 기기에 두고 그것을 쓴다.
/// 읽기에 실패하면 [stages] 가 비어 커리큘럼은 지금 동작(회화 레벨 R 기준)으로 돌아간다.
class CurStage {
  final String n; // '1'..'5' — 진도 저장의 level 칸
  final String title;
  final String desc;
  final List<String> dialogueIds;
  final int pass;
  const CurStage(this.n, this.title, this.desc, this.dialogueIds, this.pass);
}

class CurriculumPlan {
  CurriculumPlan._();
  static final CurriculumPlan instance = CurriculumPlan._();
  static const asset = 'assets/curriculum_en.json';
  static const url = 'https://talkverse.uk/api/curriculum/en';

  int rev = 0;
  List<CurStage> stages = const [];
  bool _loaded = false;

  /// 시험용 — 서버 요청·기기 폴더를 바꿔 끼운다.
  @visibleForTesting
  Future<String?> Function(String url)? fetch;
  @visibleForTesting
  Directory? dir;

  static List<CurStage> parse(Map d) => [
        for (final s in (d['stages'] as List? ?? const []).whereType<Map>())
          CurStage('${s['n']}', '${s['title'] ?? '${s['n']}단계'}', '${s['desc'] ?? ''}', [for (final x in (s['dialogueIds'] as List? ?? const [])) '$x'], (s['pass'] as num?)?.toInt() ?? 80),
      ];

  Future<File> _cache() async => File('${(dir ?? Directory('${await dataDir()}/curriculum')).path}/curriculum_en.json');

  void _apply(Map d) {
    rev = (d['rev'] as num?)?.toInt() ?? 0;
    stages = parse(d);
  }

  /// 묶음 → 기기에 받아 둔 더 새 판 순으로 읽고, 뒤에서 서버를 한 번 본다(바뀌면 [changed] 를 부름).
  Future<void> ensureLoaded({VoidCallback? changed}) async {
    if (_loaded) return;
    _loaded = true;
    try {
      _apply(json.decode(utf8.decode((await rootBundle.load(assetPath(asset))).buffer.asUint8List())) as Map);
    } catch (_) {}
    try {
      final f = await _cache();
      if (await f.exists()) {
        final d = json.decode(await f.readAsString()) as Map;
        if (((d['rev'] as num?)?.toInt() ?? 0) > rev) _apply(d);
      }
    } catch (_) {}
    refresh().then((c) {
      if (c) changed?.call();
    });
  }

  /// 서버 판이 더 새것이면 받아 쓴다. 404(Worker 배포 전)·실패면 그대로.
  Future<bool> refresh() async {
    try {
      final body = await (fetch ?? _get)(url);
      if (body == null) return false;
      final d = json.decode(body) as Map;
      final r = (d['rev'] as num?)?.toInt() ?? 0;
      if (r <= rev || parse(d).isEmpty) return false;
      final f = await _cache();
      await f.parent.create(recursive: true);
      await f.writeAsString(body, flush: true);
      _apply(d);
      return true;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  void debugReset() {
    _loaded = false;
    rev = 0;
    stages = const [];
  }

  Future<String?> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.userAgentHeader, 'talkverse-en/0.1');
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
