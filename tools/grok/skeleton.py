# -*- coding: utf-8 -*-
"""Grok 에 보낼 뼈대(대사 칸 비움) 만들기 — uk 공지 2026-11-19: 대사째 첨부하면 「빠른」 모드가 초안 문장을 베낀다.
초안(data/drafts)의 각 줄에서 영어를 지우고, 그 줄이 할 일을 문장으로 적는다(흐름 = 초안 한국어 뜻, 꼭 넣을 표현·변수·문법 표시, 반전·심쿵 표시).
검사기 조건(급별 낱말 수, 한 단어 단답 금지, 표현 목록)도 머리에 넣는다.
  python3 tools/grok/skeleton.py <편id>...   → data/review/grok/skel/<id>.txt
"""
import os, re, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import check_dialogues as C  # noqa: E402

LVL = {'r0': 'R0', 'r1': 'R1', 'r2': 'R2', 'r3': 'R3', 'r4': 'R4', 't1': 'T1'}
EASY = {'R0': '왕초보 — 아주 기초 낱말만, 한 줄 한 문장', 'R1': '초보 — 쉬운 낱말, 한 줄 1~2문장', 'R2': '중급 — 일상 낱말, 한 줄 1~2문장',
        'R3': '고급 — 자연스러운 일상 구어, 한 줄 1~3문장', 'R4': '최상급 — 원어민 일상 구어', 'T1': '토익 Part 3·4 중급 비즈니스 회화'}


def block(eid):
    for f in sorted(os.listdir(os.path.join(ROOT, 'data/drafts'))):
        t = open(os.path.join(ROOT, 'data/drafts', f), encoding='utf-8').read()
        m = re.search(r'(?ms)^=== %s\s*$.*?(?=^=== |\Z)' % re.escape(eid), t)
        if m:
            return m.group(0).strip()


def norm(s):
    return ' %s ' % re.sub(r'[^a-z0-9\' ]', ' ', s.lower().replace('’', "'")).strip()


def main():
    os.makedirs(os.path.join(ROOT, 'data/review/grok/skel'), exist_ok=True)
    for eid in sys.argv[1:]:
        b = block(eid)
        hd, body = b.split('\n--\n', 1)
        H = {l.split(':', 1)[0]: l.split(':', 1)[1].strip() for l in hd.splitlines()[1:] if ':' in l}
        lv = LVL[eid[:2]]
        kind = H.get('kind', 'short')
        lo, hi = C.WORDS.get((lv, kind)) or C.WORDS_UP.get(lv, (1, 99))
        exprs = [x.strip() for x in H.get('expr', '').split('|') if x.strip()]
        tw = int(H['twist'].split()[0]); twt = H['twist'].split()[1]
        rows = [l for l in body.splitlines() if l.count('|') >= 3]
        out = [l for l in hd.splitlines()]
        out.append('level: %s · 한 줄 영어 %d~%d 낱말 · 한 낱말 대답 금지(반전·마지막 줄 빼고)' % (EASY[lv], lo, hi))
        out.append('--')
        placed = set()
        for k, r in enumerate(rows, 1):
            c = [x.strip() for x in r.split('|')]
            who, en, ko = c[0], c[1], c[2]
            need = []
            for x in exprs:
                if x not in placed and norm(x) in norm(en):
                    need.append('「%s」를 이 줄에 그대로' % x); placed.add(x)
            for v in re.findall(r'\{[a-z_]+\}', en):
                need.append('%s 를 그대로' % v)
            for g in dict.fromkeys(re.findall(r'\*([^*]+)\*', en)):
                need.append('문법 줄: %s 를 *%s* 로, 그 절 전체를 _밑줄_ 로 감싸고 메모는 § 로 시작' % (g, g))
            if k == tw:
                need.append('← 반전(%s)' % twt)
            if 'heart' in c[-1]:
                need.append('← 심쿵 줄(말을 다 하지 않고 여운)')
            key = need or k in (1, len(rows))
            flow = ('흐름: %s' % ko) if key else '흐름: (자유 — 장면·앞뒤 줄에 맞게 네가 정한다)'
            out.append('%s | ____ | %s%s' % (who, flow, (' · ' + ' · '.join(need)) if need else ''))
        left = [x for x in exprs if x not in placed]
        if left:
            out.append('(표현 %s 도 어느 줄엔가 그대로 넣기)' % ' · '.join('「%s」' % x for x in left))
        open(os.path.join(ROOT, 'data/review/grok/skel/%s.txt' % eid), 'w', encoding='utf-8').write('\n'.join(out) + '\n')
    print('뼈대', len(sys.argv) - 1)


if __name__ == '__main__':
    main()
