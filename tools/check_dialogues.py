#!/usr/bin/env python3
"""회화 검사기(영어) — 공통 프롬프터 §12, docs/DIALOGUE_EN.md.
  ~/.venvs/en/bin/python tools/check_dialogues.py [--fix]
--fix: 턴의 `new`(구간 밖이면서 앞 편에 없던 낱말)와 `tags` 의 expr: 를 다시 채운다. `lemmas` 는 tools/add_lemmas.py.
오류 = 턴 수·단어 수·새 단어/턴·표현 풀·반전·변수·한국어·채팅 규칙. 경고 = 3문장 턴·감사로 끝남·연애 심쿵 없음. 오류가 있으면 종료 코드 1."""
import csv, glob, json, re, sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
import add_lemmas  # noqa: E402

TURNS = {'R0': (6, 8), 'R1': (6, 8), 'R2': (8, 12), 'R3': (12, 16), 'R4': (12, 16)}
WORDS = {('R1', 'short'): (1, 9), ('R1', 'survival'): (1, 9), ('R1', 'long'): (1, 10), ('R1', 'chat'): (1, 7),
         ('R0', 'short'): (1, 6), ('R0', 'survival'): (1, 6), ('R0', 'long'): (1, 6), ('R0', 'chat'): (1, 6)}
WORDS_UP = {'R2': (1, 12), 'R3': (1, 16), 'R4': (1, 18)}
NEW_PER_TURN = {'R0': 3, 'R1': 3, 'R2': 4, 'R3': 5, 'R4': 6}
TWISTS = {'chaos', 'slip', 'reveal', 'emotion', 'ignore'}
VARS = {'{name}', '{country}', '{city}'}
ISLANDS = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study']
ORDER = ['R0', 'R1', 'R2', 'R3', 'R4']
BAND_OF = {'R0': 'R1'}
WORD = re.compile(r"[A-Za-z0-9]+(?:['’-][A-Za-z0-9]+)*")


def nwords(s):
    return len(WORD.findall(re.sub(r'\{[a-z_]+\}', ' x ', s)))


def norm(s):
    return re.sub(r'\s+', ' ', re.sub(r"[^a-z0-9' ]", ' ', s.lower().replace('’', "'"))).strip()


def has_expr(expr, text):
    return f' {norm(expr)} ' in f' {norm(text)} '


def bands():
    cum, acc = {}, set()
    rows = list(csv.DictReader(open(ROOT / 'assets/data/words/en_words.csv', encoding='utf-8')))
    for lv in ['R1', 'R2', 'R3', 'R4']:
        acc |= {r['word'].lower() for r in rows if r['level'] == lv}
        cum[lv] = set(acc)
    return cum


def sort_key(ep):
    m = re.search(r'_([a-z])(\d+)$', ep['id'])
    isl = ISLANDS.index(ep['island']) if ep['island'] in ISLANDS else 99
    return (ORDER.index(ep['region']), isl, m[1], int(m[2]))


