#!/usr/bin/env bash

set -euo pipefail

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly TEST_DIR
HELPER=$(cd "$TEST_DIR/.." && pwd)/scripts/herdr-worker.sh
readonly HELPER
TEST_TMP=$(mktemp -d)
readonly TEST_TMP
trap 'rm -rf "$TEST_TMP"' EXIT

fail() {
  printf 'herdr-worker-test: %s\n' "$*" >&2
  exit 1
}

codex() {
  :
}

git() {
  printf 'git %s\n' "$*" >>"$TEST_TMP/calls"
  case "$HERDR_FAKE_SCENARIO:$3:$4" in
    *:check-ref-format:--branch)
      return 0
      ;;
    start-existing:branch:--show-current)
      printf '%s\n' hindsight-pgrooga
      ;;
    start-mismatch:branch:--show-current)
      printf '%s\n' other-work
      ;;
    *:branch:--show-current)
      printf '%s\n' main
      ;;
    *:symbolic-ref:--quiet)
      printf '%s\n' origin/main
      ;;
    *:status:--porcelain)
      ;;
    start-branch-exists:show-ref:--verify)
      return 0
      ;;
    *:show-ref:--verify)
      return 1
      ;;
    *:switch:-c)
      ;;
    *)
      printf 'unexpected git call: %s\n' "$*" >&2
      return 1
      ;;
  esac
}

og() {
  printf 'og %s\n' "$*" >>"$TEST_TMP/calls"
  [[ $* == pull ]] || return 1
}

herdr() {
  printf '%s\n' "$*" >>"$TEST_TMP/calls"
  case "$HERDR_FAKE_SCENARIO:$1:$2" in
    start-tab-failure:tab:create)
      printf '%s\n' '{"id":"cli:tab:create","error":{"code":"workspace_not_found","message":"workspace missing"}}' >&2
      return 1
      ;;
    start*:tab:create)
      printf '%s\n' '{"result":{"tab":{"tab_id":"w2:t2"},"root_pane":{"pane_id":"w2:p2"}}}'
      ;;
    start*:agent:start)
      local count=0
      [[ ! -f $TEST_TMP/start-count ]] || count=$(<"$TEST_TMP/start-count")
      count=$((count + 1))
      printf '%s\n' "$count" >"$TEST_TMP/start-count"
      if ((count < 3)); then
        printf '%s\n' '{"id":"cli:agent:start","error":{"code":"agent_pane_busy","message":"shell not ready"}}' >&2
        return 1
      fi
      printf '%s\n' '{"result":{"agent":{"agent_status":"idle","agent":"codex"}}}'
      ;;
    send-success:agent:get|send-stalled:agent:get)
      printf '%s\n' '{"result":{"agent":{"agent_status":"idle","agent":"codex"}}}'
      ;;
    send-done:agent:get)
      printf '%s\n' '{"result":{"agent":{"agent_status":"done","agent":"codex"}}}'
      ;;
    send-working:agent:get|steer-success:agent:get)
      printf '%s\n' '{"result":{"agent":{"agent_status":"working","agent":"codex"}}}'
      ;;
    steer-idle:agent:get)
      printf '%s\n' '{"result":{"agent":{"agent_status":"idle","agent":"codex"}}}'
      ;;
    send-wait-ready:agent:wait)
      printf '%s\n' '{"result":{"agent":{"agent_status":"idle","agent":"codex"}}}'
      ;;
    send-wait-ready:agent:get)
      printf '%s\n' '{"result":{"agent":{"agent_status":"idle","agent":"codex"}}}'
      ;;
    send-success:agent:prompt|send-done:agent:prompt|send-wait-ready:agent:prompt)
      printf '%s\n' '{"result":{"agent":{"agent_status":"working","agent":"codex"}}}'
      ;;
    steer-success:agent:prompt)
      printf '%s\n' '{"result":{"agent":{"agent_status":"working","agent":"codex"}}}'
      ;;
    send-stalled:agent:prompt)
      printf '%s\n' '{"id":"cli:agent:prompt","error":{"code":"agent_prompt_stalled","message":"no observed state change"}}' >&2
      return 1
      ;;
    resume:agent:get)
      printf '%s\n' '{"result":{"agent":{"agent_status":"working","agent":"codex"}}}'
      ;;
    resume-pending:agent:get)
      printf '%s\n' '{"result":{"agent":{"agent_status":"unknown","agent":"codex","launch_pending":true,"interactive_ready":false}}}'
      ;;
    resume-pending:agent:wait)
      printf '%s\n' '{"result":{"agent":{"agent_status":"idle","agent":"codex","launch_pending":false,"interactive_ready":true}}}'
      ;;
    resume:pane:get|resume-pending:pane:get)
      printf '%s\n' '{"result":{"pane":{"pane_id":"w2:p2","tab_id":"w2:t2","cwd":"/tmp/project"}}}'
      ;;
    *)
      printf 'unexpected herdr call: %s\n' "$*" >&2
      return 1
      ;;
  esac
}

