#!/usr/bin/env bash
# Gmail同期のあとに実行する。追跡中のファイル（index.html など）に変更があればコミットしてプッシュする。
# - 新規ファイルは自動で追加しない（git add -u のみ）。公開してよいか毎回人が判断するため。
# - sync-data.js は .gitignore で除外済み。さらに pre-commit フックで個人情報の混入を止める。
#
# 使い方: bash sync-push.sh "コミットメッセージ（複数行可）"
set -euo pipefail
cd "$(dirname "$0")"

if [ -z "$(git status --porcelain --untracked-files=no)" ]; then
  echo "GitHub反映: 変更なし（同期データ sync-data.js はリポジトリ対象外）"
  exit 0
fi

msg="${1:-Gmail同期にあわせてアプリを更新}"
git add -u
echo "GitHub反映: 次のファイルをコミットします"
git diff --cached --name-only | sed 's/^/  - /'
git commit -q -m "$msg"
git push -q origin HEAD
echo "GitHub反映: プッシュ完了 ($(git rev-parse --short HEAD))"
