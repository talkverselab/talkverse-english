# -*- coding: utf-8 -*-
"""[영어앱 PC 판 — ~/Hanja/tools/grok_req.py 를 복사, 첨부를 PC D:\\grok_att\\en\\ 로 보내도록 고침. 크롬 = PC 9262(작업 Grok-Chrome-en-9262), M6 터널 ssh -fN -L 9262:127.0.0.1:9262 pc]
Grok 요청 한 건: 새 챗(또는 기존 챗) → 첨부 → 프롬프트 전송 → 응답 대기 → 생성 그림·글 저장.
2026-11-09 다시 만듦(예전 scratchpad 판이 세션 재시작으로 사라짐 — 이제 ~/Hanja/tools 에 둔다).

  GROK_CDP_PORT=9333 /usr/bin/python3 tools/grok_req.py <요청문.md> <결과.jpg> [첨부 ...] [--chat <챗id>] [--wait 180]
- 사용자 지시 2026-11-10 "그록 답은 3분만, 넘어가면 대화방 중지(토큰 낭비)": 기본 대기 180초, 넘으면 중지 단추(중지·Stop)를 누르고(없으면 Escape) 종료 코드 4.
- 2026-11-09 Grok 화면 변경: 보내기 단추 aria-label '제출' → '보내기'.
- M6 에서 쓸 때: ssh -fN -L 9333:127.0.0.1:9222 macmini4 터널. 첨부는 M4 /tmp/grok_att/ 로 scp 한 뒤 그 경로로 붙인다
  (Chrome 이 M4 에서 돌기 때문에 DOM.setFileInputFiles 는 M4 경로를 받는다).
- 결과: <결과.jpg>(첫 생성 그림) + <결과 이름>_img.md(Grok 마지막 응답 글). 한도 문구면 종료 코드 3.
- 끝나면 연 탭을 닫는다(탭이 쌓여 CDP 가 멈춘 일 2026-11-03).
"""
import base64, json, os, subprocess, sys, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import grok_cdp as G

LIMIT = ('한도에 도달', 'limit reached', 'Rate limit')


def new_tab(url):
    req = urllib.request.Request(G.BASE + '/json/new?' + url, method='PUT')
    return json.load(urllib.request.urlopen(req))


def close_tab(t):
    try:
        urllib.request.urlopen(G.BASE + '/json/close/' + t['id'])
    except Exception:
        pass


def download(src):
    """assets.grok.com 그림: grok.com 에서 fetch 는 CORS 로 빈 값, 새 탭 fetch 도 자주 빈 값 →
    그림 주소를 새 탭으로 열어 그림이 다 뜬 뒤 canvas 로 뽑는다(같은 출처라 막히지 않음, 2026-11-09 12자 확인)."""
    t = new_tab(src)
    try:
        c = G.CDP(t)
        for _ in range(20):
            time.sleep(1)
            if c.ev("document.images.length&&document.images[0].complete&&document.images[0].naturalWidth>0"):
                break
        b64 = c.ev("(()=>{const i=document.images[0];if(!i)return '';const cv=document.createElement('canvas');cv.width=i.naturalWidth;cv.height=i.naturalHeight;cv.getContext('2d').drawImage(i,0,0);try{return cv.toDataURL('image/jpeg',0.95).split(',')[1]}catch(e){return ''}})()")
        return base64.b64decode(b64 or '')
    finally:
        close_tab(t)


