#!/bin/zsh
set -euo pipefail

repo_url="${UNBLOCKLABS_PROMPT_REPO_URL:-https://github.com/unblocklabs-ai/unblocklabs-prompt.git}"
workspace_dir="${1:-/Users/Shared/openclaw-workspace-not-configured}"
state_dir="${workspace_dir}/.unblocklabs"
repo_dir="${state_dir}/source"
target_file="${state_dir}/AGENTS.md"
sha_file="${state_dir}/DEPLOYED_SHA"
lock_dir="${state_dir}/sync.lock"
clone_dir=""
candidate_file=""

cleanup() {
  if [[ -n "${candidate_file}" && "${candidate_file}" == "${state_dir}/AGENTS.md."* ]]; then
    rm -f -- "${candidate_file}" 2>/dev/null || true
  fi
  if [[ -n "${clone_dir}" && "${clone_dir}" == "${state_dir}/source."* && -d "${clone_dir}" ]]; then
    rm -R -- "${clone_dir}" 2>/dev/null || true
  fi
  rmdir "${lock_dir}" 2>/dev/null || true
}

if [[ ! -d "${workspace_dir}" ]]; then
  print -u2 -- "workspace does not exist: ${workspace_dir}"
  exit 2
fi

mkdir -p "${state_dir}"
if ! mkdir "${lock_dir}" 2>/dev/null; then
  exit 0
fi
trap cleanup EXIT

if [[ ! -d "${repo_dir}/.git" ]]; then
  if [[ -e "${repo_dir}" ]]; then
    print -u2 -- "source path exists but is not a git repository: ${repo_dir}"
    exit 6
  fi
  clone_dir="$(mktemp -d "${state_dir}/source.XXXXXX")"
  git clone --quiet --filter=blob:none --no-checkout "${repo_url}" "${clone_dir}"
  mv "${clone_dir}" "${repo_dir}"
  clone_dir=""
fi

git -C "${repo_dir}" fetch --quiet --depth=1 origin main
remote_sha="$(git -C "${repo_dir}" rev-parse FETCH_HEAD)"

if [[ -f "${sha_file}" ]] && [[ "$(<"${sha_file}")" == "${remote_sha}" ]] && [[ -s "${target_file}" ]]; then
  exit 0
fi

candidate_file="$(mktemp "${state_dir}/AGENTS.md.XXXXXX")"
git -C "${repo_dir}" show "${remote_sha}:UNBLOCKLABS.md" > "${candidate_file}"

if [[ ! -s "${candidate_file}" ]]; then
  print -u2 -- "refusing to deploy an empty UNBLOCKLABS.md"
  exit 3
fi

if ! grep -q '^# Unblock Labs Fleet Constitution' "${candidate_file}"; then
  print -u2 -- "refusing to deploy a document without the fleet constitution header"
  exit 4
fi

candidate_bytes="$(wc -c < "${candidate_file}" | tr -d ' ')"
if (( candidate_bytes > 35000 )); then
  print -u2 -- "refusing to deploy ${candidate_bytes} bytes; limit is 35000"
  exit 5
fi

chmod 0644 "${candidate_file}"
mv "${candidate_file}" "${target_file}"
candidate_file=""
print -r -- "${remote_sha}" > "${sha_file}.tmp"
mv "${sha_file}.tmp" "${sha_file}"
print -- "deployed unblocklabs-prompt ${remote_sha}"
