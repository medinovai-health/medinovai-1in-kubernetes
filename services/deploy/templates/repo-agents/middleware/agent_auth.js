/**
 * AtlasOS Agent Auth Middleware for Express.
 *
 * Validates X-AtlasOS-Agent-Id header against RBAC Guard.
 * Logs agent actions. Returns 401 when auth is required and validation fails.
 *
 * Environment:
 *   AGENT_AUTH_REQUIRED    - If 'true', reject requests without valid agent ID (default: false)
 *   ATLASOS_RBAC_GUARD_URL - Base URL for RBAC Guard validation (e.g. http://rbac-guard:8080)
 *   ATLASOS_AGENT_ID       - Optional; allow bypass when header matches this (dev/single-agent)
 */

const AGENT_HEADER = "X-AtlasOS-Agent-Id";
const VALID_AGENT_ID_REGEX = /^[a-zA-Z0-9][a-zA-Z0-9_-]{0,62}$/;

const AGENT_AUTH_REQUIRED =
  (process.env.AGENT_AUTH_REQUIRED || "false").toLowerCase() in ["true", "1", "yes"];
const RBAC_GUARD_URL = (process.env.ATLASOS_RBAC_GUARD_URL || "").replace(/\/+$/, "");
const BYPASS_AGENT_ID = process.env.ATLASOS_AGENT_ID || "";

function isValidAgentIdFormat(agentId) {
  return agentId && VALID_AGENT_ID_REGEX.test(agentId);
}

async function validateAgentWithRbac(agentId) {
  if (!RBAC_GUARD_URL) {
    console.warn("ATLASOS_RBAC_GUARD_URL not set; skipping RBAC validation");
    return true;
  }

  const url = `${RBAC_GUARD_URL}/api/v1/agents/validate?agent_id=${encodeURIComponent(agentId)}`;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timeout);

    if (res.status === 200) {
      const data = await res.json();
      return !!data.authorized;
    }
    console.warn(
      `RBAC Guard returned ${res.status} for agent ${agentId}: ${(await res.text()).slice(0, 200)}`
    );
    return false;
  } catch (err) {
    console.error(`RBAC Guard unreachable for agent ${agentId}:`, err.message);
    return false;
  }
}

function logAgentAction(req, agentId, statusCode) {
  const method = req.method || "";
  const path = req.path || req.url || "";
  console.log(
    JSON.stringify({
      level: "info",
      msg: "agent_action",
      agent_id: agentId,
      method,
      path,
      status: statusCode,
    })
  );
}

const SKIP_PATHS = new Set(["/agent/health", "/agent/status", "/health", "/ready"]);

function agentAuthMiddleware(req, res, next) {
  const agentId = (req.get(AGENT_HEADER) || "").trim();
  const path = req.path || req.originalUrl?.split("?")[0] || "";

  if (SKIP_PATHS.has(path)) {
    return next();
  }

  if (BYPASS_AGENT_ID && agentId === BYPASS_AGENT_ID) {
    res.on("finish", () => logAgentAction(req, agentId, res.statusCode));
    return next();
  }

  if (!agentId) {
    if (AGENT_AUTH_REQUIRED) {
      console.warn(`Rejected request: missing ${AGENT_HEADER}`);
      return res.status(401).json({
        error: "unauthorized",
        message: `Missing required header: ${AGENT_HEADER}`,
      });
    }
    return next();
  }

  if (!isValidAgentIdFormat(agentId)) {
    if (AGENT_AUTH_REQUIRED) {
      console.warn(`Rejected request: invalid agent ID format: ${agentId.slice(0, 20)}`);
      return res.status(401).json({
        error: "unauthorized",
        message: "Invalid agent ID format",
      });
    }
    return next();
  }

  validateAgentWithRbac(agentId)
    .then((authorized) => {
      if (!authorized && AGENT_AUTH_REQUIRED) {
        console.warn(`Rejected request: agent ${agentId} not authorized by RBAC`);
        return res.status(401).json({
          error: "unauthorized",
          message: "Agent not authorized",
        });
      }
      res.on("finish", () => logAgentAction(req, agentId, res.statusCode));
      next();
    })
    .catch((err) => {
      console.error("Agent auth validation error:", err);
      if (AGENT_AUTH_REQUIRED) {
        return res.status(503).json({
          error: "service_unavailable",
          message: "Agent validation service unavailable",
        });
      }
      next();
    });
}

module.exports = agentAuthMiddleware;
