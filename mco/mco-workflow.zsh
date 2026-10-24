# mco workflow helpers — provider 는 항상 첫 번째 인자로 명시
#
#   mco-plan-draft  <drafters>  <spec.md>                 독립 접근안 수집     -> <spec>.drafts.md
#   mco-plan-review <reviewers> <plan.md>                 plan review + debate -> <plan>.debate.md
#   mco-code-impl   <provider>  <plan.md>                 구현 (write 모드)
#   mco-code-review <reviewers> [base-ref] [--plan p.md]  구현 리뷰 (git diff base-ref, 기본 main)
#
#   예) mco-plan-draft claude,codex,grok plans/auth.spec.md
#       mco-plan-review codex,grok plans/auth.md
#       mco-code-review codex,gemini main --plan plans/auth.md
#       mco-code-impl codex plans/auth.md
#   파일 인자는 경로 대신 이름 일부만 줘도 됨 (예: insight). 여러 개 매칭되면 터미널에서 fzf 로 선택
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
      --dry-run|--json|--quiet|--synthesize|--save-artifacts|--include-token-usage|--debate|--chain|--*=*)
              _mco_extra+=("$1"); shift ;;
      -*)     _mco_extra+=("$1" "$2"); shift 2 ;;   # --flag value
      *)      _mco_pos+=("$1"); shift ;;
    esac
  done
}

# _mco_resolve_file <query> <usage>  -> 확정된 파일 경로를 stdout 으로
#   query: 정확한 경로 또는 파일명 일부 (공백 = AND, 대소문자 무시)
#   1개 매칭 -> 바로 사용 / 여러 개 -> 터미널이면 fzf, 아니면 후보 출력 후 에러 / 0개 -> 터미널이면 전체에서 fzf
#   검색 대상: git 이면 tracked+untracked (gitignore 제외), 아니면 find. 확장자는 MCO_FILE_GLOB (기본 *.md)
: ${MCO_FILE_GLOB:=*.md}
_mco_resolve_file() {
  local q="$1" usage="$2"
  [[ -n "$q" && -f "$q" ]] && { print -r -- "$q"; return 0; }

  local -a all matches
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    all=(${(f)"$(git ls-files -co --exclude-standard -- "$MCO_FILE_GLOB")"})
  else
    all=(${(f)"$(find . -name node_modules -prune -o -name .git -prune -o -type f -name "$MCO_FILE_GLOB" -print | sed 's|^\./||')"})
  fi
  local f term ok
  if [[ -n "$q" ]]; then
    for f in "${all[@]}"; do
      ok=1
      for term in ${=q}; do [[ "${(L)f}" == *"${(L)term}"* ]] || { ok=0; break; }; done
      (( ok )) && matches+=("$f")
    done
  fi

  if (( ${#matches} == 1 )); then
    echo "▶ file: ${matches[1]}" >&2; print -r -- "${matches[1]}"; return 0
  fi

  local interactive=0
  [[ -t 0 && -t 2 ]] && command -v fzf >/dev/null && interactive=1
  if (( interactive )); then
    local -a pool=("${matches[@]}"); (( ${#pool} )) || pool=("${all[@]}")
    local header="${#matches} matches for '$q'"; [[ -z "$q" ]] && header="pick a file"
    local picked
    picked=$(print -rl -- "${pool[@]}" | fzf --query "$q" --height 40% --reverse \
      --prompt "file> " --header "$header" --preview 'head -40 {}')
    [[ -n "$picked" ]] && { echo "▶ file: $picked" >&2; print -r -- "$picked"; return 0; }
    return 2
  fi

  if [[ -z "$q" ]]; then
    echo "usage: $usage" >&2
  elif (( ${#matches} == 0 )); then
    echo "error: no file matches '$q' (cwd: $PWD)" >&2
  else
    echo "error: '$q' matches ${#matches} files, be more specific:" >&2
    print -rl -- "${matches[@]}" | sed 's/^/  /' >&2
  fi
  return 2
}

mco-plan-draft() {
  local usage="mco-plan-draft <drafters> <spec.md> [-n]   e.g. mco-plan-draft claude,codex,grok plans/auth.spec.md"
  _mco_parse "$usage" "$@" || return
  local spec="${_mco_pos[1]}"
  spec=$(_mco_resolve_file "$spec" "$usage") || return 2
  local name="${${spec:t}:r}"; name="${name%.spec}"
  local id="plan-draft-$name-$(date +%Y%m%d-%H%M%S)"
  local out="${spec:h}/$name.drafts.md"
  echo "▶ plan drafts by [$_mco_providers]: $spec" >&2
  mco review --repo . --providers "$_mco_providers" \
    --task-id "$id" --artifact-base "$MCO_ARTIFACT_BASE" --result-mode both \
    --invocation-hard-timeout 600 \
    --target-paths "$spec,." \
    --prompt "Read the requirements in '$spec' and study this repository.
Propose ONE implementation approach on your own. Do NOT write a full step-by-step plan. Keep it short:
1. Approach: the core design in a few sentences
2. Key decisions: the choices you made and the alternatives you rejected (why)
3. Files/modules to touch: concrete paths
4. Risks & unknowns: what could go wrong, what needs clarification from the user
5. Test strategy: how to verify it
Do not modify any files." \
    "${_mco_extra[@]}"
  local rc=$?
  if [[ -f "$MCO_ARTIFACT_BASE/$id/result.md" ]]; then
    cp "$MCO_ARTIFACT_BASE/$id/result.md" "$out" && echo "✔ drafts doc: $out" >&2
  fi
  return $rc
}

mco-plan-review() {
  local usage="mco-plan-review <reviewers> <plan.md> [-n]   e.g. mco-plan-review codex,grok plans/auth.md"
  _mco_parse "$usage" "$@" || return
  local plan="${_mco_pos[1]}"
  plan=$(_mco_resolve_file "$plan" "$usage") || return 2
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

mco-code-review() {
  local usage="mco-code-review <reviewers> [base-ref] [--plan plan.md] [-n]   e.g. mco-code-review codex,grok main"
  _mco_parse "$usage" "$@" || return
  local base="${_mco_pos[1]:-main}"
  git rev-parse --verify -q "$base" &>/dev/null || base=HEAD
  if [[ -n "$_mco_plan" ]]; then _mco_plan=$(_mco_resolve_file "$_mco_plan" "$usage") || return 2; fi
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

mco-code-impl() {
  local usage="mco-code-impl <provider> <plan.md> [-n]   e.g. mco-code-impl codex plans/auth.md"
  _mco_parse "$usage" "$@" || return
  local plan="${_mco_pos[1]}"
  plan=$(_mco_resolve_file "$plan" "$usage") || return 2
  local id="impl-${${plan:t}:r}-$(date +%Y%m%d-%H%M%S)"
  echo "▶ implement by [$_mco_providers]: $plan" >&2
  mco run --repo . --providers "$_mco_providers" --execution-mode write \
    --task-id "$id" --artifact-base "$MCO_ARTIFACT_BASE" --result-mode both \
    --prompt "Implement the plan in '$plan' step by step.
Follow the plan exactly; if something in the plan is wrong, stop and explain instead of improvising.
Run the relevant build/lint/tests and report the results at the end." \
    "${_mco_extra[@]}"
}
