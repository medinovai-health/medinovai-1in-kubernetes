#!/usr/bin/env bash
set -euo pipefail
ORG="myonsite-healthcare"
MATCH="medinovai"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) ORG="$2"; shift 2 ;;
    --match) MATCH="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done
command -v gh >/dev/null || { echo "gh CLI required"; exit 1; }
echo "repo,has_pr,merged,default_branch"
repos=$(gh api -X GET orgs/${ORG}/repos --paginate -f per_page=100 --jq '.[] | select(.private==true and .archived==false and (.name | test(env.MATCH; "i"))) | .name')
for r in $repos; do
  has_pr=$(gh pr list -R "${ORG}/$r" --search "Adopt medinovai standards in:title" --json number --jq 'length')
  merged=$(gh pr list -R "${ORG}/$r" --search "Adopt medinovai standards is:merged" --json number --jq 'length')
  def=$(gh repo view "${ORG}/$r" --json defaultBranchRef --jq '.defaultBranchRef.name')
  echo "${r},${has_pr},${merged},${def}"
done
