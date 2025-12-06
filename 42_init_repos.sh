#!/usr/bin/env bash
set -euo pipefail

# 自分と同じディレクトリの config を読む
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# 設定読み込み（OWNER, BASE_DIR, REPOS が定義される）
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/42_repos_config.sh"

mkdir -p "${BASE_DIR}"

echo "Creating / configuring / initializing GitHub repositories under org: ${OWNER}"
echo -e "Total: ${#REPOS[@]} repos\n"

for repo in "${REPOS[@]}"; do
  full="${OWNER}/${repo}"
  target_dir="${BASE_DIR}/${repo}"
  echo "==== ${full} ===="

  ############################
  # 1. GitHub 上にリポジトリ作成
  ############################
  if gh repo view "${full}" >/dev/null 2>&1; then
    echo "  -> Repo already exists on GitHub."
  else
    echo "  -> Creating GitHub repo (public)..."
    if gh repo create "${full}" --public -y >/dev/null 2>&1; then
      echo "  -> Created."
    else
      echo -e "  !! Failed to create repo on GitHub. Skipping this repo.\n"
      continue
    fi
  fi

  ############################
  # 2. description / topics 設定
  ############################
  echo "  -> Updating description/topics..."
  safe_repo=$(echo "${repo}" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
  topic_project="42-${safe_repo}"

  if ! gh repo edit "${full}" \
        --description "42 project: ${repo}" \
        --add-topic 42 \
        --add-topic 42tokyo \
        --add-topic "${topic_project}"; then
    echo "  !! gh repo edit failed (description/topics). Continuing anyway."
  fi

  ############################
  # 3. ローカル clone or 再利用
  ############################
  if [ -d "${target_dir}/.git" ]; then
    echo "  -> Local clone exists at ${target_dir}, reusing it."
    cd "${target_dir}"
  else
    if ! git clone "https://github.com/${full}.git" "${target_dir}"; then
      echo -e "  !! clone failed, skipping initial commit for this repo.\n"
      continue
    fi
    cd "${target_dir}"
  fi

  ############################
  # 4. 初回 README コミット作成 (master)
  ############################
  if git rev-parse --quiet --verify HEAD >/dev/null; then
    echo "  -> Repo already has commits. Skipping initial README."
    cd "${SCRIPT_DIR}"  # 元のディレクトリに戻る（or cd - >/dev/null）
    continue
  fi

  echo "  -> No commits yet. Creating initial README.md on 'master' branch ..."
  git checkout -b master

  echo "# ${repo}" > README.md
  git add README.md
  git commit -m "Add initial README"

  echo "  -> Pushing 'master' to origin ..."
  git push -u origin master
  echo "  -> Done."

  cd "${SCRIPT_DIR}"
done

echo "=== All done. ==="
