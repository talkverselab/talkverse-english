#!/usr/bin/env python3
"""편 JSON 의 턴마다 `lemmas`(내용어 [표면형, 기본형, 읽기]) 를 채운다 — 문장 레마 ↔ 단어장 연결(사용자 지시 2026-11-04).
영어는 라틴 문자라 **낱말 단위 + 규칙 기반 기본형**(불규칙 동사·명사 표 + 접미사 규칙, 후보 중 wordfreq 빈도가 높은 것).
기능어(관사·전치사·대명사·조동사·be·접속사·감탄사)는 뺀다. 읽기 칸은 비워 둔다(영어는 발음 표기 데이터가 생기면).
단어장(assets/data/words/en_words.csv)에 없는 레마는 data/review/write/missing_lemmas.csv 로(uk 세션에 넘겨 단어·그림 제작).
  python3 -m venv ~/.venvs/en && ~/.venvs/en/bin/pip install wordfreq
  ~/.venvs/en/bin/python tools/add_lemmas.py            # 편 JSON 에 lemmas 채움 + missing_lemmas.csv
  ~/.venvs/en/bin/python tools/add_lemmas.py --dry "I went to the store and bought apples."   # 한 문장 시험"""
import csv, glob, json, re, sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
try:
    from wordfreq import zipf_frequency
except ImportError:  # wordfreq 가 없으면 단어장만으로 판단
    def zipf_frequency(w, lang):
        return 3.0 if w in VOCAB else 0.0

VAR = re.compile(r'\{[a-z_]+\}')
TOKEN = re.compile(r"[A-Za-z]+(?:'[A-Za-z]+)?")

FUNCTION = set('''a an the this that these those my your his her its our their me him us them i you he she it we they
to of for at in on by from with as into about than and but or so if because when while where who whom whose which what how why
is am are was were be been being do does did have has had can could will would shall should may might must
not no yes oh hey hi hello um uh yeah yep nope okay ok wow ah huh hmm mm
there here then now just very too also only even still already yet ever never always often sometimes
up down out off over back again
some any every each all both few many much more most other another such own same
one two three four five six seven eight nine ten
gonna wanna gotta lemme gimme kinda sorta dunno ya
maya emma jake daniel'''.split())
CONTRACT = {"i'm": [], "you're": [], "he's": [], "she's": [], "it's": [], "we're": [], "they're": [], "that's": [], "there's": [], "what's": ['what'],
            "i've": [], "you've": [], "we've": [], "they've": [], "i'll": [], "you'll": [], "we'll": [], "they'll": [], "he'll": [], "she'll": [], "it'll": [],
            "i'd": [], "you'd": [], "we'd": [], "they'd": [], "he'd": [], "she'd": [], "let's": ['let'],
            "don't": [], "doesn't": [], "didn't": [], "can't": [], "couldn't": [], "won't": [], "wouldn't": [], "shouldn't": [], "isn't": [], "aren't": [],
            "wasn't": [], "weren't": [], "haven't": [], "hasn't": [], "hadn't": [], "mustn't": [], "ain't": [],
            "gonna": ['go'], "wanna": ['want'], "gotta": ['get'], "lemme": ['let'], "gimme": ['give'], "dunno": ['know'], "y'all": []}
IRREGULAR = {}
for line in '''be was were been am is are
go went gone goes
do did done does
have had has
say said says
make made
get got gotten
take took taken
come came
see saw seen
know knew known
think thought
give gave given
find found
tell told
feel felt
leave left
put
keep kept
let
begin began begun
seem
bring brought
hold held
write wrote written
stand stood
hear heard
mean meant
meet met
run ran
pay paid
sit sat
speak spoke spoken
lie lay lain
lead led
read
grow grew grown
lose lost
fall fell fallen
send sent
build built
understand understood
draw drew drawn
break broke broken
spend spent
cut
rise rose risen
drive drove driven
buy bought
wear wore worn
choose chose chosen
eat ate eaten
drink drank drunk
sleep slept
fly flew flown
forget forgot forgotten
teach taught
catch caught
sell sold
fight fought
throw threw thrown
win won
sing sang sung
swim swam swum
ride rode ridden
shake shook shaken
steal stole stolen
wake woke woken
freeze froze frozen
hide hid hidden
bite bit bitten
light lit
shoot shot
sweep swept
bend bent
lend lent
feed fed
bleed bled
deal dealt
dig dug
hang hung
stick stuck
strike struck
swing swung
tear tore torn
wind wound
quit
shut
hurt
hit
cost
set
child children
man men
woman women
person people
foot feet
tooth teeth
mouse mice
goose geese
life lives
knife knives
wife wives
leaf leaves
half halves
shelf shelves
better good best
worse bad worst
further far farther'''.splitlines():
    parts = line.split()
    for p in parts[1:]:
        IRREGULAR.setdefault(p, parts[0])
