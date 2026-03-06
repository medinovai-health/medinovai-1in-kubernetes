/**
 * AtlasOS Agent Health Routes for Express.
 *
 * Exposes GET /agent/status and GET /agent/health for agent discovery and health checks.
 *
 * Environment:
 *   AGENT_STATE_FILE - Path to JSON state file (default: ./state/agent_state.json)
 *   AGENT_ID         - Agent identifier (fallback when state file absent)
 *   AGENT_NAME       - Human-readable agent name
 *   AGENT_VERSION    - Agent version string
 *   AGENT_CAPABILITIES - Comma-separated capabilities (optional)
 */

const fs = require("fs");
const path = require("path");

const AGENT_STATE_FILE = process.env.AGENT_STATE_FILE || "state/agent_state.json";
const AGENT_ID = process.env.AGENT_ID || "";
const AGENT_NAME = process.env.AGENT_NAME || "AtlasOS Agent";
const AGENT_VERSION = process.env.AGENT_VERSION || "1.0.0";
const AGENT_CAPABILITIES = (process.env.AGENT_CAPABILITIES || "")
  .split(",")
  .map((c) => c.trim())
  .filter(Boolean);

function loadState() {
  const fp = path.isAbsolute(AGENT_STATE_FILE)
    ? AGENT_STATE_FILE
    : path.join(process.cwd(), AGENT_STATE_FILE);
  if (!fs.existsSync(fp)) return {};
  try {
    return JSON.parse(fs.readFileSync(fp, "utf8"));
  } catch {
    return {};
  }
}

function agentInfo() {
  const state = loadState();
  return {
    agent_id: state.agent_id || AGENT_ID || "unknown",
    name: state.name || AGENT_NAME,
    version: state.version || AGENT_VERSION,
    capabilities: state.capabilities || AGENT_CAPABILITIES,
    status: state.status || "operational",
    last_heartbeat: state.last_heartbeat,
    started_at: state.started_at,
  };
}

/**
 * GET /agent/status - Agent info for discovery/registry
 */
function getAgentStatus(req, res) {
  const info = agentInfo();
  info.timestamp = new Date().toISOString();
  res.json(info);
}

/**
 * GET /agent/health - Health check for load balancers
 */
function getAgentHealth(req, res) {
  const info = agentInfo();
  const status = info.status || "operational";
  const healthy = ["operational", "ready", "running"].includes(status);

  res.json({
    status: healthy ? "healthy" : "degraded",
    agent_id: info.agent_id,
    version: info.version,
    timestamp: new Date().toISOString(),
    details: {
      operational_status: status,
      capabilities_count: (info.capabilities || []).length,
    },
  });
}

/**
 * Mount agent health routes on an Express app or router.
 * @param {import('express').Router|import('express').Application} app - Express app or router
 */
function mountAgentHealthRoutes(app) {
  app.get("/agent/status", getAgentStatus);
  app.get("/agent/health", getAgentHealth);
}

module.exports = {
  getAgentStatus,
  getAgentHealth,
  mountAgentHealthRoutes,
};
