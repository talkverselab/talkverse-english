#!/usr/bin/env python3
"""생성된 문장 조각을 받아쓰기로 검사하고, 나쁜 조각의 재생성 작업을 만든다(mlx-whisper 필요).
  python qa.py <wav폴더> <편id>... [--jobs <moss_jobs.json>]   결과는 <wav폴더>/qa.json 에 쌓인다(조각 → sim·dur·tries·ok)
소문자로 바꿔 글자·숫자만 남겨 견준다(띄어쓰기·문장부호 무시). 나쁨 = 비슷함 0.90 미만·앞뒤 낱말 누락·잡음 바닥 초과 또는 길이가 글자 수에 견줘 지나치게 길거나 짧음·말이 너무 느림·클리핑.
재생성본은 PC 의 out/<폴더>/retake/<편>/<조각>.t<N>.wav — 받아 온 뒤 다시 돌리면 가장 잘 나온 판을 본 파일로 고른다. 세 번 해도 나쁘면 가장 나은 판을 쓰고 qa.json 에 ok=false 로 남긴다."""
import array, difflib, glob, json, math, os, re, shutil, subprocess, sys
import mlx_whisper
import ttslib as L
M = 'mlx-community/whisper-large-v3-turbo'
NUM = {'1': 'one', '2': 'two', '3': 'three', '4': 'four', '5': 'five', '10': 'ten', '12': 'twelve', '30': 'thirty'}
RATE_MIN = 11 / 1.15   # 말 속도 11~17 글자/초(영어 일상 대화에 맞음), pack 이 최대 1.15배 보정
PASS = float(os.environ.get('TTS_PASS', 0.90))     # 2026-11-07 품질 점검: 0.72 는 앞말 누락이 통과했다
SIL_DB = -40.0   # 이 아래 20ms 프레임 = 말 아닌 프레임
SIL_RUN = 15     # 0.3초 이상 이어진 곳만 — 낱말 사이 순간 낮아짐 제외
SIL_EDGE = 3     # 그 구간 앞뒤 60ms 는 버림
SIL_MIN = 0.15   # 말 아닌 구간 합이 150ms 미만이면 잡음 판정 불가 = 통과
TRIES = int(os.environ.get('TTS_TRIES', 3))   # 재생성 한도. 나중 묶음에서 더 만들 때 6 으로 올린다(tries 를 0 으로 돌리지 말 것 — PC 는 이미 있는 t1~t3 을 건너뛰어 옛 파일이 다시 온다)
FLOOR = -55.0   # 잡음 바닥(dB) — 이보다 크면 다시 만든다


def spell(s):
    """숫자 표기를 맞춘다(12 = twelve, 30% = thirty percent)."""
    s = s.lower().replace('%', ' percent').replace('’', "'")
    return re.sub(r'\d+', lambda m: NUM.get(m.group(0), m.group(0)), s)


def norm(s):
    return re.sub(r'[^a-z0-9]', '', spell(s))


def words(s):
    return re.findall(r'[a-z0-9]+', spell(s))


def floor(f):
    """잡음 바닥(dB) = 가장 긴 말 아닌 구간 하나의 RMS(§5, 2026-11-24 바로잡음). 잴 구간이 모자라면 None(판정 불가 = 통과).
    예전 방식(전 프레임 하위 10%)은 앞뒤 무음이 거의 없는 짧은 조각에서 말소리를 잡음으로 쟀다."""
    o = subprocess.run(['ffmpeg', '-v', 'error', '-i', f, '-ac', '1', '-ar', '16000', '-f', 's16le', '-'], capture_output=True).stdout
    x = array.array('h', o[:len(o) // 2 * 2])
    ms = [sum(v * v for v in x[i:i + 320]) / 320 for i in range(0, len(x) - 320, 320)]
    db = [20 * math.log10(max(math.sqrt(m), 1) / 32768) for m in ms]
    quiet, run = [], []
    for m, d in zip(ms + [None], db + [0.0]):
        if m is not None and d < SIL_DB:
            run.append(m); continue
        if len(run) >= SIL_RUN and len(run) - 2 * SIL_EDGE > len(quiet):   # 가장 긴 구간 하나(ar·pt 와 같은 방식, 11-24)
            quiet = run[SIL_EDGE:len(run) - SIL_EDGE]
        run = []
    if len(quiet) * 0.02 < SIL_MIN:
        return None
    return 20 * math.log10(max(math.sqrt(sum(quiet) / len(quiet)), 1) / 32768)


def noisy(f, limit=None):
    """잡음 바닥이 기준을 넘으면 True. 판정 불가(None)는 통과."""
    v = floor(f)
    return v is not None and v > (FLOOR if limit is None else limit)


def dur(f):
    return float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f], capture_output=True, text=True).stdout or 0)


