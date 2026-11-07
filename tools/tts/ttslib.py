"""회화 음성 공통(영어): 감정 계획 + 편 JSON → 턴별 남성판·여성판(본문 넷 + 읽을 조각). 일본어앱 tools/tts/ttslib.py 와 같은 구조.
D1 audio_lines 열에 맞춘 이름: text = 영어 본문, reading = 빈 값, rd = 한글 독음, ko = 한국어 뜻.
모든 턴에 m·f 두 판, 판마다 본문과 mp4 하나. 소리 낼 글이 없는 턴(지문·「……」)만 뺀다.
편 id 끝의 `_vox` = 같은 편을 VoxCPM2 로 읽은 판(시험 비교용, 2026-11-07) — 대본·계획은 원래 편을 쓴다.
아직 앱에 넣지 않은 시험 편은 data/tts/episodes/ 에 둔다."""
import glob, json, os, re
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
V = json.load(open(f'{R}/data/tts/voices.json', encoding='utf-8'))
EP = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{R}/assets/data/dialogues/R*/*/*.json') + glob.glob(f'{R}/data/tts/episodes/*.json')}
SIL = re.compile(r'[\s…。、！？!?.,~♪]|\([^)]*\)')
LANG = 'English'
OUT = os.environ.get('TTS_OUT', 'en2')   # PC 출력 폴더. 앞선 결과를 건너뛰지 않게 판마다 나눈다(en = 첫 판, en2 = 감정 낮춘 판)
REF = f'ref_{OUT}'
VOX = '_vox'


def base(ep):
    return ep[:-len(VOX)] if ep.endswith(VOX) else ep


def _josa(word, j):
    """한국어 뜻 칸의 이름 뒤 조사를 받침에 맞춘다."""
    c = word[-1]
    if not ('가' <= c <= '힣'):
        return j
    has = (ord(c) - 0xAC00) % 28 != 0
    pair = {'은': '는', '이': '가', '을': '를', '과': '와', '아': '야', '이랑': '랑', '이에요': '예요', '이라고': '라고'}
    back = {v: k for k, v in pair.items()}
    if j in pair:
        return j if has else pair[j]
    if j in back:
        return back[j] if has else j
    return j


_J = r'(이라고|이에요|이랑|라고|예요|은|는|이|가|을|를|과|와|아|야|랑)(?![가-힣])'


def fills(P, g):
    out = {}
    for k, x in V['fill'].items():
        out[k] = x.get(g) or x
    out.update(P.get('fill', {}))
    return out


def fill(s, F, key):
    """자리 채우기. key = text(영어) · rd(한글 독음) · ko(한국어, 조사 맞춤)."""
    if '{' not in s:
        return s
    if key == 'ko':
        def rep(m):
            w = F.get('{' + m.group(1) + '}', {}).get('ko')
            return m.group(0) if w is None else w + _josa(w, m.group(2))
        s = re.sub(r'\{(\w+)\}' + _J, rep, s)
    for k, x in F.items():
        s = s.replace(k, x.get(key) or x['text'])
    return s


def turns(ep):
    """[{num, speaker, m:{voice,text,reading,rd,ko,segs:[(감정,읽기)]}, f:{…}, same:bool}] — 소리 없는 턴은 뺀다."""
    ep = base(ep)
    P = json.load(open(f'{R}/data/tts/plan/{ep}.json', encoding='utf-8')); d = json.load(open(EP[ep], encoding='utf-8'))
    out = []
    for t in d['turns']:
        T = P['turns'][str(t['num'])]; row = {'num': t['num'], 'speaker': t['speaker']}
        for g in 'mf':
            X = T.get(g) or {}; F = fills(P, g)
            segs = [(s[0], fill(s[-1], F, 'text').strip()) for s in (X.get('segs') or T['segs'])]
            segs = [s for s in segs if SIL.sub('', s[1])]
            row[g] = {'voice': ('am' if g == 'm' else 'af') if t['speaker'] == 'A' else P['cast'][t['speaker']],
                      'text': fill(X.get('text') or t['en'], F, 'text'), 'reading': '',
                      'rd': fill(X.get('rd') or t.get('rd', ''), F, 'rd'), 'ko': fill(X.get('ko') or t.get('ko', ''), F, 'ko'), 'segs': segs}
        if not row['m']['segs'] or not row['f']['segs']:
            continue
        row['same'] = row['m']['voice'] == row['f']['voice'] and row['m']['segs'] == row['f']['segs']
        out.append(row)
    return out


def seg_files(ep):
    """생성할 조각 [(파일이름, 목소리, 감정, 읽기)] — 두 판이 같으면 c 하나, 다르면 m·f."""
    out = []
    for r in turns(ep):
        for tag in (['c'] if r['same'] else ['m', 'f']):
            x = r['m' if tag == 'c' else tag]
            for i, (emo, text) in enumerate(x['segs']):
                out.append((f"{r['num']:02d}_{i}_{tag}.wav", x['voice'], emo, text))
    return out


def job(ep, name, voice, emo, text, out=None):
    """조각 하나의 PC 작업. `_vox` 편은 VoxCPM2(언어 칸 없음, 참고 음성 복제), 그 밖은 MOSS."""
    j = {'out': out or f'{OUT}/{ep}/{name}', 'text': text, 'reference': f'out/{REF}/{voice}_{emo}.wav'}
    if not ep.endswith(VOX):
        j['language'] = LANG
    return j


def planned():
    """감정 계획이 있는 편 id(정렬)."""
    return sorted(os.path.basename(p)[:-5] for p in glob.glob(f'{R}/data/tts/plan/*.json') if os.path.basename(p)[:-5] in EP)
