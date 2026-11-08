#!/usr/bin/env python3
"""토익 단어 목록 → assets/data/toeic/toeic_words.json (앱내앱 「토익」 첫 기능 '토익 단어 익히기', 사용자 지시 2026-11-08).
표제어 = data/toeic/headwords.txt(낱말만, 1,209어). 뜻 = 절벽 단어장(assets/data/words/en_words.csv)에 있으면 그 뜻, 없으면 tools/toeic_gloss.py(이 세션이 직접 씀).
차례: 핵심 명사 → 동사 → 형용사 → 부사(알파벳순) → 관용표현(tools/toeic_gloss.py I) → A 기본 빈도어(절벽 단어장에 있는 낱말, 빈도순 — 이미 아는 말 점검). 20어 단원은 앱이 자른다.
나중에 전자책 세션이 구조화 JSON(표제어·발음·품사 묶음)을 넘기면 이 스크립트의 입력만 바꾼다 — 출력 형식은 그대로 둔다.
  python3 tools/toeic_words.py"""
import csv, json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
from toeic_gloss import G, I  # noqa: E402

POS = {'n': 'n.', 'v': 'v.', 'a': 'adj.', 'adv': 'adv.', 'prep': 'prep.'}
OURS_POS = {'noun': 'n.', 'verb': 'v.', 'adj': 'adj.', 'adv': 'adv.', 'prep': 'prep.', 'pron': 'pron.', 'conj': 'conj.', 'det': 'det.', 'aux': 'aux.', 'num': 'num.', 'intj': 'intj.'}
GRP = {'n': 'N', 'v': 'V', 'a': 'ADJ', 'adv': 'ADV', 'prep': 'N'}


def main():
    ours = {}
    for r in csv.DictReader(open(ROOT / 'assets/data/words/en_words.csv', encoding='utf-8')):
        ours.setdefault(r['word'].lower(), r)
    heads = [w.strip() for w in open(ROOT / 'data/toeic/headwords.txt', encoding='utf-8') if w.strip()]
    a, rest = [], []
    for w in heads:
        e = ours.get(w)
        if e:
            a.append({'w': w, 'pos': OURS_POS.get(e['pos'], e['pos']), 'ko': e['ko'], 'grp': 'A', 'rank': int(e['rank']), 'level': e['level']})
        elif w in G:
            p, ko = G[w].split('|', 1)
            rest.append({'w': w, 'pos': POS[p], 'ko': ko, 'grp': GRP[p], 'rank': 0, 'level': ''})
        else:
            raise SystemExit(f'뜻 없음: {w} — tools/toeic_gloss.py 에 추가')
    idioms = [{'w': w, 'pos': 'phr.', 'ko': ko, 'grp': 'I', 'rank': 0, 'level': ''} for w, ko in I.items()]
    a.sort(key=lambda x: x['rank'])
    order = {'N': 0, 'V': 1, 'ADJ': 2, 'ADV': 3}
    rest.sort(key=lambda x: (order[x['grp']], x['w']))
    out = rest + idioms + a
    seen = set()
    out = [x for x in out if not (x['w'] in seen or seen.add(x['w']))]  # 같은 낱말이 두 묶음에 있으면 앞 것만
    for i, x in enumerate(out, 1):
        x['n'] = i
    d = ROOT / 'assets/data/toeic'; d.mkdir(parents=True, exist_ok=True)
    json.dump({'_meta': '토익 단어 — 표제어 목록 + 자체 뜻(tools/toeic_gloss.py) 또는 절벽 단어장 뜻. grp N 명사 · V 동사 · ADJ 형용사 · ADV 부사 · I 관용표현 · A 기본 빈도어.', 'words': out},
              open(d / 'toeic_words.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    from collections import Counter
    print(f'토익 단어 {len(out)} · {dict(Counter(x["grp"] for x in out))} · 단원 {(len(out) + 19) // 20}')


if __name__ == '__main__':
    main()
