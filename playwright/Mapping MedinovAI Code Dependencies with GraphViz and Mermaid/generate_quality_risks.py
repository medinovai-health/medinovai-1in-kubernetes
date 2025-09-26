import os
import subprocess
import json

def run_scan(command, cwd):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, cwd=cwd)
        return result.stdout.strip()
    except Exception as e:
        return f"Error running scan: {e}"

def generate_quality_risks(repos_dir):
    risks = {
        'Performance': [],
        'Stability': [],
        'Security': [],
        'Privacy & Compliance': [],
        'Operability': []
    }

    for repo_name in os.listdir(repos_dir):
        repo_path = os.path.join(repos_dir, repo_name)
        if not os.path.isdir(repo_path):
            continue

        # Security scan with bandit for Python repos
        if os.path.exists(os.path.join(repo_path, 'requirements.txt')) or os.path.exists(os.path.join(repo_path, 'setup.py')):
            print(f"Running bandit on {repo_name}")
            bandit_output = run_scan(f'/home/ubuntu/analysis_env/bin/bandit -r . -f json', repo_path)
            if bandit_output:
                try:
                    bandit_results = json.loads(bandit_output)
                    for issue in bandit_results.get('results', []):
                        risks['Security'].append(f"**{repo_name}**: {issue['issue_text']} in `{issue['filename']}` (line {issue['line_number']}) - Confidence: {issue['issue_confidence']}")
                except json.JSONDecodeError:
                    print(f"Error parsing bandit output for {repo_name}")

        # Generic static analysis with semgrep
        print(f"Running semgrep on {repo_name}")
        semgrep_output = run_scan(f'/home/ubuntu/analysis_env/bin/semgrep scan --config auto --json', repo_path)
        if semgrep_output:
            try:
                semgrep_results = json.loads(semgrep_output)
                for result in semgrep_results.get('results', []):
                    risks['Security'].append(f"**{repo_name}**: {result['extra']['message']} in `{result['path']}` (lines {result['start']['line']}-{result['end']['line']})")
            except json.JSONDecodeError:
                print(f"Error parsing semgrep output for {repo_name}")

    with open('quality_risks.md', 'w') as f:
        f.write('# Quality and Risk Analysis\n\n')
        for category, items in risks.items():
            f.write(f'## {category}\n\n')
            if items:
                for item in items:
                    f.write(f'- {item}\n')
            else:
                f.write('No significant risks identified in this category.\n')
            f.write('\n')

    print('quality_risks.md generated successfully.')

if __name__ == '__main__':
    generate_quality_risks('/home/ubuntu/repos')

