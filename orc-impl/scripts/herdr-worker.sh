#!/usr/bin/env bash

set -euo pipefail

readonly MAX_MESSAGE_BYTES=8192
readonly PROMPT_TIMEOUT_MS=10000
readonly START_ATTEMPTS=20
readonly START_RETRY_DELAY_SECONDS=0.5
readonly WORKER_MODEL=gpt-5.6-luna
readonly WORKER_REASONING_EFFORT=max
readonly WORKER_ROLE_ENV=ORC_WORKER_ROLE
readonly IMPLEMENTATION_WORKER_ROLE=implementation-worker
readonly WORKER_DISPLAY_AGENT='Implementation worker'
readonly METADATA_SOURCE=orc-impl
HELPER_TEMP_DIR=

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
  [[ -n ${HERDR_TAB_ID:-} ]] || die "HERDR_TAB_ID is missing"
  [[ -n ${HERDR_PANE_ID:-} ]] || die "HERDR_PANE_ID is missing"
  require_command herdr
  require_command jq
}

cleanup() {
  if [[ -n $HELPER_TEMP_DIR && -d $HELPER_TEMP_DIR ]]; then
    rm -rf -- "$HELPER_TEMP_DIR"
  fi
}

init_temp_dir() {
  HELPER_TEMP_DIR=$(mktemp -d)
  trap cleanup EXIT
}

usage() {
  cat >&2 <<'EOF'
usage:
  herdr-worker.sh start NAME
  herdr-worker.sh resume --pane PANE_ID [--label LABEL]
  herdr-worker.sh send [--wait-ready] --pane PANE_ID --message TEXT
  herdr-worker.sh steer --pane PANE_ID --message TEXT
  herdr-worker.sh status --pane PANE_ID
EOF
  exit 2
}

json_error_code() {
  jq -r '.error.code // empty' 2>/dev/null <<<"$1" || true
}

json_error_message() {
  jq -r '.error.message // empty' 2>/dev/null <<<"$1" || true
}

emit_start_failure() {
  local worker_pane=$1
  local worker_tab=$2
  local recoverable=$3
  local error=$4
  local message=$5

  jq -n \
    --arg owner_pane_id "$HERDR_PANE_ID" \
    --arg worker_pane_id "$worker_pane" \
    --arg worker_tab_id "$worker_tab" \
    --arg error "$error" \
    --arg message "$message" \
    --argjson recoverable "$recoverable" \
    '{started: false, recoverable: $recoverable, owner_pane_id: $owner_pane_id, worker_pane_id: $worker_pane_id, worker_tab_id: $worker_tab_id, error: $error, message: $message}'
}

emit_prompt_failure() {
  local pane=$1
  local error=$2
  local message=$3
  local status=${4:-}

  jq -n \
    --arg pane_id "$pane" \
    --arg error "$error" \
    --arg message "$message" \
    --arg status "$status" \
    '{accepted: false, pane_id: $pane_id, error: $error, message: $message} + if $status == "" then {} else {status: $status} end'
}

guard_incompatible_entrypoint() {
  local command=$1

  [[ ${ORC_WORKER_ROLE:-} == "$IMPLEMENTATION_WORKER_ROLE" ]] || return 0
  die "role guard: Implementation worker cannot invoke $command to start or recover another worker; continue implementing the assigned spec and use the Completion callback to coordinate with the Owner"
}

resolve_default_branch() {
  local cwd=$1
  local default_ref

  if default_ref=$(git -C "$cwd" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null); then
    printf '%s\n' "${default_ref#origin/}"
    return 0
  fi
  if git -C "$cwd" show-ref --verify --quiet refs/heads/main; then
    printf '%s\n' main
    return 0
  fi
  if git -C "$cwd" show-ref --verify --quiet refs/heads/master; then
    printf '%s\n' master
    return 0
  fi
  die "cannot determine the default branch in $cwd"
}

prepare_worker_branch() {
  local name=$1
  local cwd=$2
  local current_branch default_branch tracked_changes

  git -C "$cwd" check-ref-format --branch "$name" >/dev/null 2>&1 || \
    die "invalid worker or branch name: $name"
  current_branch=$(git -C "$cwd" branch --show-current)
  [[ -n $current_branch ]] || die "detached HEAD is not supported: $cwd"
  tracked_changes=$(git -C "$cwd" status --porcelain --untracked-files=no)
  [[ -z $tracked_changes ]] || die "tracked worktree is not clean: $cwd"
  default_branch=$(resolve_default_branch "$cwd")

  if [[ $current_branch == "$default_branch" ]]; then
    if git -C "$cwd" show-ref --verify --quiet "refs/heads/$name"; then
      die "branch already exists: $name; switch to it before starting the worker"
    fi
    require_command og
    (cd "$cwd" && og pull >&2)
    if git -C "$cwd" show-ref --verify --quiet "refs/remotes/origin/$name"; then
      die "remote branch already exists: $name; switch to it before starting the worker"
    fi
    git -C "$cwd" switch -c "$name" >&2
    return 0
  fi

  [[ $current_branch == "$name" ]] || \
    die "current branch $current_branch does not match worker name $name"
}

