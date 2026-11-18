# -*- coding: utf-8 -*-
"""Grok 답(data/review/grok/out/<id>.md)을 초안 파일(data/drafts/*.txt)의 같은 편 자리에 그대로 붙인다.
원칙(사용자 2026-11-18): 대사는 Grok 이 쓰고 받은 그대로 — Claude 가 다듬지 않는다.
기계적인 것만 맞춘다: ① 줄 수·화자 순서가 초안과 다르면 붙이지 않고 알림(turn_lock) ② 초안 emo 의 heart 표시가 빠졌으면 그 줄에 되살림.
  python3 tools/grok/merge_out.py [편id ...]   (없으면 out 전부) → 이어서 draft_to_json · add_lemmas · check_dialogues
"""
import glob, os, re, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
OUT = os.path.join(ROOT, 'data/review/grok/out')
DRAFTS = sorted(glob.glob(os.path.join(ROOT, 'data/drafts/*.txt')))


def block_of(text, eid):
    m = re.search(r'(?ms)^=== %s\s*$.*?(?=^=== |\Z)' % re.escape(eid), text)
    return m


def turns(blk):
    body = blk.split('\n--\n', 1)[1] if '\n--\n' in blk else ''
    return [l for l in body.splitlines() if l.count('|') >= 3]


def main():
    ids = sys.argv[1:] or sorted(os.path.basename(p)[:-3] for p in glob.glob(OUT + '/*.md'))
    texts = {p: open(p, encoding='utf-8').read() for p in DRAFTS}
    ok = bad = 0
    for eid in ids:
        raw = open(os.path.join(OUT, eid + '.md'), encoding='utf-8').read()
        g = block_of(raw, eid)
        if not g:
            print('형식 없음', eid); bad += 1; continue
        new = g.group(0).replace('```', '').strip()
        hit = [p for p, t in texts.items() if block_of(t, eid)]
        if not hit:
            print('초안에 없음', eid); bad += 1; continue
        p = hit[0]; old = block_of(texts[p], eid).group(0)
        to, tn = turns(old), turns(new)
        if [l.split('|')[0].strip() for l in to] != [l.split('|')[0].strip() for l in tn]:
            print('줄 수·화자 다름 — 안 붙임', eid, len(to), len(tn)); bad += 1; continue
        lines = new.splitlines(); j = 0
        for i, l in enumerate(lines):
            if l.count('|') >= 3 and j < len(to):
                if 'heart' in to[j].split('|')[-1] and 'heart' not in l.split('|')[-1]:
                    lines[i] = l.rstrip() + ' heart'
                j += 1
        texts[p] = texts[p].replace(old, '\n'.join(lines) + '\n\n', 1)
        ok += 1
    for p, t in texts.items():
        t = re.sub(r'\n{3,}', '\n\n', t)
        if t != open(p, encoding='utf-8').read():
            open(p, 'w', encoding='utf-8').write(t)
    print('붙임', ok, '· 못 붙임', bad)


if __name__ == '__main__':
    main()
