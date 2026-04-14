/**
 * /api/modules — Platform Module Status
 * MedinovAI Command Center v3.0
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Returns live status of all 190+ MedinovAI platform modules
 * by reading from medinovai-platform-brain and medinovai-Deploy.
 */

import { NextRequest, NextResponse } from 'next/server';

const E_BRAIN_REPO = 'medinovai-health/medinovai-platform-brain';
const E_CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

let mos_moduleCache: { data: unknown; cachedAt: number } | null = null;

async function fetchModuleIndex(): Promise<unknown[]> {
  // Check cache
  if (mos_moduleCache && Date.now() - mos_moduleCache.cachedAt < E_CACHE_TTL_MS) {
    return mos_moduleCache.data as unknown[];
  }

  try {
    const mos_res = await fetch(
      `https://api.github.com/repos/${E_BRAIN_REPO}/contents/agent-knowledge/MODULE_INDEX.json`,
      {
        headers: {
          Authorization: `token ${process.env.GITHUB_TOKEN}`,
          Accept: 'application/vnd.github.v3+json',
        },
      }
    );

    if (!mos_res.ok) throw new Error(`GitHub API error: ${mos_res.status}`);

    const mos_data = await mos_res.json();
    const mos_content = JSON.parse(
      Buffer.from(mos_data.content, 'base64').toString('utf-8')
    );

    mos_moduleCache = { data: mos_content, cachedAt: Date.now() };
    return mos_content as unknown[];
  } catch (mos_error) {
    console.error('[Modules API] Failed to fetch module index:', mos_error);
    return [];
  }
}

export async function GET(req: NextRequest) {
  const mos_filter = req.nextUrl.searchParams.get('filter');
  const mos_tier = req.nextUrl.searchParams.get('tier');

  const mos_modules = await fetchModuleIndex();

  let mos_filtered = mos_modules;

  if (mos_filter) {
    const mos_filterLower = mos_filter.toLowerCase();
    mos_filtered = mos_filtered.filter((m: unknown) => {
      const mod = m as Record<string, unknown>;
      return (
        String(mod.name || '').toLowerCase().includes(mos_filterLower) ||
        String(mod.id || '').toLowerCase().includes(mos_filterLower) ||
        String(mod.description || '').toLowerCase().includes(mos_filterLower)
      );
    });
  }

  if (mos_tier) {
    mos_filtered = mos_filtered.filter((m: unknown) => {
      const mod = m as Record<string, unknown>;
      return String(mod.tier) === mos_tier;
    });
  }

  return NextResponse.json({
    modules: mos_filtered,
    total: mos_modules.length,
    filtered: mos_filtered.length,
    cachedAt: mos_moduleCache?.cachedAt
      ? new Date(mos_moduleCache.cachedAt).toISOString()
      : null,
    timestamp: new Date().toISOString(),
  });
}
