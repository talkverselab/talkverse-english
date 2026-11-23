#!/usr/bin/env python3
"""영어 음성 시험: 한 편을 MOSS·VoxCPM2 두 판으로 만들어 R2 에만 올린다(D1 은 사용자가 고른 뒤). 품질 기준 = 일본어앱 docs/DIALOGUE_AUDIO.md §5.
  TTS_OUT=en2 <venv>/bin/python tools/tts/trial.py <작업폴더> [편id=r1_survival_s1]   venv = mlx-whisper 가 있는 파이썬. uk 의 "지금 시작" 뒤에 돌린다.
순서: 참고 음성(잡음 바닥 -60dB 넘으면 잡음을 줄여 되돌림) → 문장 → 받아쓰기 검사·재생성(세 번) → 묶어서 R2."""
import glob, json, os, subprocess, sys, time
import ttslib as L
import qa
PC = 'Administrator@100.127.143.37'; HERE = os.path.dirname(os.path.abspath(__file__))
work = sys.argv[1]; EP = sys.argv[2] if len(sys.argv) > 2 else 'r1_survival_s1'
job = f'{work}/job'; wav = f'{work}/wav'; refd = f'{work}/ref'
for d in (job, f'{wav}/retake', refd):
    os.makedirs(d, exist_ok=True)
log = lambda *a: print(time.strftime('%H:%M:%S'), *a, flush=True)


def sh(*a, check=True, **k):
    return subprocess.run(a, check=check, capture_output=True, text=True, **k)


def state():
    return sh('ssh', PC, "(Get-ScheduledTask -TaskName 'TTS job 2060').State", check=False).stdout


def pc_run():
    while 'Ready' not in state():
        time.sleep(30)
    for n in ('vox_jobs.json', 'moss_jobs.json'):
        if os.path.exists(f'{job}/{n}'):
            sh('scp', '-q', f'{job}/{n}', f'{PC}:D:/tts_test/job/')
        else:
            sh('ssh', PC, f'Remove-Item D:\\tts_test\\job\\{n} -ErrorAction SilentlyContinue')
    sh('ssh', PC, "Start-ScheduledTask -TaskName 'TTS job 2060'")
    time.sleep(20)
    while 'Ready' not in state():
        time.sleep(15)


def fetch(path, dst):
    os.makedirs(dst, exist_ok=True)
    sh('scp', '-q', '-r', f'{PC}:D:/tts_test/job/out/{L.OUT}/{path}', dst + '/', check=False)


def clear():
    for n in ('vox_jobs.json', 'moss_jobs.json'):
        if os.path.exists(f'{job}/{n}'):
            os.remove(f'{job}/{n}')


clear()
log(sh(sys.executable, f'{HERE}/make_jobs.py', job, '--refs', EP).stdout.strip())
pc_run()
sh('scp', '-q', f'{PC}:D:/tts_test/job/out/{L.REF}/*.wav', refd + '/', check=False)
for f in sorted(glob.glob(f'{refd}/*.wav')):
    n = qa.floor(f)
    if n > -60:
        o = f + '.dn.wav'
        sh('ffmpeg', '-y', '-v', 'error', '-i', f, '-af', 'afftdn=nf=-40,highpass=f=60', o)
        os.replace(o, f)
        sh('scp', '-q', f, f'{PC}:D:/tts_test/job/out/{L.REF}/')
        log('잡음 줄임', os.path.basename(f), round(n, 1), '→', round(qa.floor(f), 1))
log('참고 음성 끝', len(glob.glob(f'{refd}/*.wav')))
clear()
eps = [EP, EP + L.VOX]
log(sh(sys.executable, f'{HERE}/make_jobs.py', job, *eps).stdout.strip())
pc_run(); log('생성 끝')
for e in eps:
    fetch(e, wav)
for rnd in range(3):
    jobs = []
    for e in eps:
        q = f'{job}/qa_{e}.json'
        try:
            r = subprocess.run([sys.executable, f'{HERE}/qa.py', wav, e, '--jobs', q], capture_output=True, text=True, timeout=600)
            log(e, r.stdout.strip() or r.stderr.strip()[-300:])
        except subprocess.TimeoutExpired:
            log('TIMEOUT', e); continue
        if os.path.exists(q):
            jobs += json.load(open(q, encoding='utf-8')); os.remove(q)
    if not jobs:
        break
    clear()
    for n, x in (('moss_jobs.json', [j for j in jobs if 'language' in j]), ('vox_jobs.json', [j for j in jobs if 'language' not in j])):
        if x:
            json.dump(x, open(f'{job}/{n}', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    pc_run()
    for e in eps:
        fetch(f'retake/{e}', f'{wav}/retake')
log('PC 끝')
for e in eps:
    r = sh(sys.executable, f'{HERE}/pack.py', wav, e, '--upload', '--no-db', check=False)
    log(r.stdout.strip() or (r.stderr or '')[-300:])
log('끝')
