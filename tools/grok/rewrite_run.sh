#!/bin/zsh
# 회화 Grok 재작성 회차(PC 크롬 9262 = 작업 스케줄러 Grok-Chrome-en-9262, 전문가 모드). 방 하나에 N편 — 첫 메시지만 규칙 첨부, 이후 파일 이름 한 줄.
#   zsh tools/grok/rewrite_run.sh <규칙.md> <편id>...   결과 data/review/grok/out/<id>.md
#   M6 터널: ssh -fN -L 9262:127.0.0.1:9262 pc
cd "$(dirname "$0")/../.."
export GROK_CDP_PORT=9262
rules=$1; shift
chat=""
for id in "$@"; do
  out=data/review/grok/out/$id.md
  [[ -s $out ]] && { echo "skip $id"; continue; }
  if [[ -z $chat ]]; then
    first=${TMPDIR:-/tmp}/grok_en_first.txt
    print -r -- "첨부한 $(basename $rules) 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $id.txt" > $first
    r=$(/usr/bin/python3 tools/grok/grok_text.py $first $out $rules data/review/grok/src/$id.txt 2>&1)
  else
    r=$(/usr/bin/python3 tools/grok/grok_text.py -m "$id.txt" $out data/review/grok/src/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E '저장|LIMIT|전문가|중지' | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 20
done
echo "끝 $chat"
