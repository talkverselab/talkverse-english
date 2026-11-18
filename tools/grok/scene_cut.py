#!/usr/bin/env python3
"""회화 장면 컷 1장(편의 대표 장면 = 컷 1)을 Grok(PC 크롬 9262, 「빠른」)에 요청해 data/review/scenes/<편id>_1.jpg 로 받는다(2026-11-18, 심사 준비 = 장면 컷 10장).
  /usr/bin/python3 tools/grok/scene_cut.py <편id> ...     (이미 있으면 건너뜀) → 그다음 ~/.venvs/img/bin/python tools/scene_upload.py
앱은 컷이 하나뿐이면 모든 턴에 그 컷을 보인다(lib/services/art_service.dart 가장 가까운 컷). 인물 = data/review/art/chars_en_v1.jpg(캐릭터 시트).
"""
import glob, json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'data/review/scenes')
SHEET = os.path.join(ROOT, 'data/review/art/chars_en_v1.jpg')
DESC = {'Maya': '시트의 Maya(곱슬 흑발 반묶음·따뜻한 갈색 피부·주황 오버사이즈 스웨트셔츠)',
        'Emma': '시트의 Emma(낮게 묶은 금발 긴 머리·주근깨·연두색 카디건)',
        'Jake': '시트의 Jake(짧은 갈색 곱슬·옅은 수염·뒤로 쓴 빨간 캡·회색 후드티)',
        'Daniel': '시트의 Daniel(가장 키 큰 흑발 투블럭 동아시아계·카멜 롱코트)'}
LEARNER = '시트의 학습자(남)(인디고 후드티·베이지 팬츠·갈색 백팩)'


def ep_of(eid):
    p = glob.glob(os.path.join(ROOT, f'assets/data/dialogues/R*/*/{eid}.json'))
    return json.load(open(p[0], encoding='utf-8'))


def prompt(ep):
    others = []
    for k, v in ep['speakers'].items():
        if k == 'A':
            continue
        others.append(f'{k} = ' + DESC.get(v, f'{v}(시트에 없는 단역, 같은 점토 화풍, 유니폼·명찰 글자 없음)'))
    tw = ep.get('twist', '')
    lines = ' / '.join(f"{t['speaker']}: {t['ko']}" for t in ep['turns'][:6])
    chat = '**채팅 장면**: 두 사람은 같은 곳에 있지 않다 — 화면을 좌우로 나눠 각자 자기 방에서 휴대폰을 보는 모습.\n' if ep.get('kind') == 'chat' else ''
    return f"""[EN-SCENE {ep['id']}] 첨부한 캐릭터 시트(영어앱 고정 인물, 점토·펠트 인형)의 인물로 이 회화의 대표 장면 **1장**을 그려 주세요.
장면: {ep['scene']} (장소: {ep.get('where', '')})
인물: A = {LEARNER}, {', '.join(others)}. 시트의 얼굴·머리·옷을 그대로.
화풍: 점토·펠트 인형, 파스텔·따뜻한 조명, 뉴욕 브루클린 일상 배경. **그림 안에 글자·말풍선·간판 글씨·상표 없음**. **가로 3:2**.
{chat}표정과 몸짓은 크게 — 반전({tw}번 턴) 직전의 웃기거나 설레는 순간으로.
대화 흐름(그리지 말고 상황·표정만): {lines}
그림 1장만, 설명은 "완료" 한 줄."""


def main():
    os.makedirs(OUT, exist_ok=True)
    env = dict(os.environ, GROK_CDP_PORT='9262')
    for eid in sys.argv[1:]:
        out = os.path.join(OUT, f'{eid}_1.jpg')
        if os.path.exists(out):
            print('skip', eid); continue
        req = os.path.join(OUT, f'{eid}_prompt.md')
        open(req, 'w', encoding='utf-8').write(prompt(ep_of(eid)))
        r = subprocess.run(['/usr/bin/python3', os.path.join(ROOT, 'tools/grok/grok_img.py'), req, out, SHEET], env=env, capture_output=True, text=True)
        print(eid, r.returncode, (r.stdout.strip().splitlines() or [''])[-1][:120], flush=True)
        if r.returncode == 3:
            sys.exit('한도 — 멈춤')


if __name__ == '__main__':
    main()