launch_worker() {
  local label=$1
  local cwd=$2
  local worker_pane=$3
  local worker_tab=$4
  local attempt output error_file error_output error_code error_message status

  for ((attempt = 1; attempt <= START_ATTEMPTS; attempt++)); do
    error_file=$HELPER_TEMP_DIR/herdr-error.json
    if output=$(herdr agent start "$label" \
      --kind codex \
      --pane "$worker_pane" \
      --timeout 30000 \
      -- -C "$cwd" \
      -m "$WORKER_MODEL" \
      -c "model_reasoning_effort=\"$WORKER_REASONING_EFFORT\"" \
      2>"$error_file"); then
      status=$(jq -er '.result.agent.agent_status' <<<"$output")
      jq -n \
        --arg owner_pane_id "$HERDR_PANE_ID" \
        --arg worker_pane_id "$worker_pane" \
        --arg worker_tab_id "$worker_tab" \
        --arg status "$status" \
        '{started: true, owner_pane_id: $owner_pane_id, worker_pane_id: $worker_pane_id, worker_tab_id: $worker_tab_id, agent: "codex", status: $status}'
      return 0
    fi

    error_output=$(<"$error_file")
    error_code=$(json_error_code "$error_output")
    error_message=$(json_error_message "$error_output")
    [[ -n $error_code ]] || error_code=agent_start_failed
    [[ -n $error_message ]] || error_message=$error_output

    if [[ $error_code != agent_pane_busy ]]; then
      emit_start_failure "$worker_pane" "$worker_tab" false "$error_code" "$error_message"
      return 1
    fi
    if ((attempt < START_ATTEMPTS)); then
      sleep "$START_RETRY_DELAY_SECONDS"
    fi
  done

  emit_start_failure "$worker_pane" "$worker_tab" true agent_pane_busy \
    "agent target pane did not reach an available shell after $START_ATTEMPTS attempts; resume the same pane"
  return 1
}

report_worker_identity() {
  local pane=$1
  local error_file=$HELPER_TEMP_DIR/metadata-error.json
  local error_message

  if ! herdr pane report-metadata "$pane" \
    --source "$METADATA_SOURCE" \
    --display-agent "$WORKER_DISPLAY_AGENT" \
    >/dev/null 2>"$error_file"; then
    error_message=$(<"$error_file")
    [[ -n $error_message ]] || error_message=display_metadata_unavailable
    printf 'herdr-worker: unable to report Implementation worker identity: %s; continuing\n' \
      "$error_message" >&2
  fi
}