IRREGULAR.update({'better': 'good', 'best': 'good', 'worse': 'bad', 'worst': 'bad', 'left': 'leave', 'lives': 'life', 'leaves': 'leave'})

def load_vocab():
    out = {}
    with open(ROOT / 'assets/data/words/en_words.csv', encoding='utf-8') as f:
        for r in csv.DictReader(f):
            out.setdefault(r['word'].lower(), r)
    return out

VOCAB = load_vocab()

def candidates(w):
    """접미사 규칙으로 기본형 후보(가능성 높은 순)."""
    c = []
    if w in IRREGULAR:
        return [IRREGULAR[w]]
    if w.endswith('ies') and len(w) > 4: c.append(w[:-3] + 'y')
    if w.endswith('ied') and len(w) > 4: c.append(w[:-3] + 'y')
    if w.endswith('ier') or w.endswith('iest'): c.append(re.sub(r'ie(r|st)$', 'y', w))
    if w.endswith('ing') and len(w) > 5:
        s = w[:-3]
        if len(s) > 2 and s[-1] == s[-2] and s[-1] not in 'lsz': c.append(s[:-1])  # running → run
        c += [s + 'e', s]  # making → make, eating → eat
    if w.endswith('ed') and len(w) > 4:
        s = w[:-2]
        if len(s) > 2 and s[-1] == s[-2] and s[-1] not in 'lsz': c.append(s[:-1])  # stopped → stop
        c += [s, s + 'e'] if not s.endswith('e') else [s]  # liked → like(s='lik'+e), wanted → want
        if s.endswith('e'): c.append(s[:-1])
    if w.endswith('es') and len(w) > 4 and re.search(r'(s|x|z|ch|sh|o)es$', w): c.append(w[:-2])
    if w.endswith('s') and not w.endswith('ss') and not w.endswith('us') and not w.endswith('is') and len(w) > 3: c.append(w[:-1])
    if w.endswith('er') and len(w) > 5: c += [w[:-2], w[:-1]]      # bigger/faster → big/fast, nicer → nice
    if w.endswith('est') and len(w) > 6: c += [w[:-3], w[:-2]]
    if w.endswith('ly') and len(w) > 5: c.append(w[:-2])          # quickly → quick (부사도 형용사 기본형으로)
    c.append(w)
    seen = set(); out = []
    for x in c:
        if x not in seen and len(x) > 1:
            seen.add(x); out.append(x)
    return out

def lemma_of(w):
    cands = candidates(w)
    if cands == [w]: return w
    # 단어장에 있는 후보 → 가장 흔한 후보(zipf ≥ 2.5) → 원형
    for x in cands:
        if x in VOCAB: return x
    best = max(cands, key=lambda x: zipf_frequency(x, 'en'))
    return best if zipf_frequency(best, 'en') >= 2.5 else w

def lemmas(text):
    out = []
    for tok in TOKEN.findall(VAR.sub(' ', text)):
        low = tok.lower().replace('’', "'")
        if low in CONTRACT:
            for b in CONTRACT[low]: out.append([tok, b, ''])
            continue
        if "'" in low:  # dog's, Maya's → 소유격
            low = low.split("'")[0]
        if low in FUNCTION or len(low) < 2: continue
        base = lemma_of(low)
        if base in FUNCTION: continue
        out.append([tok, base, ''])
    return out

def main():
    if len(sys.argv) > 2 and sys.argv[1] == '--dry':
        print(lemmas(' '.join(sys.argv[2:]))); return
    miss = Counter(); ex = {}; tot = hit = 0
    files = sorted(glob.glob(str(ROOT / 'assets/data/dialogues/R*/*/*.json')) + glob.glob(str(ROOT / 'assets/data/toeic/dialogues/T*/*/*.json')))
    for f in files:
        d = json.load(open(f, encoding='utf-8')); ch = False
        for t in d['turns']:
            out = lemmas(t.get('tl') or t.get('en') or '')
            for s, b, _ in out:
                tot += 1
                if b in VOCAB: hit += 1
                else:
                    miss[b] += 1; ex.setdefault(b, t.get('tl') or t.get('en') or '')
            if t.get('lemmas') != out: t['lemmas'] = out; ch = True
        if ch: open(f, 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
    outdir = ROOT / 'data/review/write'; outdir.mkdir(parents=True, exist_ok=True)
    with open(outdir / 'missing_lemmas.csv', 'w', encoding='utf-8', newline='') as fo:
        w = csv.writer(fo); w.writerow(['lemma', 'reading', 'count', 'example'])
        for b, n in miss.most_common(): w.writerow([b, '', n, ex[b]])
    print(f'편 {len(files)} · 내용어 {tot} · 단어장 있음 {hit/tot:.0%} · 없는 레마 {len(miss)} → missing_lemmas.csv' if tot else f'편 {len(files)} — 회화가 아직 없음(missing_lemmas.csv 는 머리글만)')

if __name__ == '__main__':
    main()
