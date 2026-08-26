#!/usr/bin/env bash

set -euo pipefail

readonly MAX_MESSAGE_BYTES=8192

die() {
  printf 'herdr-worker: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_herdr() {
  [[ ${HERDR_ENV:-} == 1 ]] || die "not running inside Herdr (HERDR_ENV=1 is required)"
  [[ -n ${HERDR_WORKSPACE_ID:-} ]] || die "HERDR_WORKSPACE_ID is missing"
  [[ -n ${HERDR_PANE_ID:-} ]] || die "HERDR_PANE_ID is missing"
  require_command herdr
  require_command jq
}

usage() {
  cat >&2 <<'EOF'
usage:
  herdr-worker.sh start [--label LABEL] [--cwd PATH] [--model MODEL] [--thinking LEVEL]
  herdr-worker.sh send --pane PANE_ID --message TEXT
  herdr-worker.sh status --pane PANE_ID
EOF
  exit 2
}

start_worker() {
  local label=worker
  local cwd=$PWD
  local model=luna
  local thinking=max

  while (($#)); do
    case $1 in
      --label) (($# >= 2)) || usage; label=$2; shift 2 ;;
      --cwd) (($# >= 2)) || usage; cwd=$2; shift 2 ;;
      --model) (($# >= 2)) || usage; model=$2; shift 2 ;;
      --thinking) (($# >= 2)) || usage; thinking=$2; shift 2 ;;
      *) usage ;;
    esac
  done

  [[ -d $cwd ]] || die "worker cwd is not a directory: $cwd"
  case $model in sol|terra|luna) ;; *) die "unsupported Tact model: $model" ;; esac
  case $thinking in low|medium|high|xhigh|max) ;; *) die "unsupported thinking level: $thinking" ;; esac

  require_command tact

  local created worker_pane worker_tab tact_bin tact_command status agent_state deadline
  created=$(herdr tab create \
    --workspace "$HERDR_WORKSPACE_ID" \
    --cwd "$cwd" \
    --label "$label" \
    --no-focus)
  worker_pane=$(jq -er '.result.root_pane.pane_id' <<<"$created")
  worker_tab=$(jq -er '.result.tab.tab_id' <<<"$created")
  tact_bin=$(command -v tact)
  printf -v tact_command '%q --model %q --thinking %q --workspace %q' \
    "$tact_bin" "$model" "$thinking" "$cwd"
  herdr pane run "$worker_pane" "$tact_command"

  deadline=$((SECONDS + 30))
  status=
  agent_state=
  while ((SECONDS < deadline)); do
    if status=$(herdr agent get "$worker_pane" 2>/dev/null); then
      agent_state=$(jq -r '.result.agent.agent_status // empty' <<<"$status")
      case $agent_state in
        idle|done) break ;;
      esac
    fi
    sleep 0.5
  done

  if [[ -z $status ]] || [[ $agent_state != "idle" && $agent_state != "done" ]]; then
    die "Tact did not become ready in pane $worker_pane within 30 seconds; tab $worker_tab was preserved for diagnosis"
  fi

  jq -n \
    --arg owner_pane_id "$HERDR_PANE_ID" \
    --arg worker_pane_id "$worker_pane" \
    --arg worker_tab_id "$worker_tab" \
    --arg model "$model" \
    --arg thinking "$thinking" \
    '{owner_pane_id: $owner_pane_id, worker_pane_id: $worker_pane_id, worker_tab_id: $worker_tab_id, model: $model, thinking: $thinking}'
}

send_message() {
  local pane=
  local message=

  while (($#)); do
    case $1 in
      --pane) (($# >= 2)) || usage; pane=$2; shift 2 ;;
      --message) (($# >= 2)) || usage; message=$2; shift 2 ;;
      *) usage ;;
    esac
  done

  [[ -n $pane ]] || usage
  [[ -n $message ]] || usage

  local message_bytes
  message_bytes=$(LC_ALL=C printf '%s' "$message" | wc -c | tr -d '[:space:]')
  ((message_bytes <= MAX_MESSAGE_BYTES)) || die "message is $message_bytes bytes; write long content to a shared file and send its absolute path"

  herdr pane get "$pane" >/dev/null
  herdr pane send-text "$pane" "$message"
  herdr pane send-keys "$pane" enter
  jq -n --arg pane_id "$pane" --argjson bytes "$message_bytes" '{pane_id: $pane_id, sent: true, bytes: $bytes}'
}

show_status() {
  local pane=

  while (($#)); do
    case $1 in
      --pane) (($# >= 2)) || usage; pane=$2; shift 2 ;;
      *) usage ;;
    esac
  done

  [[ -n $pane ]] || usage
  herdr agent get "$pane"
}

main() {
  require_herdr
  (($#)) || usage

  local command=$1
  shift
  case $command in
    start) start_worker "$@" ;;
    send) send_message "$@" ;;
    status) show_status "$@" ;;
    *) usage ;;
  esac
}

main "$@"
