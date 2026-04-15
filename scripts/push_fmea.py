import requests, base64

PAT = "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"
H = {"Authorization": f"token {PAT}", "Accept": "application/vnd.github.v3+json"}

def push_file(repo, path, local_file, msg):
    r = requests.get(f"https://api.github.com/repos/{repo}/contents/{path}", headers=H)
    sha = r.json().get("sha") if r.status_code == 200 else None
    with open(local_file) as f:
        content = f.read()
    payload = {
        "message": msg,
        "content": base64.b64encode(content.encode()).decode(),
        "branch": "main"
    }
    if sha:
        payload["sha"] = sha
    r = requests.put(f"https://api.github.com/repos/{repo}/contents/{path}", headers=H, json=payload)
    if r.status_code in (200, 201):
        print(f"✅ {repo}/{path}: commit {r.json()['commit']['sha'][:8]}")
    else:
        print(f"❌ {repo}/{path}: {r.status_code} — {r.text[:200]}")

FMEA_MSG = "feat(fmea): expand FMEA engine to 128 detailed failure modes v3.0\n\nCovers Docker, Kubernetes, Terraform, GitHub Actions, SSH, DNS, SSL,\nDatabase, AWS, Node.js, Go, Python, Tailscale, System, Security,\nMonitoring, and Vidur event bus failure modes with automated CAPA responses."

push_file("medinovai-health/medinovai-2ag-deploy", "lib/fmea-engine.ts", "/home/ubuntu/fmea_engine_500.ts", FMEA_MSG)
push_file("medinovai-health/medinovai-2ag-astra", "lib/fmea-engine.ts", "/home/ubuntu/fmea_engine_500.ts", FMEA_MSG)
