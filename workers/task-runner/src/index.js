/**
 * BlackRoad OS — Task Runner Worker
 * Cloudflare Worker with Queue consumer for long-running CI/infra tasks.
 *
 * Routes:
 *   POST /dispatch     → Enqueue a task
 *   GET  /status/:id   → Check task status
 *   GET  /health       → Health check
 *
 * Queue consumer handles: deploy, health-check, dns-verify, worker-deploy
 */

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
  });
}

/** Dispatch a long-running task to the Cloudflare Queue */
async function dispatchTask(taskType, payload, env) {
  const taskId = crypto.randomUUID();
  const task = {
    id: taskId,
    type: taskType,
    payload,
    created_at: new Date().toISOString(),
    status: 'queued',
  };

  if (env.TASK_QUEUE) {
    await env.TASK_QUEUE.send(task);
    return { queued: true, task_id: taskId, task };
  }
  // Fallback: execute immediately if queue not configured
  return { queued: false, task_id: taskId, message: 'Queue not configured, task logged only' };
}

/** Process a queued task (called by Queue consumer) */
async function processTask(task, env) {
  const { type, payload } = task;
  console.log(`Processing task: ${type} (${task.id})`);

  switch (type) {
    case 'health-check': {
      const endpoints = payload.endpoints || [];
      const results = await Promise.allSettled(
        endpoints.map(async (url) => {
          try {
            const r = await fetch(url, { signal: AbortSignal.timeout(10000) });
            return { url, status: r.status, ok: r.ok, error: null };
          } catch (e) {
            const isTimeout = e.name === 'TimeoutError' || e.message.includes('timeout');
            return { url, status: null, ok: false, error: isTimeout ? 'timeout' : e.message };
          }
        })
      );
      return { type, results: results.map(r => r.value ?? { url: null, ok: false, error: String(r.reason) }) };
    }

    case 'dns-verify': {
      const domains = payload.domains || [];
      const results = await Promise.allSettled(
        domains.map(async (domain) => {
          try {
            const r = await fetch(`https://${domain}`, { signal: AbortSignal.timeout(10000) });
            return { domain, status: r.status, reachable: r.ok, error: null };
          } catch (e) {
            const isTimeout = e.name === 'TimeoutError' || e.message.includes('timeout');
            return { domain, status: null, reachable: false, error: isTimeout ? 'timeout' : e.message };
          }
        })
      );
      return { type, results: results.map(r => r.value ?? { domain: null, reachable: false, error: String(r.reason) }) };
    }

    case 'worker-deploy': {
      // Notify a deploy webhook / CI system
      const { worker_name, deploy_hook } = payload;
      if (deploy_hook) {
        const r = await fetch(deploy_hook, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ worker_name, triggered_at: new Date().toISOString() }),
        });
        return { type, worker_name, dispatched: r.ok, status: r.status };
      }
      return { type, worker_name, dispatched: false, reason: 'No deploy_hook provided' };
    }

    default:
      return { type, status: 'unknown_task_type' };
  }
}

export default {
  /** HTTP handler */
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname } = url;

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    // GET /health
    if (request.method === 'GET' && pathname === '/health') {
      return json({
        service: 'BlackRoad Task Runner',
        version: '1.0.0',
        queue: env.TASK_QUEUE ? 'connected' : 'not configured',
        ts: new Date().toISOString(),
      });
    }

    // GET /
    if (request.method === 'GET' && pathname === '/') {
      return json({
        service: 'BlackRoad Task Runner',
        endpoints: {
          'POST /dispatch': 'Enqueue a long-running task',
          'GET /health': 'Health check',
        },
        task_types: ['health-check', 'dns-verify', 'worker-deploy'],
      });
    }

    // POST /dispatch
    if (request.method === 'POST' && pathname === '/dispatch') {
      let body;
      try {
        body = await request.json();
      } catch {
        return json({ error: 'Invalid JSON' }, 400);
      }
      const { type, payload } = body;
      if (!type) return json({ error: 'task type is required' }, 400);
      const result = await dispatchTask(type, payload || {}, env);
      return json(result);
    }

    return json({ error: 'Not found' }, 404);
  },

  /** Queue consumer — processes long-running tasks */
  async queue(batch, env) {
    console.log(`Processing batch of ${batch.messages.length} tasks`);
    for (const message of batch.messages) {
      try {
        const result = await processTask(message.body, env);
        console.log(`Task ${message.body.id} completed:`, JSON.stringify(result));
        message.ack();
      } catch (e) {
        console.error(`Task ${message.body.id} failed:`, e.message);
        message.retry();
      }
    }
  },
};
