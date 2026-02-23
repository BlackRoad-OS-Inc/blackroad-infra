/**
 * BlackRoad Failover Router
 * ─────────────────────────────────────────────────────────────
 * Tiered origin failover. Tries each tier in order until one
 * responds. Health state cached in KV, refreshed by cron.
 *
 * Tier order:
 *  1. Pi Fleet        — cloudflared tunnel (home hardware, $0)
 *  2. DigitalOcean    — droplet 159.65.43.12 (nginx mirror, ~$6/mo)
 *  3. Vercel          — blackroad-os.vercel.app (free tier)
 *  4. CF Pages        — blackroad-os.pages.dev  (free tier, always on)
 *  5. GitHub Pages    — blackroad-os.github.io  (free tier)
 *  6. Railway         — blackroad-railway.up.railway.app
 *  7. Salesforce      — minimal status page on SF Sites
 */

// ── Origin definitions ────────────────────────────────────────
const ORIGINS = [
  {
    id: "pi-fleet",
    label: "Pi Fleet (primary)",
    url: "https://blackroad.io",          // cloudflared tunnel → nginx on Pi
    healthPath: "/health",
    tier: 1,
  },
  {
    id: "digitalocean",
    label: "DigitalOcean droplet",
    url: "http://159.65.43.12",           // nginx mirror on droplet
    healthPath: "/health",
    tier: 2,
  },
  {
    id: "vercel",
    label: "Vercel",
    url: "https://blackroad-os.vercel.app",
    healthPath: "/",
    tier: 3,
  },
  {
    id: "cf-pages",
    label: "Cloudflare Pages",
    url: "https://blackroad-os.pages.dev",
    healthPath: "/",
    tier: 4,
  },
  {
    id: "github-pages",
    label: "GitHub Pages",
    url: "https://blackroad-os.github.io",
    healthPath: "/",
    tier: 5,
  },
  {
    id: "railway",
    label: "Railway",
    url: "https://blackroad-railway.up.railway.app",
    healthPath: "/health",
    tier: 6,
  },
  {
    id: "salesforce",
    label: "Salesforce Sites",
    url: "https://blackroad.my.salesforce-sites.com",
    healthPath: "/status",
    tier: 7,
  },
];

const KV_TTL   = 120;  // seconds — health state TTL
const PROBE_MS = 4000; // timeout per health probe

// ── Exports ───────────────────────────────────────────────────
export default {
  /**
   * HTTP request handler — route to healthiest tier.
   */
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Internal health endpoint (for monitoring)
    if (url.pathname === "/_br/health") {
      return healthReport(env);
    }

    // Load health state from KV
    const healthState = await loadHealthState(env);

    // Try tiers in order
    for (const origin of ORIGINS) {
      const state = healthState[origin.id];

      // Skip known-down origins (unless all are down)
      if (state === "down") continue;

      try {
        const targetUrl = origin.url + url.pathname + url.search;
        const proxied = await proxyRequest(request, targetUrl);

        if (proxied.ok || proxied.status < 500) {
          // Tag response with which tier served it
          const response = new Response(proxied.body, proxied);
          response.headers.set("X-BlackRoad-Tier", `${origin.tier}:${origin.label}`);
          response.headers.set("X-BlackRoad-Origin", origin.id);

          // If we fell back past tier 1, log it
          if (origin.tier > 1) {
            ctx.waitUntil(logFailover(env, origin, healthState));
          }

          return response;
        }
      } catch (_) {
        // Network error — mark down and try next tier
        ctx.waitUntil(markDown(env, origin.id));
        continue;
      }
    }

    // All tiers failed — serve emergency page
    return emergencyPage();
  },

  /**
   * Cron trigger — run health checks every 2 minutes.
   */
  async scheduled(_event, env, ctx) {
    ctx.waitUntil(runHealthChecks(env));
  },
};

// ── Health check runner ───────────────────────────────────────
async function runHealthChecks(env) {
  const results = await Promise.allSettled(
    ORIGINS.map(async (origin) => {
      const status = await probeOrigin(origin);
      const key = `health:${origin.id}`;
      await env.HEALTH.put(key, status, { expirationTtl: KV_TTL * 10 });
      return { id: origin.id, status };
    })
  );

  // Write summary
  const summary = {};
  for (const r of results) {
    if (r.status === "fulfilled") summary[r.value.id] = r.value.status;
  }
  await env.HEALTH.put("health:summary", JSON.stringify({
    ts: new Date().toISOString(),
    origins: summary,
  }), { expirationTtl: KV_TTL * 10 });

  console.log("[BR-Failover] Health check complete:", JSON.stringify(summary));
}

