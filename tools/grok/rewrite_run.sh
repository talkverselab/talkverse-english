#!/bin/zsh
# 회화 Grok 재작성 회차(PC 크롬 9262 = 작업 스케줄러 Grok-Chrome-en-9262, 빠른 모드 — 사용자 지시 2026-11-18).
# 원칙(사용자 2026-11-18): Claude 는 초안까지, 대사는 Grok 이 쓰고 받은 그대로 붙인다. 시작 전 uk 에 순서 받기.
#   zsh tools/grok/rewrite_run.sh <규칙.md> <편id>...   결과 data/review/grok/out/<id>.md
#   방 하나에 PER(25)편까지 — 첫 메시지만 규칙 첨부, 이후 파일 이름 한 줄. 3분 TIMEOUT(rc 4)이면 다시 보내지 않고 방에서 답을 먼저 읽는다(uk 공지).
#   M6 터널: ssh -fN -L 9262:127.0.0.1:9262 pc
cd "$(dirname "$0")/../.."
export GROK_CDP_PORT=9262
PER=${PER:-25}
rules=$1; shift
chat=""; k=0
for id in "$@"; do
  out=data/review/grok/out/$id.md
  [[ -s $out ]] && { echo "skip $id"; continue; }
  (( k >= PER )) && { chat=""; k=0; }
  if [[ -z $chat ]]; then
    first=${TMPDIR:-/tmp}/grok_en_first.txt
    print -r -- "첨부한 $(basename $rules) 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $id.txt" > $first
    r=$(/usr/bin/python3 tools/grok/grok_text.py $first $out $rules data/review/grok/src/$id.txt 2>&1)
  else
    r=$(/usr/bin/python3 tools/grok/grok_text.py -m "$id.txt" $out data/review/grok/src/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?
  c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  if [[ $rc -eq 4 && -n $chat ]]; then  # TIMEOUT 오판 대비: 30초 뒤 방에서 마지막 답만 읽기
    sleep 30; /usr/bin/python3 tools/grok/grok_text.py --fetch $out --chat "$chat" >/dev/null 2>&1
    grep -q "=== $id" $out 2>/dev/null && rc=0 || rm -f $out
  fi
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E '저장|LIMIT|빠른|중지' | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  (( k++ ))
  sleep 20
done
echo "끝 $chat"
