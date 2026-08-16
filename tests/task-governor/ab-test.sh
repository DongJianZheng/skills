#!/bin/zsh

set -euo pipefail

if (( $# < 3 )); then
  echo "用法: $0 <项目目录> <任务清单> <核验任务>" >&2
  exit 2
fi

project_input="$1"
plan_input="$2"
verification_task="$3"

if [[ ! -d "$project_input" ]]; then
  echo "项目目录不存在: $project_input" >&2
  exit 2
fi
if [[ ! -f "$plan_input" ]]; then
  echo "任务清单不存在: $plan_input" >&2
  exit 2
fi
if ! command -v codex >/dev/null 2>&1; then
  echo "未找到 codex CLI" >&2
  exit 2
fi
if ! command -v node >/dev/null 2>&1; then
  echo "未找到 Node.js" >&2
  exit 2
fi

project_dir="$(cd "$project_input" && pwd)"
plan_dir="$(cd "$(dirname "$plan_input")" && pwd)"
plan_file="$plan_dir/$(basename "$plan_input")"
script_dir="$(cd "$(dirname "$0")" && pwd)"
summary_script="$script_dir/summarize-codex-json.mjs"
model_name="${TASK_GOVERNOR_MODEL:-}"
ab_temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/task-governor-ab.XXXXXX")"
trap '/bin/rm -rf "$ab_temp_dir"' EXIT

base_task="以 $plan_file 为唯一任务清单。只做只读核验：$verification_task。给出结论、直接证据和未验证边界；不要修改文件，不联网。"

model_args=()
if [[ -n "$model_name" ]]; then
  model_args=(--model "$model_name")
fi

run_case() {
  local case_label="$1"
  local case_prompt="$2"
  local case_log="$ab_temp_dir/$case_label.jsonl"
  local case_stderr="$ab_temp_dir/$case_label.stderr"
  local started_at="$(date +%s)"

  if ! codex exec \
    --json \
    --ephemeral \
    "${model_args[@]}" \
    --sandbox read-only \
    --skip-git-repo-check \
    --cd "$project_dir" \
    --add-dir "$plan_dir" \
    "$case_prompt" >"$case_log" 2>"$case_stderr"; then
    echo "测试失败: $case_label" >&2
    tail -n 20 "$case_stderr" >&2
    return 1
  fi

  local finished_at="$(date +%s)"
  node "$summary_script" "$case_log" "$case_label" "$((finished_at - started_at))"
}

echo "同条件 A/B｜模型: ${model_name:-Codex 当前默认模型}｜read-only"
run_case "A_未调用Skill" "$base_task"
run_case "B_调用task-governor" "使用 \$task-governor。$base_task"
