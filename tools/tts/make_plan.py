#!/usr/bin/python3
"""회화 파일의 감정 열 → 감정 계획 data/tts/plan/<편id>.json 자동 생성(사용자 지시 2026-11-07, 감정을 다시 손으로 적지 않는다).
턴의 `emotion`, 감정이 바뀌는 턴은 `segs`([감정, 본문])을 읽는다. 목소리는 data/tts/cast.json. 이모지는 읽을 글에서 뺀다.
이미 있는 계획의 m·f 판(학습자 성별로 말이 달라지는 턴)은 그대로 둔다. 그 뒤 make_jobs 가 (목소리, 감정) 참고 음성으로 조각을 만든다.
  python3 tools/tts/make_plan.py [편id...] [--check]    없으면 회화 전부. --check = 파일을 쓰지 않고 지금 계획과 다른 편만 알린다."""
import json, os, re, sys
import ttslib as L

CAST = {k: v for k, v in json.load(open(f'{L.R}/data/tts/cast.json', encoding='utf-8')).items() if not k.startswith('_')}
EMOJI = re.compile(r'\s*[\U0001F000-\U0001FAFF☀-➿️]+\s*')


def seg(emo, text):
    clean = re.sub(r'\s+', ' ', EMOJI.sub(' ', text).replace('…', ' ')).strip()  # 「…」을 읽게 하면 늘어진다, 쉼은 pack 이 넣는다
    if re.search(r'\d', clean):
        raise SystemExit(f'숫자는 읽기를 정해야 함: {text!r} — 대사에 글자로 쓰거나 계획에 읽기 칸을 넣는다')
    return [emo, text] if clean == text else [emo, text, clean]


def plan(ep, old=None):
    d = json.load(open(L.EP[ep], encoding='utf-8'))
    cast = {}
    for k, name in d['speakers'].items():
        if k == 'A':
            continue
        if name not in CAST:
            raise SystemExit(f'{ep}: cast.json 에 없는 인물 {name}')
        cast[k] = CAST[name]
    turns = {}
    for t in d['turns']:
        if not t.get('segs') and not t.get('emotion'):
            raise SystemExit(f"{ep} {t['num']}번: 감정 열 없음")
        x = {'segs': [seg(*s) for s in t['segs']] if t.get('segs') else [seg(t['emotion'], t['en'])]}
        for g in 'mf':
            if old and old['turns'].get(str(t['num']), {}).get(g):
                x[g] = old['turns'][str(t['num'])][g]
        turns[str(t['num'])] = x
    return {'ep': ep, 'cast': cast, 'turns': turns}


def main():
    a = sys.argv[1:]; check = '--check' in a
    ids = [x for x in a if x != '--check'] or sorted(e for e in L.EP)
    made = diff = 0
    for ep in ids:
        f = f'{L.R}/data/tts/plan/{ep}.json'
        old = json.load(open(f, encoding='utf-8')) if os.path.exists(f) else None
        new = plan(ep, old)
        if new == old:
            continue
        diff += 1
        if check:
            print('다름', ep)
        else:
            json.dump(new, open(f, 'w', encoding='utf-8'), ensure_ascii=False, indent=1); made += 1
    print(f'편 {len(ids)} · 바뀐 계획 {diff}' + ('' if check else f' · 씀 {made}'))


if __name__ == '__main__':
    main()
