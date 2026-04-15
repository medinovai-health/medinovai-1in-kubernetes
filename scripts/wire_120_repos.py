"""
Wire all repos in medinovai-health org to the reusable AIFactory deploy workflow.
Only updates repos that DON'T already have an AIFactory-specific workflow.
"""
import requests, base64, json, time

PAT = "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"
H = {"Authorization": f"token {PAT}", "Accept": "application/vnd.github.v3+json"}
ORG = "medinovai-health"

# Repos that already have custom AIFactory workflows — skip these
SKIP_REPOS = {
    "medinovai-2ag-astra", "medinovai-2ag-deploy", "medinovai-infrastructure",
    "medinovai-command-center", "medinovai-intelligence-layer",
    "medinovai-website", "medinovai-ios", "medinovai-android",
    "medinovai-healthLLM", "hello-world-devin",
    # Add any others that already have custom workflows
}

def get_all_repos():
    repos = []
    page = 1
    while True:
        r = requests.get(f"https://api.github.com/orgs/{ORG}/repos?per_page=100&page={page}", headers=H)
        if r.status_code != 200:
            print(f"Error fetching repos: {r.status_code}")
            break
        data = r.json()
        if not data:
            break
        repos.extend(data)
        page += 1
        if len(data) < 100:
            break
    return repos

def has_aifactory_workflow(repo_name):
    """Check if repo already has an AIFactory-specific workflow."""
    r = requests.get(f"https://api.github.com/repos/{ORG}/{repo_name}/contents/.github/workflows", headers=H)
    if r.status_code != 200:
        return False
    files = r.json()
    for f in files:
        if isinstance(f, dict):
            # Check workflow content for AIFactory references
            wf_r = requests.get(f["download_url"], headers=H)
            if wf_r.status_code == 200 and ("aifactory" in wf_r.text.lower() or "macstudio" in wf_r.text.lower()):
                return True
    return False

def get_default_branch(repo_name):
    r = requests.get(f"https://api.github.com/repos/{ORG}/{repo_name}", headers=H)
    if r.status_code == 200:
        return r.json().get("default_branch", "main")
    return "main"

def wire_repo(repo_name, service_port=8080):
    """Add reusable AIFactory workflow to a repo."""
    branch = get_default_branch(repo_name)
    
    # Determine port based on repo name patterns
    port_map = {
        "api": 8080, "service": 8080, "backend": 8080,
        "frontend": 3000, "ui": 3000, "web": 3000,
        "worker": 8081, "job": 8081,
    }
    for key, port in port_map.items():
        if key in repo_name.lower():
            service_port = port
            break
    
    workflow_content = f"""name: Deploy to AIFactory
on:
  push:
    branches: [{branch}]
  workflow_dispatch:

jobs:
  deploy:
    uses: medinovai-health/medinovai-infrastructure/.github/workflows/deploy-to-aifactory.yml@main
    with:
      service_name: "{repo_name}"
      port: {service_port}
    secrets: inherit
"""
    
    # Check if workflow file already exists
    wf_path = ".github/workflows/deploy-to-aifactory.yml"
    r = requests.get(f"https://api.github.com/repos/{ORG}/{repo_name}/contents/{wf_path}", headers=H)
    sha = r.json().get("sha") if r.status_code == 200 else None
    
    payload = {
        "message": f"ci: wire {repo_name} to reusable AIFactory deploy workflow\n\nUses medinovai-infrastructure/.github/workflows/deploy-to-aifactory.yml\nService port: {service_port}",
        "content": base64.b64encode(workflow_content.encode()).decode(),
        "branch": branch
    }
    if sha:
        payload["sha"] = sha
    
    r = requests.put(f"https://api.github.com/repos/{ORG}/{repo_name}/contents/{wf_path}", headers=H, json=payload)
    return r.status_code in (200, 201), r.status_code

def main():
    print(f"Fetching all repos in {ORG}...")
    repos = get_all_repos()
    print(f"Found {len(repos)} repos total")
    
    results = {"wired": [], "skipped": [], "failed": [], "already_has_aifactory": []}
    
    for repo in repos:
        name = repo["name"]
        
        if name in SKIP_REPOS:
            results["skipped"].append(name)
            print(f"  ⏭ Skip (known custom): {name}")
            continue
        
        if repo.get("archived"):
            results["skipped"].append(name)
            print(f"  ⏭ Skip (archived): {name}")
            continue
        
        # Check if already has AIFactory workflow
        if has_aifactory_workflow(name):
            results["already_has_aifactory"].append(name)
            print(f"  ✓ Already has AIFactory workflow: {name}")
            continue
        
        # Wire it
        success, status = wire_repo(name)
        if success:
            results["wired"].append(name)
            print(f"  ✅ Wired: {name}")
        else:
            results["failed"].append({"name": name, "status": status})
            print(f"  ❌ Failed ({status}): {name}")
        
        time.sleep(0.5)  # Rate limiting
    
    print("\n" + "="*60)
    print(f"SUMMARY:")
    print(f"  Wired:                {len(results['wired'])}")
    print(f"  Already had AIFactory: {len(results['already_has_aifactory'])}")
    print(f"  Skipped:              {len(results['skipped'])}")
    print(f"  Failed:               {len(results['failed'])}")
    
    if results["failed"]:
        print("\nFailed repos:")
        for f in results["failed"]:
            print(f"  - {f['name']} (HTTP {f['status']})")
    
    # Save results
    with open("/home/ubuntu/wire_results.json", "w") as f:
        json.dump(results, f, indent=2)
    print("\nFull results saved to /home/ubuntu/wire_results.json")

if __name__ == "__main__":
    main()
