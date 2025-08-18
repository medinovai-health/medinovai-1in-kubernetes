package repo.rules

# Enforce presence of branch protection config file or rulesets manifest.
deny[msg] {
  not input_has_file(".github/branch-protection.yml")
  not input_has_file(".github/rulesets.yml")
  msg := "Repository must include branch protection configuration (.github/branch-protection.yml or .github/rulesets.yml)"
}

# Disallow plaintext PHI markers in log lines (heuristic)
deny[msg] {
  f := input.files[_]
  endswith(f.path, ".py") or endswith(f.path, ".cs") or endswith(f.path, ".rs") or endswith(f.path, ".kt") or endswith(f.path, ".swift")
  lower(f.content) contains "phi:"
  lower(f.content) contains "print("  # crude heuristic for plaintext log
  msg := sprintf("Potential PHI plaintext logging in %v (heuristic)", [f.path])
}

# Helper
input_has_file(name) {
  some f
  f := input.files[_]
  f.path == name
}