export -f codex git og herdr
export HERDR_ENV=1 HERDR_WORKSPACE_ID=w1 HERDR_PANE_ID=w1:p1 TEST_TMP

HERDR_FAKE_SCENARIO=start
export HERDR_FAKE_SCENARIO
start_output=$(cd "$TEST_TMP" && bash "$HELPER" start hindsight-pgrooga)
[[ $(jq -r '.started' <<<"$start_output") == true ]] || fail "start did not succeed"
[[ $(jq -r '.worker_pane_id' <<<"$start_output") == w2:p2 ]] || fail "start returned wrong pane"
[[ $(<"$TEST_TMP/start-count") == 3 ]] || fail "start did not retry busy twice"
[[ $(grep -c '^tab create ' "$TEST_TMP/calls") == 1 ]] || fail "start created more than one tab"
grep -Fq "og pull" "$TEST_TMP/calls" || fail "start did not pull the default branch"
grep -Fq "git -C $TEST_TMP switch -c hindsight-pgrooga" "$TEST_TMP/calls" || \
  fail "start did not create the requested branch"
grep -Fq "tab create --workspace w1 --cwd $TEST_TMP --label hindsight-pgrooga --no-focus" "$TEST_TMP/calls" || \
  fail "start did not use the branch name as the tab label"
grep -Fq "agent start hindsight-pgrooga --kind codex --pane w2:p2 --timeout 30000 -- -C $TEST_TMP -m gpt-5.6-luna -c model_reasoning_effort=\"max\"" "$TEST_TMP/calls" || \
  fail "start did not pin the Luna model with max reasoning"

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=start-existing
export HERDR_FAKE_SCENARIO
existing_output=$(cd "$TEST_TMP" && bash "$HELPER" start hindsight-pgrooga)
[[ $(jq -r '.started' <<<"$existing_output") == true ]] || fail "matching feature branch did not start"
if grep -q '^og pull$\| switch -c ' "$TEST_TMP/calls"; then
  fail "matching feature branch was pulled or recreated"
fi

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=start-mismatch
export HERDR_FAKE_SCENARIO
set +e
(cd "$TEST_TMP" && bash "$HELPER" start hindsight-pgrooga) >"$TEST_TMP/mismatch-output" 2>"$TEST_TMP/mismatch-error"
mismatch_status=$?
set -e
[[ $mismatch_status == 1 ]] || fail "mismatched feature branch did not fail"
grep -Fq 'current branch other-work does not match worker name hindsight-pgrooga' "$TEST_TMP/mismatch-error" || \
  fail "mismatched branch failure was not actionable"
if grep -q '^tab create ' "$TEST_TMP/calls"; then
  fail "mismatched branch created a tab"
fi

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=start-branch-exists
export HERDR_FAKE_SCENARIO
set +e
(cd "$TEST_TMP" && bash "$HELPER" start hindsight-pgrooga) >"$TEST_TMP/exists-output" 2>"$TEST_TMP/exists-error"
exists_status=$?
set -e
[[ $exists_status == 1 ]] || fail "existing target branch did not fail"
grep -Fq 'branch already exists: hindsight-pgrooga' "$TEST_TMP/exists-error" || \
  fail "existing target branch failure was not actionable"
if grep -q '^og pull$\|^tab create ' "$TEST_TMP/calls"; then
  fail "existing target branch pulled or created a tab"
