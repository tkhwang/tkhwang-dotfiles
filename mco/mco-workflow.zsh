# mco workflow helpers — provider 는 항상 첫 번째 인자로 명시
#
#   mco-plan  <reviewers> <plan.md>                 plan review + debate  -> <plan>.debate.md
#   mco-code  <reviewers> [base-ref] [--plan p.md]  구현 리뷰 (git diff base-ref, 기본 main)
#   mco-impl  <provider>  <plan.md>                 구현 (write 모드)
#
#   예) mco-plan codex,grok plans/auth.md
#       mco-code codex,gemini main --plan plans/auth.md
#       mco-impl codex plans/auth.md
#   공통 옵션: -n (dry-run), 그 외 --xxx 는 mco 로 그대로 전달 (예: --stream live)

: ${MCO_ARTIFACT_BASE:=reports/mco}

# _mco_parse <usage> "$@"  ->  _mco_providers, _mco_pos[], _mco_extra[], _mco_plan
_mco_parse() {
  local usage="$1"; shift
  _mco_providers="" _mco_plan=""; _mco_pos=(); _mco_extra=()
  if [[ -z "$1" || "$1" == -* ]]; then
    echo "usage: $usage" >&2; return 2
  fi
  _mco_providers="$1"; shift
  while (( $# )); do
    case "$1" in
      -n)     _mco_extra+=(--dry-run); shift ;;
      --plan) _mco_plan="$2"; shift 2 ;;
      -*)     _mco_extra+=("$1"); shift ;;
      *)      _mco_pos+=("$1"); shift ;;
    esac
  done
}

mco-plan() {
  local usage="mco-plan <reviewers> <plan.md> [-n]   e.g. mco-plan codex,grok plans/auth.md"
  _mco_parse "$usage" "$@" || return
  local plan="${_mco_pos[1]}"
  [[ -f "$plan" ]] || { echo "usage: $usage" >&2; return 2; }
  local id="plan-review-${${plan:t}:r}-$(date +%Y%m%d-%H%M%S)"
  local out="${plan:r}.debate.md"
  echo "▶ plan review by [$_mco_providers]: $plan" >&2
  mco review --repo . --providers "$_mco_providers" --debate \
    --task-id "$id" --artifact-base "$MCO_ARTIFACT_BASE" --result-mode both \
    --target-paths "$plan,." \
    --prompt "Review the implementation plan at '$plan' against this repository.
Point out: missing requirements, wrong assumptions about the existing code, risky/ambiguous steps,
ordering problems, missing tests, and simpler alternatives. Reference concrete files where possible.
Do not modify any files." \
    "${_mco_extra[@]}"
  local rc=$?
  if [[ -f "$MCO_ARTIFACT_BASE/$id/result.md" ]]; then
    cp "$MCO_ARTIFACT_BASE/$id/result.md" "$out" && echo "✔ debate doc: $out" >&2
  fi
  return $rc
}

mco-code() {
  local usage="mco-code <reviewers> [base-ref] [--plan plan.md] [-n]   e.g. mco-code codex,grok main"
  _mco_parse "$usage" "$@" || return
  local base="${_mco_pos[1]:-main}"
  git rev-parse --verify -q "$base" &>/dev/null || base=HEAD
  local id="code-review-$(date +%Y%m%d-%H%M%S)"
  local spec=""
  [[ -n "$_mco_plan" ]] && spec="
Also check the changes against the plan in '$_mco_plan' (missing or extra scope)."
  echo "▶ code review by [$_mco_providers]: diff vs $base" >&2
  mco review --repo . --providers "$_mco_providers" \
    --task-id "$id" --artifact-base "$MCO_ARTIFACT_BASE" --result-mode both \
    --prompt "Review the changes shown by \`git diff $base\` (including uncommitted and untracked files).
Focus on correctness bugs, regressions, security issues, and missing tests. Cite file:line.$spec
Do not modify any files." \
    "${_mco_extra[@]}"
}

mco-impl() {
  local usage="mco-impl <provider> <plan.md> [-n]   e.g. mco-impl codex plans/auth.md"
  _mco_parse "$usage" "$@" || return
  local plan="${_mco_pos[1]}"
  [[ -f "$plan" ]] || { echo "usage: $usage" >&2; return 2; }
  local id="impl-${${plan:t}:r}-$(date +%Y%m%d-%H%M%S)"
  echo "▶ implement by [$_mco_providers]: $plan" >&2
  mco run --repo . --providers "$_mco_providers" --execution-mode write \
    --task-id "$id" --artifact-base "$MCO_ARTIFACT_BASE" --result-mode both \
    --prompt "Implement the plan in '$plan' step by step.
Follow the plan exactly; if something in the plan is wrong, stop and explain instead of improvising.
Run the relevant build/lint/tests and report the results at the end." \
    "${_mco_extra[@]}"
}