def main():
    fix = '--fix' in sys.argv
    pool = [r['expr'] for r in csv.DictReader(open(ROOT / 'data/expressions/top_expressions.csv', encoding='utf-8'))]
    cum = bands()
    eps = []
    for f in glob.glob(str(ROOT / 'assets/data/dialogues/R*/*/*.json')):
        ep = json.load(open(f, encoding='utf-8'))
        ep['_f'] = f
        eps.append(ep)
    eps.sort(key=sort_key)
    seen, errs, warns = set(), 0, 0
    stat, used = defaultdict(Counter), Counter()
    for ep in eps:
        lv, eid, kind = ep['region'], ep['id'], ep['kind']
        e, w = [], []
        lo, hi = TURNS[lv]
        n = len(ep['turns'])
        if not lo <= n <= hi:
            e.append(f'턴 수 {n}(기준 {lo}~{hi})')
        if ep.get('twist_type') not in TWISTS:
            e.append(f"twist_type {ep.get('twist_type')}")
        if not 1 <= ep.get('twist', 0) <= n:
            e.append(f"twist 턴 {ep.get('twist')}")
        stat[lv][ep.get('twist_type')] += 1
        stat['전체'][ep.get('twist_type')] += 1
        wlo, whi = WORDS.get((lv, kind)) or WORDS_UP.get(lv, (1, 99))
        band = cum[BAND_OF.get(lv, lv)]
        text_all = ' '.join(t['en'] for t in ep['turns'])
        hits = [x for x in pool if has_expr(x, text_all)]
        used.update(hits)
        if len(hits) < 2:
            e.append(f'표현 풀 {len(hits)}개(≥2)')
        for x in ep.get('expressions', []):
            if not has_expr(x, text_all):
                e.append(f'expressions 의 {x!r} 가 대사에 없음')
        changed = False
        for t in ep['turns']:
            s, num = t['en'], t['num']
            c = nwords(s)
            if c > whi or c < wlo:
                e.append(f'{num}번 {c}단어({wlo}~{whi})')
            only_var = not re.sub(r'\{[a-z_]+\}|[^A-Za-z]', '', s)
            one_ok = kind == 'chat' or num in (ep.get('twist'), n) or only_var or any(norm(x) == norm(s) for x in pool)
            if c == 1 and not one_ok:
                e.append(f'{num}번 1단어 단답')
            for v in re.findall(r'\{[^}]*\}', s):
                if v not in VARS:
                    e.append(f'{num}번 변수 {v}')
            if not t.get('ko'):
                e.append(f'{num}번 한국어 없음')
            if not t.get('note'):
                w.append(f'{num}번 note 없음')
            if t['speaker'] not in ep['speakers']:
                e.append(f"{num}번 화자 {t['speaker']}")
            if len(re.findall(r'[.!?…]+(?:\s|$)', s)) > 3:
                w.append(f'{num}번 4문장 이상')
            if kind == 'chat' and t.get('ui') != 'bubble':
                e.append(f'{num}번 채팅 ui')
            new = []
            for _, b, _r in add_lemmas.lemmas(s):
                if b not in band and b not in seen and b not in new:
                    new.append(b)
            seen.update(b for _, b, _r in add_lemmas.lemmas(s))
            if len(new) > NEW_PER_TURN[lv]:
                e.append(f'{num}번 새 단어 {len(new)}개 {new}')
            tags = [x for x in t.get('tags', []) if not x.startswith('expr:')] + [f'expr:{x}' for x in pool if has_expr(x, s)]
            if fix and (t.get('new') != new or t.get('tags') != tags):
                t['new'], t['tags'] = new, tags
                changed = True
        if ep['turns'] and re.search(r'\bthank', ep['turns'][-1]['en'], re.I):
            w.append('감사로 끝남')
        if ep['island'] == 'love' and not any('heart' in t.get('tags', []) for t in ep['turns']):
            w.append('연애 편에 심쿵(heart) 없음')
        if changed:
            f = ep.pop('_f')
            Path(f).write_text(json.dumps(ep, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
        for tag, lst in (('✗', e), ('△', w)):
            if lst:
                print(f'{tag} {eid}: ' + ' · '.join(lst))
        errs += bool(e)
        warns += bool(w)
    print()
    for k in sorted(stat):
        c = stat[k]
        tot = sum(c.values())
        ch = c.get('chaos', 0) * 100 / tot
        print(f'{k:4} {tot:3}편 | 카오스 {ch:3.0f}%{"  ← 30% 미만" if ch < 30 else ""} | ' + ' '.join(f'{t}:{c.get(t, 0)}' for t in sorted(TWISTS)))
    print(f'표현 풀 {len(used)}/{len(pool)}개 씀 · 오류 편 {errs} · 경고 편 {warns}')
    sys.exit(1 if errs else 0)


if __name__ == '__main__':
    main()
