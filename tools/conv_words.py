#!/usr/bin/env python3
"""회화 단어 목록 — 회화 편의 레마 중 절벽 단어표 2,000위 밖이면서 단어장(en_words.csv)에 있는 것.
절벽 단어 화면의 「회화 단어 포함」이 읽는다(사용자 지시 2026-11-07). 회화가 늘면 tools/add_lemmas.py 뒤에 다시 돌린다.
  python3 tools/conv_words.py   → assets/data/freq/conv_words_en.json"""
import collections, csv, glob, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CAP = 2000
SKIP = set()  # 등장 인물 이름·연출 지시어가 레마로 섞이면 여기에

words = {}
with open(ROOT / 'assets/data/words/en_words.csv', encoding='utf-8') as f:
    for r in csv.DictReader(f):
        words.setdefault(r['word'].lower(), r)
lem = collections.Counter()
for p in glob.glob(str(ROOT / 'assets/data/dialogues/R*/**/*.json'), recursive=True):
    for t in json.load(open(p, encoding='utf-8')).get('turns', []):
        for l in t.get('lemmas', []):
            b = l[1].lower()
            if b in words and int(words[b]['rank']) > CAP and b not in SKIP:
                lem[b] += 1
out = [{'word': words[w]['word'], 'n': n} for w, n in lem.most_common()]
dest = ROOT / 'assets/data/freq/conv_words_en.json'
dest.parent.mkdir(parents=True, exist_ok=True)
json.dump({'_meta': '회화 레마 중 2,000위 밖이면서 단어장에 있는 것 · tools/conv_words.py', 'words': out}, open(dest, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(len(out), '어 →', dest.name)