async function probeOrigin(origin) {
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), PROBE_MS);

    const res = await fetch(origin.url + origin.healthPath, {
      method: "HEAD",
      signal: controller.signal,
      headers: { "User-Agent": "BlackRoad-HealthCheck/1.0" },
    });
    clearTimeout(timer);

    return res.ok || res.status < 500 ? "up" : "down";
  } catch {
    return "down";
  }
}

// ── State helpers ─────────────────────────────────────────────
async function loadHealthState(env) {
  try {
    const raw = await env.HEALTH.get("health:summary");
    if (!raw) return {};
    const data = JSON.parse(raw);
    return data.origins || {};
  } catch {
    return {};
  }
}

async function markDown(env, originId) {
  await env.HEALTH.put(`health:${originId}`, "down", { expirationTtl: KV_TTL });
}

async function logFailover(env, origin, state) {
  const log = {
    ts: new Date().toISOString(),
    serving: origin.id,
    tier: origin.tier,
    state,
  };
  await env.HEALTH.put("failover:last", JSON.stringify(log), {
    expirationTtl: 86400,
  });
}

// ── Proxy helper ──────────────────────────────────────────────
async function proxyRequest(request, targetUrl) {
  const proxied = new Request(targetUrl, {
    method: request.method,
    headers: request.headers,
    body: ["GET", "HEAD"].includes(request.method) ? undefined : request.body,
    redirect: "follow",
  });
  return fetch(proxied, { signal: AbortSignal.timeout(8000) });
}

// ── Health report page ────────────────────────────────────────
async function healthReport(env) {
  const raw = await env.HEALTH.get("health:summary").catch(() => null);
  const summary = raw ? JSON.parse(raw) : { ts: "never", origins: {} };
  const last = await env.HEALTH.get("failover:last").catch(() => null);

  const rows = ORIGINS.map((o) => {
    const st = summary.origins[o.id] || "unknown";
    const icon = st === "up" ? "🟢" : st === "down" ? "🔴" : "⚪";
    return `<tr><td>${icon}</td><td>Tier ${o.tier}</td><td>${o.label}</td><td>${o.url}</td><td>${st}</td></tr>`;
  }).join("");

  const html = `<!DOCTYPE html>
<html>
<head><title>BlackRoad Failover Status</title>
<style>
  body{font-family:monospace;background:#000;color:#fff;padding:2rem}
  h1{color:#FF1D6C}
  table{border-collapse:collapse;width:100%}
  th,td{padding:8px 12px;border:1px solid #333;text-align:left}
  th{background:#111;color:#F5A623}
  .ts{color:#666;font-size:.8em}
</style>
</head>
<body>
  <h1>⚡ BlackRoad Failover Status</h1>
  <p class="ts">Last check: ${summary.ts} | ${last ? "Last failover: " + JSON.parse(last).ts : "No failovers recorded"}</p>
  <table>
    <tr><th></th><th>Tier</th><th>Name</th><th>URL</th><th>Status</th></tr>
    ${rows}
  </table>
</body>
</html>`;

  return new Response(html, {
    headers: { "Content-Type": "text/html;charset=UTF-8" },
  });
}

// ── Emergency fallback page ───────────────────────────────────
function emergencyPage() {
  return new Response(
    `<!DOCTYPE html>
<html>
<head><title>BlackRoad — Maintenance</title>
<style>
  body{font-family:system-ui;background:#000;color:#fff;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;flex-direction:column}
  h1{color:#FF1D6C;font-size:3rem;margin:0}
  p{color:#888;margin-top:1rem}
  a{color:#F5A623}
</style>
</head>
<body>
  <h1>⚡ BlackRoad OS</h1>
  <p>All systems are temporarily offline. We'll be back shortly.</p>
  <p><a href="https://github.com/BlackRoad-OS">@BlackRoad-OS on GitHub</a></p>
</body>
</html>`,
    { status: 503, headers: { "Content-Type": "text/html;charset=UTF-8", "Retry-After": "60" } }
  );
}
