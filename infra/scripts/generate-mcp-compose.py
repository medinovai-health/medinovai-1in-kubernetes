#!/usr/bin/env python3
"""
generate-mcp-compose.py
──────────────────────────────────────────────────────────────────────────────
Reads CONNECTOR_REGISTRY.yml from the AtlasOS repo and generates the MCP
connector section of docker-compose.ceo.yml.

Usage:
    python3 infra/scripts/generate-mcp-compose.py [OPTIONS]

Options:
    --registry PATH    Path to CONNECTOR_REGISTRY.yml
                       (default: $ATLASOS_PATH/services/mcp-connectors/CONNECTOR_REGISTRY.yml)
    --compose PATH     Path to docker-compose.ceo.yml to update
                       (default: infra/docker/docker-compose.ceo.yml)
    --status FILTER    Only include connectors with this status (default: stable)
                       Use "all" to include planned connectors too
    --dry-run          Print generated YAML without writing to file
    --list             List all connectors in registry and exit

The script replaces the section between:
    # ─── MCP Connectors ──
    ...
    # ─── PDF Processing ──
in docker-compose.ceo.yml with freshly generated content.
──────────────────────────────────────────────────────────────────────────────
"""

import argparse
import os
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml not installed. Run: pip3 install pyyaml", file=sys.stderr)
    sys.exit(1)

COMPOSE_MCP_START = "  # ─── MCP Connectors ─"
COMPOSE_MCP_END = "  # ─── PDF Processing ─"

MCP_SECTION_HEADER = """\
  # ─── MCP Connectors ───────────────────────────────────────────────────
  # AUTO-GENERATED — do not edit this section manually.
  # To add or modify connectors, edit:
  #   {registry_path}
  # Then regenerate:
  #   make generate-mcp-compose
  #
  # Status: {status_filter} connectors only
  # Generated: {timestamp}
  #
  # Port map:
{port_map}
  #
  # Internal URLs used by intelligence services:
{url_map}
"""


def load_registry(registry_path: Path) -> list[dict]:
    """Load and parse CONNECTOR_REGISTRY.yml."""
    if not registry_path.exists():
        print(f"ERROR: Registry not found at {registry_path}", file=sys.stderr)
        sys.exit(1)
    with open(registry_path) as f:
        data = yaml.safe_load(f)
    return data.get("connectors", [])


def filter_connectors(connectors: list[dict], status_filter: str) -> list[dict]:
    """Filter connectors by status."""
    if status_filter == "all":
        return connectors
    statuses = status_filter.split(",")
    return [c for c in connectors if c.get("status", "planned") in statuses]


def generate_service_block(connector: dict, vault_token_var: str = "${VAULT_DEV_ROOT_TOKEN_ID:-medinovai-dev-token}") -> str:
    """Generate a docker-compose service block for a connector."""
    cid = connector["id"]
    name = connector["name"]
    port = connector["port"]
    container = connector.get("container_name", f"ceo-mcp-{cid}")
    connector_dir = connector.get("connector_dir", cid)
    vault_path = connector["vault_path"]
    status = connector.get("status", "stable")
    description = connector.get("description", "")
    tools = connector.get("tools", [])

    tools_comment = ", ".join(tools) if tools else ""

    block = f"""\
  mcp-{cid}:
    # {name} — {description}
    # Status: {status} | Tools: {tools_comment}
    build:
      context: ${{ATLASOS_PATH:-../../repos/AtlasOS}}/services/mcp-connectors
      dockerfile: Dockerfile
      args:
        CONNECTOR_NAME: {connector_dir}
    container_name: {container}
    ports:
      - "{port}:8080"
    environment:
      PORT: "8080"
      VAULT_ADDR: http://vault:8200
      VAULT_TOKEN: {vault_token_var}
      VAULT_SECRET_PATH: {vault_path}
      AUDIT_SERVICE_URL: http://audit-chain:8084
      CONNECTOR_NAME: {connector_dir}
    depends_on:
      vault:
        condition: service_healthy
      audit-chain:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 15s
    restart: unless-stopped
    networks:
      - ceo-network
"""
    return block


