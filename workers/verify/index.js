/**
 * verify.blackroad.io — Information Verification Worker
 * Routes:
 *   GET  /          → Brand landing page (JSON)
 *   GET  /?ui=1     → HTML verification UI
 *   POST /verify    → Forward claim to BlackRoad gateway /v1/verify
 *   GET  /health    → Health check
 */

const BRAND = {
  name: 'BlackRoad Verify',
  version: '1.0.0',
  description: 'AI-powered information verification powered by BlackRoad OS',
}

const HTML_UI = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>BlackRoad Verify</title>
  <style>
    :root {
      --black: #000000;
      --white: #FFFFFF;
      --amber: #F5A623;
      --hot-pink: #FF1D6C;
      --electric-blue: #2979FF;
      --violet: #9C27B0;
      --gradient: linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #000;
      color: #fff;
      font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 48px 16px;
    }
    .logo {
      width: 56px; height: 56px;
      border-radius: 16px;
      background: var(--gradient);
      display: flex; align-items: center; justify-content: center;
      font-size: 28px; font-weight: 700; color: #fff;
      margin-bottom: 16px;
    }
    h1 { font-size: 2rem; font-weight: 700; margin-bottom: 4px; }
    h1 span { background: var(--gradient); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .subtitle { color: #666; margin-bottom: 48px; font-size: 0.95rem; }
    .card {
      width: 100%; max-width: 640px;
      background: #111;
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 16px;
      padding: 32px;
    }
    label { display: block; font-size: 0.85rem; color: #888; margin-bottom: 8px; }
    textarea {
      width: 100%; min-height: 100px;
      background: #000; border: 1px solid rgba(255,255,255,0.15);
      border-radius: 10px; color: #fff; font-size: 0.95rem;
      padding: 12px; resize: vertical; font-family: inherit;
    }
    textarea:focus { outline: none; border-color: #FF1D6C; }
    .row { display: flex; gap: 12px; margin-top: 16px; align-items: center; }
    input[type=number] {
      background: #000; border: 1px solid rgba(255,255,255,0.15);
      border-radius: 8px; color: #fff; padding: 10px 12px;
      width: 120px; font-size: 0.9rem;
    }
    input[type=number]:focus { outline: none; border-color: #FF1D6C; }
    button {
      flex: 1; padding: 12px 24px;
      background: linear-gradient(135deg, #FF1D6C, #9C27B0);
      border: none; border-radius: 10px;
      color: #fff; font-size: 0.95rem; font-weight: 600;
      cursor: pointer; transition: opacity 0.2s;
    }
    button:hover { opacity: 0.85; }
    button:disabled { opacity: 0.4; cursor: not-allowed; }
    .result { margin-top: 28px; display: none; }
    .verdict-badge {
      display: inline-block; padding: 4px 14px;
      border-radius: 20px; font-size: 0.8rem; font-weight: 700;
      text-transform: uppercase; letter-spacing: 0.05em;
      margin-bottom: 12px;
    }
    .verdict-true    { background: #052e16; color: #4ade80; border: 1px solid #4ade80; }
    .verdict-false   { background: #450a0a; color: #f87171; border: 1px solid #f87171; }
    .verdict-unverified { background: #422006; color: #fbbf24; border: 1px solid #fbbf24; }
    .verdict-conflicting { background: #431407; color: #fb923c; border: 1px solid #fb923c; }
    .confidence-bar { background: #222; border-radius: 6px; height: 8px; margin: 8px 0 16px; }
    .confidence-fill {
      height: 100%; border-radius: 6px;
      background: var(--gradient); transition: width 0.5s ease;
    }
    .reasoning { color: #ccc; font-size: 0.9rem; line-height: 1.618; }
    .flags { margin-top: 12px; }
    .flag { display: inline-block; background: #1a1a1a; border: 1px solid #333; border-radius: 6px; padding: 3px 10px; font-size: 0.8rem; color: #888; margin: 3px 3px 0 0; }
    .meta { color: #444; font-size: 0.75rem; margin-top: 16px; }
    .error-msg { color: #f87171; font-size: 0.9rem; margin-top: 16px; display: none; }
  </style>
</head>
<body>
  <div class="logo">✓</div>
  <h1>BlackRoad <span>Verify</span></h1>
  <p class="subtitle">AI-powered claim verification · Powered by PRISM &amp; CIPHER agents</p>

  <div class="card">
    <label for="claim">Claim to verify</label>
    <textarea id="claim" placeholder="Enter a statement, fact, or claim to verify…"></textarea>

    <div class="row">
      <div>
        <label for="threshold" style="margin-bottom:4px">Confidence threshold</label>
        <input type="number" id="threshold" min="0" max="1" step="0.05" value="0.7" />
      </div>
      <button id="analyzeBtn" onclick="analyze()">Analyze Claim</button>
    </div>

    <div class="error-msg" id="errorMsg"></div>

    <div class="result" id="result">
      <span class="verdict-badge" id="verdictBadge"></span>
      <div class="confidence-bar"><div class="confidence-fill" id="confidenceFill" style="width:0%"></div></div>
      <p class="reasoning" id="reasoning"></p>
      <div class="flags" id="flagsContainer"></div>
      <p class="meta" id="meta"></p>
    </div>
  </div>

  <script>
    async function analyze() {
      const claim = document.getElementById('claim').value.trim();
      const threshold = parseFloat(document.getElementById('threshold').value) || 0.7;
      const btn = document.getElementById('analyzeBtn');
      const errorMsg = document.getElementById('errorMsg');

      if (!claim) { showError('Please enter a claim to verify.'); return; }

      btn.disabled = true;
      btn.textContent = 'Analyzing…';
      errorMsg.style.display = 'none';
      document.getElementById('result').style.display = 'none';

      try {
        const res = await fetch('/verify', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ claim, confidence_threshold: threshold })
        });
        const data = await res.json();
        if (!res.ok || data.status === 'error') throw new Error(data.error || 'Verification failed');
        showResult(data);
      } catch (e) {
        showError(e.message);
      } finally {
        btn.disabled = false;
        btn.textContent = 'Analyze Claim';
      }
    }

    function showResult(d) {
      const verdictEl = document.getElementById('verdictBadge');
      verdictEl.textContent = d.verdict;
      verdictEl.className = 'verdict-badge verdict-' + d.verdict;
      const pct = Math.round((d.confidence || 0) * 100);
      document.getElementById('confidenceFill').style.width = pct + '%';
      document.getElementById('reasoning').textContent = d.reasoning || '';
      const fc = document.getElementById('flagsContainer');
      fc.innerHTML = (d.flags || []).map(f => '<span class="flag">' + escHtml(f) + '</span>').join('');
      document.getElementById('meta').textContent =
        'Agent: ' + (d.agent_used || '—') + ' · Confidence: ' + pct + '% · ' + (d.timestamp ? new Date(d.timestamp).toLocaleTimeString() : '');
      document.getElementById('result').style.display = 'block';
    }

    function showError(msg) {
      const e = document.getElementById('errorMsg');
      e.textContent = msg;
      e.style.display = 'block';
    }

    function escHtml(s) {
      return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
    }

    document.getElementById('claim').addEventListener('keydown', e => {
      if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) analyze();
    });
  </script>
</body>
</html>`

export default {
  async fetch(request, env) {
    const url = new URL(request.url)
    const { pathname, searchParams } = url

    // ── GET / ──────────────────────────────────────────────────────────────
    if (request.method === 'GET' && pathname === '/') {
      if (searchParams.get('ui') === '1') {
        return new Response(HTML_UI, {
          headers: { 'Content-Type': 'text/html;charset=UTF-8' },
        })
      }
      return Response.json({
        ...BRAND,
        endpoints: {
          'POST /verify': 'Verify a claim — body: { claim, sources?, confidence_threshold? }',
          'GET /health':  'Health check',
          'GET /?ui=1':   'Interactive HTML UI',
        },
      })
    }

    // ── GET /health ────────────────────────────────────────────────────────
    if (request.method === 'GET' && pathname === '/health') {
      return Response.json({ status: 'ok', service: 'verify.blackroad.io', ts: new Date().toISOString() })
    }

    // ── POST /verify ───────────────────────────────────────────────────────
    if (request.method === 'POST' && pathname === '/verify') {
      let body
      try { body = await request.json() } catch {
        return Response.json({ status: 'error', error: 'Invalid JSON' }, { status: 400 })
      }

      const { claim, sources, confidence_threshold } = body
      if (!claim || typeof claim !== 'string' || !claim.trim()) {
        return Response.json({ status: 'error', error: 'claim is required' }, { status: 400 })
      }

      const gatewayUrl = (env.GATEWAY_URL || 'https://gateway.blackroad.io') + '/v1/verify'
      try {
        const upstream = await fetch(gatewayUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ claim, sources: sources || [], confidence_threshold: confidence_threshold ?? 0.7 }),
        })
        const data = await upstream.json()
        return Response.json(data, { status: upstream.ok ? 200 : upstream.status })
      } catch (e) {
        return Response.json({ status: 'error', error: 'Gateway unavailable' }, { status: 502 })
      }
    }

    // ── POST /verify/claim (legacy path) ───────────────────────────────────
    if (request.method === 'POST' && pathname === '/verify/claim') {
      const redirect = new URL('/verify', request.url)
      return Response.redirect(redirect.toString(), 308)
    }

    return Response.json({ status: 'error', error: 'Not found' }, { status: 404 })
  },
}