start_worker() {
  (($# == 1)) || usage
  local name=$1
  local cwd=$PWD

  [[ -d $cwd ]] || die "worker cwd is not a directory: $cwd"
  require_command git
  require_command codex
  prepare_worker_branch "$name" "$cwd"

  local created worker_pane worker_tab error_file error_output error_code error_message
  error_file=$HELPER_TEMP_DIR/herdr-error.json
  if ! created=$(herdr tab create \
    --workspace "$HERDR_WORKSPACE_ID" \
    --cwd "$cwd" \
    --label "$name" \
    --env "$WORKER_ROLE_ENV=$IMPLEMENTATION_WORKER_ROLE" \
    --no-focus 2>"$error_file"); then
    error_output=$(<"$error_file")
    error_code=$(json_error_code "$error_output")
    error_message=$(json_error_message "$error_output")
    [[ -n $error_code ]] || error_code=tab_create_failed
    [[ -n $error_message ]] || error_message=$error_output
    emit_start_failure "" "" false "$error_code" "$error_message"
    return 1
  fi
  if ! worker_pane=$(jq -er '.result.root_pane.pane_id' <<<"$created"); then
    emit_start_failure "" "" false invalid_herdr_response \
      "tab create response did not include a worker pane ID"
    return 1
  fi
  if ! worker_tab=$(jq -er '.result.tab.tab_id' <<<"$created"); then
    emit_start_failure "$worker_pane" "" true invalid_herdr_response \
      "tab create response did not include a worker tab ID"
    return 1
  fi
  report_worker_identity "$worker_pane"
  launch_worker "$name" "$cwd" "$worker_pane" "$worker_tab"
}

resume_worker() {
  local pane=
  local label=worker

  while (($#)); do
    case $1 in
      --pane) (($# >= 2)) || usage; pane=$2; shift 2 ;;
      --label) (($# >= 2)) || usage; label=$2; shift 2 ;;
      *) usage ;;
    esac
  done

  [[ -n $pane ]] || usage
  require_command codex

  local pane_info worker_tab cwd agent_info status agent_kind launch_pending interactive_ready
  local error_file error_output error_code error_message
  error_file=$HELPER_TEMP_DIR/herdr-error.json
  if ! pane_info=$(herdr pane get "$pane" 2>"$error_file"); then
    error_output=$(<"$error_file")
    error_code=$(json_error_code "$error_output")
    error_message=$(json_error_message "$error_output")
    [[ -n $error_code ]] || error_code=pane_get_failed
    [[ -n $error_message ]] || error_message=$error_output
    emit_start_failure "$pane" "" false "$error_code" "$error_message"
    return 1
  fi
  if ! worker_tab=$(jq -er '.result.pane.tab_id' <<<"$pane_info"); then
    emit_start_failure "$pane" "" false invalid_herdr_response \
      "pane response did not include a worker tab ID"
    return 1
  fi
  if ! cwd=$(jq -er '.result.pane.cwd // .result.pane.foreground_cwd' <<<"$pane_info"); then
    emit_start_failure "$pane" "$worker_tab" true pane_cwd_unavailable \
      "pane working directory is not available yet; retry resume on the same pane"
    return 1
  fi

  if agent_info=$(herdr agent get "$pane" 2>"$error_file"); then
    agent_kind=$(jq -r '.result.agent.agent // empty' <<<"$agent_info")
    status=$(jq -er '.result.agent.agent_status' <<<"$agent_info")
    if [[ $agent_kind == codex ]]; then
      launch_pending=$(jq -r '.result.agent.launch_pending // false' <<<"$agent_info")
      interactive_ready=$(jq -r '.result.agent.interactive_ready // true' <<<"$agent_info")
      if [[ $launch_pending == true || $interactive_ready == false ]]; then
        if ! agent_info=$(herdr agent wait "$pane" \
          --until idle \
          --until 'done' \
          --timeout 10000 2>"$error_file"); then
          error_output=$(<"$error_file")
          error_code=$(json_error_code "$error_output")
          error_message=$(json_error_message "$error_output")
          [[ -n $error_code ]] || error_code=agent_not_ready
          [[ -n $error_message ]] || error_message=$error_output
          emit_start_failure "$pane" "$worker_tab" true "$error_code" "$error_message"
          return 1
        fi
        status=$(jq -er '.result.agent.agent_status' <<<"$agent_info")
        interactive_ready=$(jq -r '.result.agent.interactive_ready // false' <<<"$agent_info")
        if [[ $interactive_ready != true ]]; then
          emit_start_failure "$pane" "$worker_tab" true agent_not_ready \
            "Codex reached $status but is not ready for interactive prompts"
          return 1
        fi
      fi
      jq -n \
        --arg owner_pane_id "$HERDR_PANE_ID" \
        --arg worker_pane_id "$pane" \
        --arg worker_tab_id "$worker_tab" \
        --arg status "$status" \
        '{started: true, resumed: true, owner_pane_id: $owner_pane_id, worker_pane_id: $worker_pane_id, worker_tab_id: $worker_tab_id, agent: "codex", status: $status}'
      return 0
    fi
    emit_start_failure "$pane" "$worker_tab" false agent_kind_mismatch \
      "pane already hosts agent kind $agent_kind"
    return 1
  fi
  error_output=$(<"$error_file")
  error_code=$(json_error_code "$error_output")
  if [[ $error_code != agent_not_found ]]; then
    error_message=$(json_error_message "$error_output")
    [[ -n $error_code ]] || error_code=agent_get_failed
    [[ -n $error_message ]] || error_message=$error_output
    emit_start_failure "$pane" "$worker_tab" false "$error_code" "$error_message"
    return 1
  fi

  launch_worker "$label" "$cwd" "$pane" "$worker_tab"
}

send_message() {
  local pane=
  local message=
  local wait_ready=false

  while (($#)); do
    case $1 in
      --wait-ready) wait_ready=true; shift ;;
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

  local agent_info initial_status output error_file error_output error_code error_message status
  error_file=$HELPER_TEMP_DIR/herdr-error.json
  while :; do
    if [[ $wait_ready == true ]]; then
      if ! output=$(herdr agent wait "$pane" \
        --until idle \
        --until 'done' 2>"$error_file"); then
        error_output=$(<"$error_file")
        error_code=$(json_error_code "$error_output")
        error_message=$(json_error_message "$error_output")
        [[ -n $error_code ]] || error_code=agent_wait_failed
        [[ -n $error_message ]] || error_message=$error_output
        emit_prompt_failure "$pane" "$error_code" "$error_message"
        return 1
      fi
    fi

    if ! agent_info=$(herdr agent get "$pane" 2>"$error_file"); then
      error_output=$(<"$error_file")
      error_code=$(json_error_code "$error_output")
      error_message=$(json_error_message "$error_output")
      [[ -n $error_code ]] || error_code=agent_get_failed
      [[ -n $error_message ]] || error_message=$error_output
      emit_prompt_failure "$pane" "$error_code" "$error_message"
      return 1
    fi
    initial_status=$(jq -er '.result.agent.agent_status' <<<"$agent_info")
    case $initial_status in
      idle|done) break ;;
      *)
        if [[ $wait_ready == true ]]; then
          continue
        fi
        emit_prompt_failure "$pane" agent_not_idle \
          "agent must be idle or done before a prompt can be accepted reliably" "$initial_status"
        return 1
        ;;
    esac
  done

  if ! output=$(herdr agent prompt "$pane" "$message" \
    --wait \
    --until working \
    --timeout "$PROMPT_TIMEOUT_MS" 2>"$error_file"); then
    error_output=$(<"$error_file")
    error_code=$(json_error_code "$error_output")
    error_message=$(json_error_message "$error_output")
    [[ -n $error_code ]] || error_code=agent_prompt_failed
    [[ -n $error_message ]] || error_message=$error_output
    emit_prompt_failure "$pane" "$error_code" "$error_message" "$initial_status"
    return 1
  fi

  status=$(jq -er '.result.agent.agent_status' <<<"$output")
  if [[ $status != working ]]; then
    emit_prompt_failure "$pane" agent_prompt_not_working \
      "agent prompt returned without the required working status" "$status"
    return 1
  fi
  jq -n \
    --arg pane_id "$pane" \
    --arg initial_status "$initial_status" \
    --arg status "$status" \
    --argjson waited_for_ready "$wait_ready" \
    --argjson bytes "$message_bytes" \
    '{accepted: true, pane_id: $pane_id, initial_status: $initial_status, status: $status, waited_for_ready: $waited_for_ready, bytes: $bytes}'
}

steer_message() {
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
  ((message_bytes <= MAX_MESSAGE_BYTES)) || die "message is $message_bytes bytes; write long content to a shared file and steer with its absolute path"

  local agent_info initial_status output error_file error_output error_code error_message status
  error_file=$HELPER_TEMP_DIR/herdr-error.json
  if ! agent_info=$(herdr agent get "$pane" 2>"$error_file"); then
    error_output=$(<"$error_file")
    error_code=$(json_error_code "$error_output")
    error_message=$(json_error_message "$error_output")
    [[ -n $error_code ]] || error_code=agent_get_failed
    [[ -n $error_message ]] || error_message=$error_output
    emit_prompt_failure "$pane" "$error_code" "$error_message"
    return 1
  fi
  initial_status=$(jq -er '.result.agent.agent_status' <<<"$agent_info")
  if [[ $initial_status != working ]]; then
    emit_prompt_failure "$pane" agent_not_working \
      "agent must be working before its active turn can be steered" "$initial_status"
    return 1
  fi

  if ! output=$(herdr agent prompt "$pane" "$message" 2>"$error_file"); then
    error_output=$(<"$error_file")
    error_code=$(json_error_code "$error_output")
    error_message=$(json_error_message "$error_output")
    [[ -n $error_code ]] || error_code=agent_steer_failed
    [[ -n $error_message ]] || error_message=$error_output
    emit_prompt_failure "$pane" "$error_code" "$error_message" "$initial_status"
    return 1
  fi
  status=$(jq -er '.result.agent.agent_status' <<<"$output")
  if [[ $status != working ]]; then
    emit_prompt_failure "$pane" agent_steer_not_working \
      "agent left working state before the steer was accepted" "$status"
    return 1
  fi
  jq -n \
    --arg pane_id "$pane" \
    --arg initial_status "$initial_status" \
    --arg status "$status" \
    --argjson bytes "$message_bytes" \
    '{accepted: true, mode: "steer", pane_id: $pane_id, initial_status: $initial_status, status: $status, bytes: $bytes}'
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
  (($#)) || usage

  local command=$1
  if [[ $command == start || $command == resume ]]; then
    guard_incompatible_entrypoint "$command"
  fi
  require_herdr
  init_temp_dir
  shift
  case $command in
    start) start_worker "$@" ;;
    resume) resume_worker "$@" ;;
    send) send_message "$@" ;;
    steer) steer_message "$@" ;;
    status) show_status "$@" ;;
    *) usage ;;
  esac
}

main "$@"
