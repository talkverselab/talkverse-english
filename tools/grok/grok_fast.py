#!/usr/bin/python3
# [영어앱 사본 — uk tools/grok_mode.py 를 「빠른」으로 바꾼 판(사용자 지시 2026-11-18 Grok 빠른 모드)]
"""Grok 탭의 모델 모드를 '전문가'로 맞춘다(2026-11-09 사용자 "전체세션 그록 전문가 모드인지 확인하고 아니면 전문가모드로").
사용: /usr/bin/python3 ~/talkverse-uk/tools/grok_mode.py <포트> [--check]
  그 크롬의 grok.com 탭(첫 화면·채팅 탭 — 프로젝트 목록 화면엔 입력창이 없어 '모델 단추 없음')마다 입력창 옆 '모델:' 단추를 보고, 전문가가 아니면 단추 → '전문가' 를 눌러 바꾼다. --check 는 보기만.
"""
import json, sys, time, urllib.request
import websocket

_id = 0
def call(ws, method, **p):
    global _id
    _id += 1
    ws.send(json.dumps({'id': _id, 'method': method, 'params': p}))
    while True:
        m = json.loads(ws.recv())
        if m.get('id') == _id:
            return m.get('result', {})

def ev(ws, js):
    return call(ws, 'Runtime.evaluate', expression=js, returnByValue=True).get('result', {}).get('value')

MODE = "(()=>{const b=[...document.querySelectorAll('button')].find(x=>(x.getAttribute('aria-label')||'').startsWith('모델:')||(x.getAttribute('aria-label')||'').startsWith('Model:'));return b?(b.getAttribute('aria-label')||''):''})()"
OPEN = "(()=>{const b=[...document.querySelectorAll('button')].find(x=>(x.getAttribute('aria-label')||'').match(/^(모델|Model):/));if(!b)return 0;['pointerdown','pointerup'].forEach(t=>b.dispatchEvent(new PointerEvent(t,{bubbles:true})));b.click();return 1})()"
PICK = "(()=>{const it=[...document.querySelectorAll('[role=menuitem],[role=option],[role=menuitemradio],[role=menuitemcheckbox],button,div')].find(x=>/^(빠른|Fast)(\\s|$)/.test((x.innerText||'').trim())&&x.offsetParent&&!(x.getAttribute('aria-label')||'').match(/^(모델|Model):/));if(!it)return 0;['pointerdown','pointerup'].forEach(t=>it.dispatchEvent(new PointerEvent(t,{bubbles:true})));it.click();return 1})()"

def main():
    port = sys.argv[1]; check = '--check' in sys.argv
    for t in json.load(urllib.request.urlopen(f'http://127.0.0.1:{port}/json/list', timeout=5)):
        if t.get('type') != 'page' or 'grok.com' not in t.get('url', ''):
            continue
        ws = websocket.create_connection(t['webSocketDebuggerUrl'], timeout=20, suppress_origin=True)
        cur = ev(ws, MODE) or '(모델 단추 없음)'
        tail = t['url'][-24:]
        if '빠른' in cur or 'Fast' in cur or check:
            print(f'{port} …{tail}: {cur}'); ws.close(); continue
        ev(ws, OPEN); time.sleep(1); ok = ev(ws, PICK); time.sleep(1)
        print(f'{port} …{tail}: {cur} → {ev(ws, MODE) if ok else "전문가 항목을 못 찾음 — 화면에서 직접"}')
        ws.close()

if __name__ == '__main__':
    main()
