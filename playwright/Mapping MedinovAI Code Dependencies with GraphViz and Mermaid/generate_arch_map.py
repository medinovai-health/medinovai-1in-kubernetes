import os
import re

def analyze_dependencies(repo_path):
    print(f"Analyzing {repo_path}")
    dependencies = {
        "services": set(),
        "databases": set(),
        "external": set(),
        "topics": set(),
    }
    for root, _, files in os.walk(repo_path):
        for file in files:
            file_path = os.path.join(root, file)
            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                    if re.search(r"service|api|client", file, re.IGNORECASE):
                        service_name = os.path.basename(repo_path).replace("-", "_")
                        dependencies["services"].add(service_name)
                    if re.search(r"db|database|sql|mongo|redis|postgres", content, re.IGNORECASE):
                        dependencies["databases"].add("Database")
                    if re.search(r"EHR|LIS|Mirth|Vtiger|3CX|payment|email", content, re.IGNORECASE):
                        dependencies["external"].add("External Systems")
                    if re.search(r"kafka|rabbitmq|queue|topic|publish|subscribe", content, re.IGNORECASE):
                        dependencies["topics"].add("Message Queue")
            except Exception as e:
                print(f"Error reading {file_path}: {e}")
    return dependencies

def generate_mermaid_diagram(repos_dir):
    print(f"Generating diagram for repos in {repos_dir}")
    all_dependencies = {}
    for repo_name in os.listdir(repos_dir):
        repo_path = os.path.join(repos_dir, repo_name)
        if os.path.isdir(repo_path):
            all_dependencies[repo_name] = analyze_dependencies(repo_path)

    mermaid_string = "graph TD\n"
    mermaid_string += "    subgraph MedinovAI Architecture\n"
    for repo_name, deps in all_dependencies.items():
        service_name = repo_name.replace("-", "_")
        if service_name:
            mermaid_string += f"        {service_name}[{repo_name}]\n"
    for repo_name, deps in all_dependencies.items():
        service_name = repo_name.replace("-", "_")
        if "Database" in deps["databases"]:
            mermaid_string += f"        {service_name} --> Database[(Database)]\n"
        if "External Systems" in deps["external"]:
            mermaid_string += f"        {service_name} --> External_Systems[External Systems]\n"
        if "Message Queue" in deps["topics"]:
            mermaid_string += f"        {service_name} --> Message_Queue[Message Queue]\n"
    mermaid_string += "    end"
    return mermaid_string

if __name__ == "__main__":
    print("Starting script")
    repos_directory = "/home/ubuntu/repos"
    mermaid_code = generate_mermaid_diagram(repos_directory)
    print("Generated mermaid code:")
    print(mermaid_code)
    with open("arch_map.md", "w") as f:
        f.write("# MedinovAI Architecture Map\n\n")
        f.write("## High-Level Service Architecture\n\n")
        f.write("```mermaid\n")
        f.write(mermaid_code)
        f.write("```\n")
    print("Architecture map generated: arch_map.md")

