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
PASS = 0.90     # 2026-11-07 품질 점검: 0.72 는 앞말 누락이 통과했다
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
    o = subprocess.run(['ffmpeg', '-v', 'error', '-i', f, '-ac', '1', '-ar', '16000', '-f', 's16le', '-'], capture_output=True).stdout
    x = array.array('h', o[:len(o) // 2 * 2])
    fr = [math.sqrt(sum(v * v for v in x[i:i + 320]) / 320) for i in range(0, len(x) - 320, 320)]
    fr = sorted(20 * math.log10(max(v, 1) / 32768) for v in fr)
    return fr[len(fr) // 10] if fr else -99.0


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
    if floor(f) > FLOOR or peak(f) >= 0:   # 잡음·클리핑
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
            if 'sim' not in q:
                q['sim'], q['dur'] = score(f, text)
            for c in sorted(glob.glob(f'{wav}/retake/{k[:-4]}.t*.wav')):          # 받아 온 재생성본 중 더 나은 것을 본 파일로
                s, d = score(c, text)
                if s > q['sim']:
                    shutil.copy(c, f); q['sim'], q['dur'] = s, d
                os.remove(c)
            q['ok'] = q['sim'] >= PASS
            if not q['ok']:
                bad += 1
                if q['tries'] < 3:
                    q['tries'] += 1
                    jobs.append({**L.job(ep, name, voice, emo, text, out=f"{L.OUT}/retake/{k[:-4]}.t{q['tries']}.wav"), 'seed': 42 + 97 * q['tries']})
    json.dump(Q, open(qf, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    if jobs_out:
        json.dump(jobs, open(jobs_out, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print(f'QA 편 {len(eps)} 나쁨 {bad} 재생성 {len(jobs)}')


if __name__ == '__main__':
    main()
