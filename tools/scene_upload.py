#!/usr/bin/env python3
"""영어 장면 컷을 그림 저장소(R2 talkverse-art + D1 talkverse-db.art_scenes)에 올린다(사용자 지시 2026-11-05, 일본어앱 판 규칙).
  ~/.venvs/img/bin/python tools/scene_upload.py [편id ...]    (없으면 data/review/scenes 의 컷 전부. 여자판은 편id = <편>_f)
- 원본 = data/review/scenes/<편id>_<n>.jpg. Grok 화면 캡처의 둥근 모서리를 2.5% 잘라내고 가로 1168 로 맞춘 뒤 webp q86,
  scene/en/<편id>/cut<n>.webp 와 가로 584 판 cut<n>_584.webp. 3:2(±5%) 밖이면 올리지 않는다.
- 환경변수 SKIP="편id:n,…" = 그 컷은 올리지 않는다(검수에서 떨어진 새 컷 — 서버의 기존 컷 유지).
- D1 은 lang='en' 행만 INSERT OR REPLACE. sha1(원본)이 같으면 건너뜀. 키에 ?v= 를 붙이지 않는다(매니페스트가 sha1 앞 8자리를 붙임).
"""
import datetime
import glob
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'data/review/scenes')
W = ['npx', '-y', 'wrangler@4']
KNOWN = {os.path.basename(f)[:-5] for f in glob.glob(os.path.join(ROOT, 'assets/data/dialogues/R*/*/*.json'))}


def wr(args):
    return subprocess.run(W + args, cwd=ROOT, capture_output=True, text=True)


def d1_sha():
    r = wr(['d1', 'execute', 'talkverse-db', '--remote', '--json', '--command', "SELECT episode,cut,sha1 FROM art_scenes WHERE lang='en'"])
    return {(x['episode'], int(x['cut'])): x['sha1'] for x in json.loads(r.stdout)[0]['results']}


def cuts(only):
    for f in sorted(glob.glob(os.path.join(SRC, '*.jpg'))):
        m = re.fullmatch(r'(.+?)(_f)?_(\d)\.jpg', os.path.basename(f))
        if not m or m[1] not in KNOWN:
            continue
        ep = m[1] + (m[2] or '')
        if f'{ep}:{m[3]}' in os.environ.get('SKIP', '').split(','):
            continue
        if not only or ep in only:
            yield ep, int(m[3]), f


def put(job):
    key, path = job
    for _ in range(3):
        r = wr(['r2', 'object', 'put', f'talkverse-art/{key}', '--file', path, '--content-type', 'image/webp', '--remote'])
        if r.returncode == 0:
            return None
    return key + ' ' + r.stderr[-200:]


def main():
    have = d1_sha()
    tmp = tempfile.mkdtemp()
    now = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d %H:%M:%S')
    jobs, sql, bad, skip = [], [], [], 0
    for ep, n, src in cuts(set(sys.argv[1:])):
        sha = hashlib.sha1(open(src, 'rb').read()).hexdigest()
        if have.get((ep, n)) == sha:
            skip += 1
            continue
        im = Image.open(src).convert('RGB')
        d = round(im.width * 0.025)
        im = im.crop((d, d, im.width - d, im.height - d))
        if abs(im.width / im.height - 1.5) > 0.075:
            bad.append(f'{ep}/{n} {im.size}')
            continue
        big = im.resize((1168, round(im.height * 1168 / im.width)), Image.LANCZOS)
        small = im.resize((584, round(im.height * 584 / im.width)), Image.LANCZOS)
        k1, k2 = f'scene/en/{ep}/cut{n}.webp', f'scene/en/{ep}/cut{n}_584.webp'
        for k, i in ((k1, big), (k2, small)):
            p = os.path.join(tmp, k.replace('/', '_'))
            i.save(p, 'WEBP', quality=86)
            jobs.append((k, p))
        sql.append(f"INSERT OR REPLACE INTO art_scenes (lang, episode, cut, key_1168, key_584, w, h, sha1, created_at) "
                   f"VALUES ('en','{ep}',{n},'{k1}','{k2}',{big.width},{big.height},'{sha}','{now}');")
    print('올릴 컷', len(sql), '건너뜀', skip, '규격 밖', bad, flush=True)
    with ThreadPoolExecutor(6) as ex:
        fails = [x for x in ex.map(put, jobs) if x]
    if fails:
        print('R2 실패', len(fails), fails[:3], flush=True)
        sys.exit(1)
    if sql:
        f = os.path.join(tmp, 'x.sql')
        open(f, 'w').write('\n'.join(sql) + '\n')
        r = wr(['d1', 'execute', 'talkverse-db', '--remote', '--file', f, '-y'])
        if r.returncode != 0:
            print('D1 실패', r.stderr[-400:], flush=True)
            sys.exit(1)
    print(f'DONE 올림 {len(sql)} · 건너뜀 {skip} · 규격 밖 {len(bad)}', flush=True)


main()
