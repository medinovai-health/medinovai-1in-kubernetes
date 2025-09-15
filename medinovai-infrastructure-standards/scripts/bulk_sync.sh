#!/usr/bin/env bash
set -euo pipefail
ORG="myonsite-healthcare"
MATCH="medinovai"
APPLY="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORG="$2"; shift 2 ;;
    --match) MATCH="$2"; shift 2 ;;
    --apply) APPLY="true"; shift ;;
    --dry-run) APPLY="false"; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done
command -v gh >/dev/null || { echo "gh CLI required"; exit 1; }
tmp_root=$(mktemp -d)
repos=$(gh api -X GET orgs/${ORG}/repos --paginate -f per_page=100 --jq '.[] | select(.private==true and .archived==false and (.name | test(env.MATCH; "i"))) | .name')
echo "Found repos:"
echo "$repos"
for r in $repos; do
  echo "==> ${ORG}/${r}"
  tmp="${tmp_root}/${r}"; mkdir -p "$tmp"
  gh repo clone "${ORG}/${r}" "$tmp"
  rsync -a "$(dirname "$0")/../templates/medinovai-app/" "$tmp/"
  pushd "$tmp" >/dev/null
  git checkout -b chore/medinovai-standards || true
  git add .
  if ! git diff --cached --quiet; then
    git commit -m "chore: adopt medinovai infrastructure standards"
    if [[ "$APPLY" == "true" ]]; then
      git push -u origin chore/medinovai-standards
      gh pr create --title "Adopt medinovai standards" --body "Adds CI, policy callers, deploy skeleton"
    else
      echo "(dry-run) would push PR for ${r}"
    fi
  else
    echo "No changes"
  fi
  popd >/dev/null
done
echo "Done"