def main():
    a = sys.argv[1:]
    opt = {}
    for k in ('--chat', '--wait'):
        if k in a:
            i = a.index(k); opt[k] = a[i + 1]; del a[i:i + 2]
    req, out, atts = a[0], a[1], a[2:]
    wait = int(opt.get('--wait', 180))  # 사용자 지시 2026-11-10: 3분
    # 첨부 → M4 /tmp/grok_att
    remote = []
    if atts:
        subprocess.run(['ssh', 'pc', 'cmd /c if not exist D:\\grok_att\\en mkdir D:\\grok_att\\en'], check=False, capture_output=True)
        for p in atts:
            subprocess.run(['scp', '-q', p, 'pc:D:/grok_att/en/'], check=True)
            remote.append('D:\\grok_att\\en\\' + os.path.basename(p))
    url = 'https://grok.com/c/' + opt['--chat'] if '--chat' in opt else 'https://grok.com/'
    t = new_tab(url)
    try:
        c = G.CDP(t)
        c.call('Page.bringToFront')
        for _ in range(30):
            if c.ev("!!(%s)" % G.FIND):
                break
            time.sleep(1)
        if remote:
            doc = c.call('DOM.getDocument', depth=-1, pierce=True)
            node = c.call('DOM.querySelector', nodeId=doc['root']['nodeId'], selector='input[type=file]')
            if not node.get('nodeId'):
                raise SystemExit('파일 입력 없음')
            c.call('DOM.setFileInputFiles', nodeId=node['nodeId'], files=remote)
            time.sleep(4 + 2 * len(remote))
            print('첨부', len(remote))
        time.sleep(4)  # 기존 챗이면 이전 대화가 다 그려질 때까지
        GEN = "[...document.querySelectorAll('img')].filter(i=>i.src.includes('/generated/')).map(i=>i.src)"
        gen0 = set(c.ev(GEN) or [])  # 이 챗에 이미 있던 생성 그림(같은 챗에 이어 보낼 때 옛 그림을 잡지 않게)
        lim0 = c.ev("(document.body.innerText.match(/한도에 도달|limit reached/g)||[]).length")
        text = open(req, encoding='utf-8').read().strip()
        c.ev("(()=>{const e=%s;e.focus();return 1})()" % G.FIND)
        c.call('Input.insertText', text=text)
        time.sleep(1)
        for typ in ('keyDown', 'keyUp'):
            c.call('Input.dispatchKeyEvent', type=typ, key='Enter', code='Enter', windowsVirtualKeyCode=13, nativeVirtualKeyCode=13)
        time.sleep(3)
        left = c.ev("(()=>{const e=%s;return e?(e.value||e.innerText||'').trim().length:-1})()" % G.FIND)
        if left and left > 0:
            c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(x=>/제출|보내기|Submit|Send/.test(x.getAttribute('aria-label')||''));if(b){b.click();return 1}return 0})()")
            time.sleep(3)
        print('전송', c.ev('location.href'))
        # 대기: 생성 그림(큰 img)이 새로 생기고 응답이 멈추면 끝. 한도 문구면 3.
        t0 = time.time(); src = None; last = ''
        while time.time() - t0 < wait:
            time.sleep(10)
            body = c.ev("document.body.innerText.slice(-600)")
            if c.ev("(document.body.innerText.match(/한도에 도달|limit reached/g)||[]).length") > lim0:
                print('LIMIT'); sys.exit(3)
            # 새로 생긴 생성 그림만(첨부 미리보기도 assets.grok.com 이라 '/generated/' 로 가르고, 이전 그림은 gen0 로 뺀다)
            new = [x for x in (c.ev(GEN) or []) if x not in gen0]
            src = new[-1] if new else None
            busy = c.ev("/생성 중|생각 중|Generating|Thinking|이미지 생성/.test(document.body.innerText.slice(-400))")
            if src and not busy and body == last:
                break
            last = body
        if not src:
            if time.time() - t0 >= wait:  # 3분 초과 → 그 대화의 생성 중지(사용자 지시 2026-11-10)
                how = c.ev("(()=>{const b=[...document.querySelectorAll('button')].find(e=>/중지|stop/i.test((e.getAttribute('aria-label')||'')+' '+e.innerText));if(b){b.click();return b.getAttribute('aria-label')||b.innerText}return ''})()")
                if not how:
                    for typ in ('keyDown', 'keyUp'):
                        c.call('Input.dispatchKeyEvent', type=typ, key='Escape', code='Escape', windowsVirtualKeyCode=27, nativeVirtualKeyCode=27)
                print('TIMEOUT 중지', how or 'Escape', c.ev('location.href')); sys.exit(4)
            print('그림 없음', c.ev('location.href')); sys.exit(2)
        raw = download(src)
        if not raw:
            print('내려받기 실패', src); sys.exit(2)
        tmp = out + '.dl'
        open(tmp, 'wb').write(raw)
        subprocess.run(['sips', '-s', 'format', 'jpeg', tmp, '--out', out], check=True, capture_output=True)
        os.remove(tmp)
        md = os.path.splitext(out)[0] + '_img.md'
        reply = c.ev("(()=>{const m=[...document.querySelectorAll('[class*=message], [data-testid*=message]')];return m.length?m[m.length-1].innerText:document.body.innerText.slice(-1500)})()")
        open(md, 'w', encoding='utf-8').write('# Grok 응답 (%s)\n\n챗: %s\n요청문: %s\n\n%s\n' % (time.strftime('%Y-%m-%d %H:%M'), c.ev('location.href'), req, reply))
        print('저장', out, len(raw), 'bytes ·', md)
    finally:
        close_tab(t)


if __name__ == '__main__':
    main()
