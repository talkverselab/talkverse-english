# -*- coding: utf-8 -*-
"""언어감각 외울 대화: Grok 답(data/review/grok/out/sense_L<n>.md)을 assets/data/grammar/sense_course.json 에 그대로 넣는다.
원칙(사용자 2026-11-18): 대사는 Grok 이 쓰고 받은 그대로. 줄 수·화자 순서가 다르면 넣지 않고 알린다.
  python3 tools/grok/merge_sense.py   → 이어서 script_publish(--publish)
"""
import json, os, re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
P = os.path.join(ROOT, 'assets/data/grammar/sense_course.json')
OUT = os.path.join(ROOT, 'data/review/grok/out')


def main():
    d = json.load(open(P, encoding='utf-8'))
    ok = 0
    for lv in d['levels']:
        f = os.path.join(OUT, 'sense_%s.md' % lv['id'])
        if not os.path.exists(f):
            continue
        raw = open(f, encoding='utf-8').read().replace('```', '')
        rows = [[c.strip() for c in l.split('|')] for l in raw.splitlines() if l.count('|') >= 1 and not l.startswith(('===',))]
        sents = [r for r in rows if r[0] != 'note' and len(r) >= 3]
        notes = [' | '.join(r[1:]) for r in rows if r[0] == 'note']
        t = [l for l in lv['lessons'] if l['kind'] == 'memorize'][0]
        if [s['who'] for s in t['sentences']] != [r[0] for r in sents]:
            print('줄 수·화자 다름 — 안 넣음', lv['id'], len(t['sentences']), len(sents)); continue
        bad = [r[1] for r in sents if not re.search(r'\{[^{}|]+\|\d+\}', r[1])]
        if len(bad) > 3:
            print('표시 {말|번호} 가 너무 적음 — 안 넣음', lv['id'], len(bad)); continue
        t['sentences'] = [{'who': r[0], 'en': r[1], 'ko': r[2]} for r in sents]
        if len(notes) == len(t.get('footnotes', [])):
            t['footnotes'] = notes
        else:
            print('note 줄 수 다름 — 설명은 그대로', lv['id'])
        ok += 1
    json.dump(d, open(P, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('넣음', ok)


if __name__ == '__main__':
    main()
