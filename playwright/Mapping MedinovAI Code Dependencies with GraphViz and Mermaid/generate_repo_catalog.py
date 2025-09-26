import os
import json
import subprocess
import csv

def run_command(cmd, cwd=None):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=cwd)
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except Exception as e:
        return "", str(e), 1

def analyze_repo(repo_path):
    repo_name = os.path.basename(repo_path)
    analysis = {
        'repo_name': repo_name,
        'size_kb': 0,
        'languages': {},
        'file_count': 0,
        'build_systems': [],
        'has_dockerfile': False,
        'has_k8s': False,
        'has_ci': False,
        'license': 'unknown',
        'last_commit': 'unknown',
        'default_branch': 'unknown',
    }
    
    if not os.path.exists(repo_path):
        return analysis
    
    stdout, _, _ = run_command(f"du -sk {repo_path}")
    if stdout:
        analysis['size_kb'] = int(stdout.split()[0])
    
    stdout, _, _ = run_command(f"find {repo_path} -type f | wc -l")
    if stdout:
        analysis['file_count'] = int(stdout)
    
    stdout, _, _ = run_command(f"cloc --json {repo_path}")
    if stdout:
        try:
            cloc_data = json.loads(stdout)
            for lang, data in cloc_data.items():
                if lang not in ['header', 'SUM']:
                    analysis['languages'][lang] = data.get('nFiles', 0)
        except:
            pass
    
    build_files = {
        'package.json': 'npm',
        'requirements.txt': 'pip',
        'setup.py': 'pip',
        'pyproject.toml': 'pip',
        'Pipfile': 'pipenv',
        'poetry.lock': 'poetry',
        'pom.xml': 'maven',
        'build.gradle': 'gradle',
        'Makefile': 'make',
        'CMakeLists.txt': 'cmake',
        'Dockerfile': 'docker',
        'docker-compose.yml': 'docker-compose',
        'composer.json': 'composer',
        '*.csproj': 'dotnet',
        '*.sln': 'msbuild'
    }
    
    for root, dirs, files in os.walk(repo_path):
        for file in files:
            if file in build_files and build_files[file] not in analysis['build_systems']:
                analysis['build_systems'].append(build_files[file])
            if file == 'Dockerfile':
                analysis['has_dockerfile'] = True
            if file.endswith(('.yml', '.yaml')) and ('k8s' in file.lower() or 'kubernetes' in file.lower()):
                analysis['has_k8s'] = True
        if '.github' in dirs:
            analysis['has_ci'] = True

    stdout, _, _ = run_command("git log -1 --format='%ci'", cwd=repo_path)
    if stdout:
        analysis['last_commit'] = stdout.split(' ')[0]
    
    stdout, _, _ = run_command("git rev-parse --abbrev-ref HEAD", cwd=repo_path)
    if stdout:
        analysis['default_branch'] = stdout

    return analysis

repos_dir = "/home/ubuntu/repos"
catalog = []
for repo_dir in os.listdir(repos_dir):
    repo_path = os.path.join(repos_dir, repo_dir)
    if os.path.isdir(repo_path):
        catalog.append(analyze_repo(repo_path))

with open('repo_catalog.csv', 'w', newline='') as csvfile:
    fieldnames = ['org/repo', 'size_kb', 'languages', 'file_count', 'build_systems', 'has_dockerfile', 'has_k8s', 'has_ci', 'license', 'last_commit', 'default_branch']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    for repo in catalog:
        writer.writerow({
            'org/repo': f"myonsite-healthcare/{repo['repo_name']}",
            'size_kb': repo['size_kb'],
            'languages': ', '.join([f"{lang}({count})" for lang, count in repo['languages'].items()]),
            'file_count': repo['file_count'],
            'build_systems': ', '.join(repo['build_systems']),
            'has_dockerfile': repo['has_dockerfile'],
            'has_k8s': repo['has_k8s'],
            'has_ci': repo['has_ci'],
            'license': repo['license'],
            'last_commit': repo['last_commit'],
            'default_branch': repo['default_branch']
        })

print(f"Repository catalog created: repo_catalog.csv")

