import requests, base64

PAT = "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"
H = {"Authorization": f"token {PAT}", "Accept": "application/vnd.github.v3+json"}

def update_workflow(repo, path, local_file):
    r = requests.get(f"https://api.github.com/repos/{repo}/contents/{path}", headers=H)
    sha = r.json().get("sha") if r.status_code == 200 else None
    
    with open(local_file) as f:
        content = f.read()
    
    payload = {
        "message": "fix(ci): deploy under aifactory-medinovai user with correct home dir\n\n- SSH as MACSTUDIO_USER then sudo to aifactory-medinovai\n- Use /Users/aifactory-medinovai/medinovai/ as deploy path\n- Inject GITHUB_PAT into .env\n- Force --no-cache rebuild",
        "content": base64.b64encode(content.encode()).decode(),
        "branch": "main"
    }
    if sha:
        payload["sha"] = sha
    
    r = requests.put(f"https://api.github.com/repos/{repo}/contents/{path}", headers=H, json=payload)
    if r.status_code in (200, 201):
        print(f"✅ {repo}: updated — commit {r.json()['commit']['sha'][:8]}")
    else:
        print(f"❌ {repo}: {r.status_code} — {r.text[:200]}")

update_workflow("medinovai-health/medinovai-2ag-astra", ".github/workflows/deploy.yml", "/tmp/astra_workflow_fix.yml")
update_workflow("medinovai-health/medinovai-2ag-deploy", ".github/workflows/deploy.yml", "/tmp/deploy_workflow_fix.yml")