def generate_mcp_section(connectors: list[dict], registry_path: Path, status_filter: str) -> str:
    """Generate the complete MCP connectors section."""
    from datetime import datetime, timezone

    port_lines = []
    url_lines = []
    for c in connectors:
        cid = c["id"]
        port = c["port"]
        name = c["name"]
        port_lines.append(f"  #   {name:<30} host:{port} → container:8080")
        url_lines.append(f"  #   http://mcp-{cid}:8080")

    port_map = "\n".join(port_lines)
    url_map = "\n".join(url_lines)

    header = MCP_SECTION_HEADER.format(
        registry_path=registry_path,
        status_filter=status_filter,
        timestamp=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC"),
        port_map=port_map,
        url_map=url_map,
    )

    service_blocks = "\n".join(generate_service_block(c) for c in connectors)
    return header + "\n" + service_blocks


def update_compose_file(compose_path: Path, mcp_section: str, dry_run: bool) -> None:
    """Replace the MCP Connectors section in docker-compose.ceo.yml."""
    content = compose_path.read_text()

    # Find the markers
    start_idx = content.find(COMPOSE_MCP_START)
    end_idx = content.find(COMPOSE_MCP_END)

    if start_idx == -1 or end_idx == -1:
        print("ERROR: Could not find MCP section markers in compose file.", file=sys.stderr)
        print(f"  Looking for: '{COMPOSE_MCP_START}'", file=sys.stderr)
        print(f"       and:   '{COMPOSE_MCP_END}'", file=sys.stderr)
        sys.exit(1)

    new_content = content[:start_idx] + mcp_section + "\n" + content[end_idx:]

    if dry_run:
        print("=== DRY RUN — Generated MCP section ===")
        print(mcp_section)
        return

    # Backup original
    backup_path = compose_path.with_suffix(".yml.bak")
    backup_path.write_text(content)
    compose_path.write_text(new_content)
    print(f"Updated: {compose_path}")
    print(f"Backup:  {backup_path}")


def print_connector_list(connectors: list[dict]) -> None:
    """Print a formatted table of connectors."""
    print(f"\n{'ID':<25} {'NAME':<30} {'STATUS':<10} {'PORT':<8} {'TOOLS'}")
    print("-" * 100)
    for c in connectors:
        tools = ", ".join(c.get("tools", []))
        print(f"{c['id']:<25} {c['name']:<30} {c.get('status','?'):<10} {c['port']:<8} {tools}")
    print()


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate MCP connector compose blocks from registry")
    parser.add_argument("--registry", help="Path to CONNECTOR_REGISTRY.yml")
    parser.add_argument("--compose", default="infra/docker/docker-compose.ceo.yml", help="Path to compose file")
    parser.add_argument("--status", default="stable", help="Status filter: stable|beta|scaffold|planned|all (comma-separated)")
    parser.add_argument("--dry-run", action="store_true", help="Print without writing")
    parser.add_argument("--list", action="store_true", help="List all connectors and exit")
    args = parser.parse_args()

    # Resolve registry path
    if args.registry:
        registry_path = Path(args.registry)
    else:
        atlasos_path = os.environ.get(
            "ATLASOS_PATH",
            str(Path(__file__).resolve().parents[3] / "medinovai-Atlas"),
        )
        registry_path = Path(atlasos_path) / "services" / "mcp-connectors" / "CONNECTOR_REGISTRY.yml"

    all_connectors = load_registry(registry_path)

    if args.list:
        print_connector_list(all_connectors)
        print(f"Total: {len(all_connectors)} connectors")
        by_status: dict = {}
        for c in all_connectors:
            s = c.get("status", "?")
            by_status[s] = by_status.get(s, 0) + 1
        for s, count in sorted(by_status.items()):
            print(f"  {s}: {count}")
        return

    active_connectors = filter_connectors(all_connectors, args.status)
    if not active_connectors:
        print(f"No connectors match status filter '{args.status}'", file=sys.stderr)
        sys.exit(1)

    print(f"Generating compose blocks for {len(active_connectors)} '{args.status}' connector(s)...")

    mcp_section = generate_mcp_section(active_connectors, registry_path, args.status)

    compose_path = Path(args.compose)
    if not compose_path.is_absolute():
        # Try relative to repo root
        repo_root = Path(__file__).resolve().parents[2]
        compose_path = repo_root / compose_path

    update_compose_file(compose_path, mcp_section, args.dry_run)

    if not args.dry_run:
        print(f"\nConnectors generated:")
        for c in active_connectors:
            print(f"  mcp-{c['id']:<25} port {c['port']}  ({c['name']})")
        print(f"\nNext steps:")
        print(f"  1. Rebuild containers:  make ceo-stack-rebuild")
        print(f"  2. Seed credentials:    ./infra/scripts/seed-vault-credentials.sh all")
        print(f"  3. Verify health:       make mcp-status")


if __name__ == "__main__":
    main()
