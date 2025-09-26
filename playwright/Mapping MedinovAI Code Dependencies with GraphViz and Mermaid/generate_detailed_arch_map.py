import os
import re
import json

def analyze_repo_dependencies(repo_path):
    dependencies = {
        'services': set(),
        'databases': set(),
        'external': set(),
        'topics': set(),
        'connections': set()
    }
    repo_name = os.path.basename(repo_path)

    for root, _, files in os.walk(repo_path):
        for file in files:
            file_path = os.path.join(root, file)
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()

                    # Simplified service detection from file names
                    if re.search(r'service|api|client|controller', file, re.IGNORECASE):
                        service_name = os.path.splitext(file)[0].replace('-', '_')
                        dependencies['services'].add(service_name)
                        dependencies['connections'].add((repo_name.replace('-', '_'), service_name))

                    # Database usage
                    if re.search(r'db|database|sql|mongo|redis|postgres', content, re.IGNORECASE):
                        dependencies['databases'].add('Database')
                        dependencies['connections'].add((repo_name.replace('-', '_'), 'Database'))

                    # External integrations
                    if re.search(r'EHR|LIS|Mirth|Vtiger|3CX|payment|email', content, re.IGNORECASE):
                        dependencies['external'].add('External_Systems')
                        dependencies['connections'].add((repo_name.replace('-', '_'), 'External_Systems'))

                    # Message queues/topics
                    if re.search(r'kafka|rabbitmq|queue|topic|publish|subscribe', content, re.IGNORECASE):
                        dependencies['topics'].add('Message_Queue')
                        dependencies['connections'].add((repo_name.replace('-', '_'), 'Message_Queue'))

            except Exception as e:
                print(f"Error reading {file_path}: {e}")

    return dependencies

def generate_mermaid_diagram(repos_dir):
    all_dependencies = {}
    for repo_name in os.listdir(repos_dir):
        repo_path = os.path.join(repos_dir, repo_name)
        if os.path.isdir(repo_path):
            all_dependencies[repo_name] = analyze_repo_dependencies(repo_path)

    mermaid_string = 'graph TD\n'
    mermaid_string += '    subgraph MedinovAI Service Ecosystem\n'

    # Define nodes for repos and major components
    for repo_name in all_dependencies:
        mermaid_string += f'        {repo_name.replace("-", "_")}[{repo_name}]\n'
    mermaid_string += '        Database[(Database)]\n'
    mermaid_string += '        External_Systems[External Systems]\n'
    mermaid_string += '        Message_Queue[Message Queue]\n'

    # Add connections
    for repo_name, deps in all_dependencies.items():
        for source, target in deps['connections']:
            mermaid_string += f'        {source} --> {target}\n'

    mermaid_string += '    end\n'
    return mermaid_string

if __name__ == '__main__':
    repos_directory = '/home/ubuntu/repos'
    mermaid_code = generate_mermaid_diagram(repos_directory)
    with open('arch_map.md', 'w') as f:
        f.write('# MedinovAI Architecture Map\n\n')
        f.write('## Detailed Service and Dependency Map\n\n')
        f.write('```mermaid\n')
        f.write(mermaid_code)
        f.write('```\n')
    print('Detailed architecture map generated: arch_map.md')

