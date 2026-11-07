#!/usr/bin/env python3
"""회화 초안 글(data/drafts/*.txt) → 편 JSON(assets/data/dialogues/R<레벨>/<주제>/<편id>.json).
초안 형식은 tools/prompts/dialogue_r1.md. Grok 재작성이 끝난 편은 JSON 이 원본이라 다시 만들지 않는다(review 칸이 있으면 건너뜀).
  python3 tools/draft_to_json.py [data/drafts/파일.txt ...]   # 없으면 전부"""
import glob, json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HEAD = {'title', 'emoji', 'scene', 'where', 'goal', 'kind', 'register', 'B', 'C', 'D', 'twist', 'expr', 'flags'}


def parse(text):
    eps = []
    for block in re.split(r'^=== *', text, flags=re.M)[1:]:
        lines = [l.rstrip() for l in block.splitlines()]
        eid, head, turns, body = lines[0].strip(), {}, [], False
        for l in lines[1:]:
            if not l.strip() or l.startswith('#'):
                continue
            if l.strip() == '--':
                body = True
            elif body:
                turns.append([c.strip() for c in l.split('|')])
            else:
                k, _, v = l.partition(':')
                if k.strip() not in HEAD:
                    raise SystemExit(f'{eid}: 모르는 머리글 {k!r}')
                head[k.strip()] = v.strip()
        eps.append(build(eid, head, turns))
    return eps


def build(eid, h, rows):
    m = re.fullmatch(r'r(\d)_([a-z]+)_([a-z]\d+)', eid)
    if not m:
        raise SystemExit(f'편 id 형식 오류: {eid}')
    region, island = f'R{m[1]}', m[2]
    tw = h['twist'].split()
    exprs = [e.strip() for e in h.get('expr', '').split('|') if e.strip()]
    chat = h['kind'] == 'chat'
    speakers = {'A': '{name}', **{k: h[k] for k in 'BCD' if k in h}}
    turns = []
    for i, r in enumerate(rows, 1):
        if len(r) < 3:
            raise SystemExit(f'{eid} {i}번: 칸이 모자람 {r}')
        sp, _, at = r[0].partition('@')
        t = {'num': i, 'speaker': sp, 'en': r[1], 'ko': r[2], 'note': r[3] if len(r) > 3 else '', 'tags': [], 'new': []}
        if chat:
            t['ui'] = 'bubble'
        if at:
            t['at'] = at
        for x in (r[4].split() if len(r) > 4 else []):
            k, _, v = x.partition('=')
            if k == 'stamp':
                t['stamp'] = v
            elif k == 'read':
                t['read'] = v != 'false'
            elif k == 'emo':
                emo = v.split('+')
                if len(emo) == 1:
                    t['emotion'] = emo[0]
                else:  # 한 턴에서 감정이 바뀌면 문장 경계로 조각을 나눈다. `/` 로 나눌 곳을 직접 줄 수도 있다
                    parts = [x.strip() for x in t['en'].split(' / ')] if ' / ' in t['en'] else re.split(r'(?<=[.?!…])\s+', t['en'], maxsplit=len(emo) - 1)
                    if len(parts) != len(emo):
                        raise SystemExit(f'{eid} {i}번: 감정 {len(emo)}개인데 조각 {len(parts)}개')
                    t['en'] = ' '.join(parts)
                    t['segs'] = [[e, x] for e, x in zip(emo, parts)]
            elif k == 'heart':
                t['tags'].append('heart')
            elif k == 'callback':
                t['tags'].append(f'callback:{v}')
            else:
                raise SystemExit(f'{eid} {i}번: 모르는 표시 {x}')
        turns.append(t)
    return {'id': eid, 'region': region, 'island': island, 'kind': h['kind'], 'draft': True, 'purpose': [island], 'domain': [island],
            'title': h['title'], 'emoji': h['emoji'], 'scene': h['scene'], 'where': h.get('where', ''), 'goal': h.get('goal', ''),
            'speakers': speakers, 'register': h['register'], 'twist': int(tw[0]), 'twist_type': tw[1],
            'flags': h.get('flags', '').split(), 'expressions': exprs, 'turns': turns}


def main():
    files = sys.argv[1:] or sorted(glob.glob(str(ROOT / 'data/drafts/*.txt')))
    made = kept = 0
    for f in files:
        for ep in parse(open(f, encoding='utf-8').read()):
            out = ROOT / 'assets/data/dialogues' / ep['region'] / ep['island'] / f"{ep['id']}.json"
            if out.exists() and json.load(open(out, encoding='utf-8')).get('review'):
                kept += 1
                continue
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(json.dumps(ep, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
            made += 1
    print(f'편 {made} 만듦 · 재작성 끝난 편 {kept} 그대로')


if __name__ == '__main__':
    main()
