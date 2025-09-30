#!/bin/bash
# MedinovAI Restore Point Creation Script
# Creates comprehensive restore points before any repository updates

set -e

RESTORE_POINT_DIR="restore-points/$(date +%Y-%m-%d-%H-%M-%S)"
mkdir -p "$RESTORE_POINT_DIR"

echo "🔄 Creating restore point: $RESTORE_POINT_DIR"

# 1. Git state backup
echo "📦 Backing up git states..."
find /Users/dev1/github -name "*medinovai*" -type d -exec sh -c '
  cd "$1" 2>/dev/null && {
    echo "Backing up: $1"
    git log --oneline -1 > "$RESTORE_POINT_DIR/git-$(basename "$1").txt" 2>/dev/null || echo "No git repo"
  }
' _ {} \;

# 2. Repository state documentation
echo "📋 Documenting repository states..."
cat > "$RESTORE_POINT_DIR/repository-states.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "repositories": [
EOF

find /Users/dev1/github -name "*medinovai*" -type d | while read repo; do
  repo_name=$(basename "$repo")
  file_count=$(find "$repo" -type f | wc -l)
  size=$(du -sh "$repo" 2>/dev/null | cut -f1)
  echo "    {\"name\": \"$repo_name\", \"path\": \"$repo\", \"files\": $file_count, \"size\": \"$size\"}," >> "$RESTORE_POINT_DIR/repository-states.json"
done

echo "  ]
}" >> "$RESTORE_POINT_DIR/repository-states.json"

# 3. Kubernetes state backup
echo "☸️ Backing up Kubernetes state..."
kubectl get all -A -o yaml > "$RESTORE_POINT_DIR/kubernetes-state.yaml" 2>/dev/null

# 4. Configuration backup
echo "⚙️ Backing up configurations..."
cp -r config/ "$RESTORE_POINT_DIR/configuration-backup/" 2>/dev/null

# 5. Create rollback script
cat > "$RESTORE_POINT_DIR/rollback-script.sh" << 'EOF'
#!/bin/bash
echo "🔄 Rolling back to restore point..."

# Restore git states
find restore-points/$(basename "$0" .sh)/ -name "git-*.txt" | while read git_file; do
  repo_name=$(basename "$git_file" .txt | sed 's/git-//')
  repo_path="/Users/dev1/github/$repo_name"
  if [ -d "$repo_path" ]; then
    cd "$repo_path"
    commit_hash=$(cat "$git_file" | cut -d' ' -f1)
    git reset --hard "$commit_hash" 2>/dev/null
    echo "Restored: $repo_name to $commit_hash"
  fi
done

# Restore Kubernetes state
kubectl apply -f restore-points/$(basename "$0" .sh)/kubernetes-state.yaml

echo "✅ Rollback completed"
EOF

chmod +x "$RESTORE_POINT_DIR/rollback-script.sh"

# 6. Update latest symlink
ln -sfn "$(basename "$RESTORE_POINT_DIR")" restore-points/latest

echo "✅ Restore point created: $RESTORE_POINT_DIR"


