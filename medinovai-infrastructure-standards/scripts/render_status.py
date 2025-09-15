#!/usr/bin/env python3
import sys, csv
rows=list(csv.DictReader(open(sys.argv[1])))
print("# Rollout status\n")
print("| Repo | PR opened | Merged | Default branch |")
print("|------|-----------|--------|----------------|")
for r in rows:
    print(f"| {r['repo']} | {r['has_pr']} | {r['merged']} | {r['default_branch']} |")