fi

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=start-tab-failure
export HERDR_FAKE_SCENARIO
set +e
tab_failure_output=$(cd "$TEST_TMP" && bash "$HELPER" start hindsight-pgrooga)
tab_failure_status=$?
set -e
[[ $tab_failure_status == 1 ]] || fail "tab failure did not fail"
[[ $(jq -r '.started' <<<"$tab_failure_output") == false ]] || fail "tab failure was not structured"
[[ $(jq -r '.error' <<<"$tab_failure_output") == workspace_not_found ]] || fail "tab failure lost Herdr error code"

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=send-success
export HERDR_FAKE_SCENARIO
send_output=$(bash "$HELPER" send --pane w2:p2 --message 'implement the spec')
[[ $(jq -r '.accepted' <<<"$send_output") == true ]] || fail "prompt was not accepted"
[[ $(jq -r '.initial_status' <<<"$send_output") == idle ]] || fail "prompt initial status was not recorded"
[[ $(jq -r '.status' <<<"$send_output") == working ]] || fail "prompt did not require working"
grep -q '^agent prompt w2:p2 implement the spec --wait --until working --timeout 10000$' "$TEST_TMP/calls" || \
  fail "prompt did not use the verified Agent API"

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=send-stalled
export HERDR_FAKE_SCENARIO
set +e
stalled_output=$(bash "$HELPER" send --pane w2:p2 --message 'implement the spec')
stalled_status=$?
set -e
[[ $stalled_status == 1 ]] || fail "stalled prompt did not fail"
[[ $(jq -r '.accepted' <<<"$stalled_output") == false ]] || fail "stalled prompt claimed acceptance"
[[ $(jq -r '.error' <<<"$stalled_output") == agent_prompt_stalled ]] || fail "stalled prompt lost Herdr error code"

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=send-done
export HERDR_FAKE_SCENARIO
done_output=$(bash "$HELPER" send --pane w2:p2 --message 'review fixes')
[[ $(jq -r '.accepted' <<<"$done_output") == true ]] || fail "done agent did not accept prompt"
[[ $(jq -r '.initial_status' <<<"$done_output") == "done" ]] || fail "done initial status was not preserved"

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=send-working
export HERDR_FAKE_SCENARIO
set +e
working_output=$(bash "$HELPER" send --pane w2:p2 --message 'review fixes')
working_status=$?
set -e
[[ $working_status == 1 ]] || fail "working agent prompt was not rejected"
[[ $(jq -r '.error' <<<"$working_output") == agent_not_idle ]] || fail "working rejection had wrong error"
if grep -q '^agent prompt ' "$TEST_TMP/calls"; then
  fail "working agent received an unverifiable prompt"
fi

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=steer-success
export HERDR_FAKE_SCENARIO
steer_output=$(bash "$HELPER" steer --pane w2:p2 --message 'also remove the internal hash')
[[ $(jq -r '.accepted' <<<"$steer_output") == true ]] || fail "working agent did not accept steer"
[[ $(jq -r '.mode' <<<"$steer_output") == steer ]] || fail "steer mode was not recorded"
[[ $(jq -r '.initial_status' <<<"$steer_output") == working ]] || fail "steer initial status was not working"
[[ $(jq -r '.status' <<<"$steer_output") == working ]] || fail "steer did not preserve working status"
grep -q '^agent prompt w2:p2 also remove the internal hash$' "$TEST_TMP/calls" || \
  fail "steer did not submit directly to the active Agent turn"

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=steer-idle
export HERDR_FAKE_SCENARIO
set +e
idle_steer_output=$(bash "$HELPER" steer --pane w2:p2 --message 'late requirement')
idle_steer_status=$?
set -e
[[ $idle_steer_status == 1 ]] || fail "idle agent steer was not rejected"
[[ $(jq -r '.error' <<<"$idle_steer_output") == agent_not_working ]] || fail "idle steer rejection had wrong error"
if grep -q '^agent prompt ' "$TEST_TMP/calls"; then
  fail "idle agent received a steer"
fi

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=send-wait-ready
export HERDR_FAKE_SCENARIO
callback_output=$(bash "$HELPER" send --wait-ready --pane w1:p1 --message 'IMPL_COMPLETE: report')
[[ $(jq -r '.accepted' <<<"$callback_output") == true ]] || fail "wait-ready callback was not accepted"
[[ $(jq -r '.waited_for_ready' <<<"$callback_output") == true ]] || fail "wait-ready result was not recorded"
grep -q '^agent wait w1:p1 --until idle --until done$' "$TEST_TMP/calls" || \
  fail "callback did not wait for owner readiness"
grep -q '^agent prompt w1:p1 IMPL_COMPLETE: report --wait --until working --timeout 10000$' "$TEST_TMP/calls" || \
  fail "callback did not use the verified Agent API"

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=resume
export HERDR_FAKE_SCENARIO
resume_output=$(bash "$HELPER" resume --pane w2:p2)
[[ $(jq -r '.started' <<<"$resume_output") == true ]] || fail "resume did not recover running Codex"
[[ $(jq -r '.resumed' <<<"$resume_output") == true ]] || fail "resume did not identify existing Codex"
if grep -q '^agent start ' "$TEST_TMP/calls"; then
  fail "resume started a second agent in an occupied pane"
fi

: >"$TEST_TMP/calls"
HERDR_FAKE_SCENARIO=resume-pending
export HERDR_FAKE_SCENARIO
pending_output=$(bash "$HELPER" resume --pane w2:p2)
[[ $(jq -r '.started' <<<"$pending_output") == true ]] || fail "resume did not wait for pending Codex"
grep -q '^agent wait w2:p2 --until idle --until done --timeout 10000$' "$TEST_TMP/calls" || \
  fail "resume did not wait for interactive readiness"

printf 'herdr-worker tests passed\n'
