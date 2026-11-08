#!/usr/bin/env python3
"""회화 초안 글(data/drafts/*.txt) → 편 JSON(assets/data/dialogues/R<레벨>/<주제>/<편id>.json).
초안 형식은 tools/prompts/dialogue_r1.md. Grok 재작성이 끝난 편은 JSON 이 원본이라 다시 만들지 않는다(review 칸이 있으면 건너뜀).
  python3 tools/draft_to_json.py [data/drafts/파일.txt ...]   # 없으면 전부"""
import glob, json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HEAD = {'title', 'emoji', 'scene', 'where', 'goal', 'kind', 'register', 'B', 'C', 'D', 'twist', 'expr', 'flags', 'grammar', 'check'}
MARK = re.compile(r'_([^_]+)_|\*([^*]+)\*')


def unmark(text):
    """'_밑줄 구간_'·'*빨간 레마*' 표기를 벗기고 (깨끗한 글, 밑줄 구간들, 빨간 낱말들) 을 돌려준다(토익 문법 표시, 사용자 지시 2026-11-08)."""
    u, red = [], []
    def strip_red(x):
        return re.sub(r'\*([^*]+)\*', lambda m: (red.append(m.group(1)), m.group(1))[1], x)
    def rep(m):
        if m.group(1) is not None:
            inner = strip_red(m.group(1)); u.append(inner); return inner
        red.append(m.group(2)); return m.group(2)
    clean = MARK.sub(rep, text)
    return clean, u, red


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
    m = re.fullmatch(r'([rt])(\d)_([a-z]+)_([a-z]\d+)', eid)
    if not m:
        raise SystemExit(f'편 id 형식 오류: {eid}')
    region, island = f'{m[1].upper()}{m[2]}', m[3]  # r = 영어 회화 R0~R4 · t = 토익 비즈니스 회화 T1
    tw = h['twist'].split()
    exprs = [e.strip() for e in h.get('expr', '').split('|') if e.strip()]
    chat = h['kind'] == 'chat'
    speakers = {'A': '{name}', **{k: h[k] for k in 'BCD' if k in h}}
    turns = []
    for i, r in enumerate(rows, 1):
        if len(r) < 3:
            raise SystemExit(f'{eid} {i}번: 칸이 모자람 {r}')
        sp, _, at = r[0].partition('@')
        en, under, red = unmark(r[1])
        note = r[3] if len(r) > 3 else ''
        t = {'num': i, 'speaker': sp, 'en': en, 'ko': r[2], 'note': '' if note.startswith('§') else note, 'tags': [], 'new': []}
        if under or red or note.startswith('§'):
            t['gram'] = {'u': under, 'red': red, 'note': note[1:] if note.startswith('§') else ''}
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
    out = {'id': eid, 'region': region, 'island': island, 'kind': h['kind'], 'draft': True, 'purpose': [island], 'domain': [island],
            'title': h['title'], 'emoji': h['emoji'], 'scene': h['scene'], 'where': h.get('where', ''), 'goal': h.get('goal', ''),
            'speakers': speakers, 'register': h['register'], 'twist': int(tw[0]), 'twist_type': tw[1],
            'flags': h.get('flags', '').split(), 'expressions': exprs, 'turns': turns}
    if 'grammar' in h:  # 토익: 편의 문법 포인트(제목|설명) + 대사에서 뽑은 빈칸 문제(문장 | A | B | C | D | 정답)
        g = [x.strip() for x in h['grammar'].split('|')]
        out['grammar'] = {'point': g[0], 'ko': g[1] if len(g) > 1 else ''}
    if 'check' in h:
        c = [x.strip() for x in h['check'].split('|')]
        if len(c) != 6 or c[5] not in 'ABCD':
            raise SystemExit(f'{eid}: check 형식(문장 | A | B | C | D | 정답)')
        out['check'] = {'q': c[0], 'options': c[1:5], 'answer': 'ABCD'.index(c[5])}
    return out


def main():
    files = sys.argv[1:] or sorted(glob.glob(str(ROOT / 'data/drafts/*.txt')))
    made = kept = 0
    for f in files:
        for ep in parse(open(f, encoding='utf-8').read()):
            base = ROOT / ('assets/data/toeic/dialogues' if ep['region'].startswith('T') else 'assets/data/dialogues')
            out = base / ep['region'] / ep['island'] / f"{ep['id']}.json"
            if out.exists() and json.load(open(out, encoding='utf-8')).get('review'):
                kept += 1
                continue
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(json.dumps(ep, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
            made += 1
    print(f'편 {made} 만듦 · 재작성 끝난 편 {kept} 그대로')


if __name__ == '__main__':
    main()
