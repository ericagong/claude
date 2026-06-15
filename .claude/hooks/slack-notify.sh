#!/usr/bin/env bash
# Claude Code → Slack 알림 훅
# 권한/입력 대기(Notification) 및 응답 종료(Stop) 시 모바일 슬랙으로 알림 전송.
# 실패해도 Claude를 막지 않도록 항상 exit 0.

WEBHOOK_FILE="$HOME/.claude/slack-webhook-url"
# 웹훅 key가 없거나 비어 있으면, 안내 메시지를 사용자에게 보여주고 종료(비차단)
if [ ! -f "$WEBHOOK_FILE" ] || [ -z "$(tr -d '[:space:]' < "$WEBHOOK_FILE" 2>/dev/null)" ]; then
  echo "🔑 Slack 웹훅 key가 없습니다. key를 .env 파일($WEBHOOK_FILE)에 저장해주셔야 합니다." >&2
  exit 1
fi
WEBHOOK_URL="$(tr -d '[:space:]' < "$WEBHOOK_FILE")"

input="$(cat)"
event="$(printf '%s' "$input" | jq -r '.hook_event_name // empty')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
project="$(basename "${cwd:-unknown}")"

case "$event" in
  Notification)
    msg="$(printf '%s' "$input" | jq -r '.message // "입력 대기 중"')"
    text=":bell: *[$project]* 권한/입력 대기: $msg"
    ;;
  Stop)
    text=":white_check_mark: *[$project]* 작업 완료 (응답 종료)"
    ;;
  *)
    exit 0
    ;;
esac

payload="$(jq -n --arg t "$text" '{text: $t}')"
curl -fsS -X POST -H 'Content-type: application/json' --data "$payload" "$WEBHOOK_URL" >/dev/null 2>&1 || true
exit 0