def speech(f):
    """앞뒤 무음을 뺀 말 길이."""
    o = f + '.sp.wav'
    subprocess.run(['ffmpeg', '-y', '-v', 'error', '-i', f, '-af', 'silenceremove=start_periods=1:start_threshold=-45dB,areverse,silenceremove=start_periods=1:start_threshold=-45dB,areverse', o])
    d = dur(o) if os.path.exists(o) else 0
    if os.path.exists(o):
        os.remove(o)
    return d


def peak(f):
    o = subprocess.run(['ffmpeg', '-hide_banner', '-i', f, '-af', 'volumedetect', '-f', 'null', '-'], capture_output=True, text=True).stderr
    m = re.search(r'max_volume: (-?[\d.]+) dB', o)
    return float(m.group(1)) if m else -99.0


def score(f, text):
    w = norm(text); d = dur(f)
    if d <= 0 or peak(f) < -30:            # 거의 무음으로 나온 조각(생성 실패)
        return 0.0, d
    if d > 2.2 + 0.17 * len(w) or d < 0.025 * len(w):   # 라틴 글자 하나 ≈ 0.07초
        return 0.0, d
    if len(w) <= 4:                       # 아주 짧은 말은 받아쓰기를 믿을 수 없다 — 길이만 본다
        return (1.0 if d <= 2.0 else 0.0), d
    if noisy(f) or peak(f) >= 0:   # 잡음(가장 긴 말 아닌 구간, it 47a861a — uk 결정 11-24)·클리핑
        return 0.0, d
    if len(w) >= 12 and speech(f) and len(w) / speech(f) < RATE_MIN:   # pack 의 1.15배로도 11 글자/초에 못 미친다
        return 0.0, d
    raw = mlx_whisper.transcribe(f, path_or_hf_repo=M, language='en', condition_on_previous_text=False)['text']
    a, b = words(text), words(raw)
    if not b or a[0] != b[0] or a[-1] != b[-1]:   # 앞뒤 낱말이 빠지면 유사도가 높아도 불합격
        return 0.0, d
    return difflib.SequenceMatcher(None, w, norm(raw)).ratio(), d


def main():
    a = sys.argv[1:]; jobs_out = None
    if '--jobs' in a:
        i = a.index('--jobs'); jobs_out = a[i + 1]; a = a[:i] + a[i + 2:]
    wav, eps = a[0], a[1:]
    qf = f'{wav}/qa.json'; Q = json.load(open(qf, encoding='utf-8')) if os.path.exists(qf) else {}
    jobs = []; bad = 0
    for ep in eps:
        for name, voice, emo, text in L.seg_files(ep):
            k = f'{ep}/{name}'; f = f'{wav}/{k}'; q = Q.setdefault(k, {'tries': 0})
            if not os.path.exists(f):
                q.update(sim=0.0, ok=False); bad += 1; continue
            mt = int(os.path.getmtime(f))
            if q.get('text') != text:                # 대사가 바뀌었으면 옛 점수·횟수는 버린다(2026-11-23 한국어앱 발견: 같은 파일 이름에 옛 녹음 점수가 남아 새 녹음을 안 봄)
                q.pop('sim', None); q['tries'] = 0; q['text'] = text
            if q.get('mtime') != mt:                  # 파일이 새로 만들어졌으면 다시 채점
                q.pop('sim', None)
            if 'sim' not in q:
                q['sim'], q['dur'] = score(f, text); q['mtime'] = mt
            for c in sorted(glob.glob(f'{wav}/retake/{k[:-4]}.t*.wav')):          # 받아 온 재생성본 중 더 나은 것을 본 파일로
                s, d = score(c, text)
                if s > q['sim']:
                    shutil.copy(c, f); q['sim'], q['dur'] = s, d; q['mtime'] = int(os.path.getmtime(f))
                os.remove(c)
            q['ok'] = q['sim'] >= PASS
            if not q['ok']:
                bad += 1
                if jobs_out and q['tries'] < TRIES:      # 채점만 할 때(--jobs 없음)는 횟수를 쓰지 않는다
                    q['tries'] += 1
                    jobs.append({**L.job(ep, name, voice, emo, text, out=f"{L.OUT}/retake/{k[:-4]}.t{q['tries']}.wav"), 'seed': 42 + 97 * q['tries']})
    json.dump(Q, open(qf, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    if jobs_out:
        json.dump(jobs, open(jobs_out, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print(f'QA 편 {len(eps)} 나쁨 {bad} 재생성 {len(jobs)}')


if __name__ == '__main__':
    main()
