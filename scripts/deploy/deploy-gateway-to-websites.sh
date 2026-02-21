#!/bin/bash
# Deploy BlackRoad Copilot Gateway to all websites

echo "🚀 Deploying BlackRoad Copilot Gateway to all websites..."
echo ""

# Load service registry
REGISTRY=~/infra/blackroad_registry.json

if [ ! -f "$REGISTRY" ]; then
  echo "❌ Registry not found: $REGISTRY"
  exit 1
fi

# Get all active services
SERVICES=$(jq -r '.services[] | select(.status == "active") | "\(.subdomain).\(.domain)"' "$REGISTRY")

echo "📋 Active Services:"
echo "$SERVICES" | nl
echo ""

# Create gateway deployment configs for each service
mkdir -p ~/copilot-agent-gateway/configs

# Generate Cloudflare Workers for each domain
for SERVICE in $SERVICES; do
  SUBDOMAIN=$(echo "$SERVICE" | cut -d'.' -f1)
  DOMAIN=$(echo "$SERVICE" | cut -d'.' -f2-)
  
  # Create Cloudflare Worker script
  cat > ~/copilot-agent-gateway/configs/${SUBDOMAIN}-worker.js << WORKER
// BlackRoad Copilot Gateway for ${SERVICE}
export default {
  async fetch(request, env) {
    const url = new URL(request.url)
    
    // Gateway API routes
    if (url.pathname.startsWith('/api/gateway/')) {
      return handleGateway(request, env)
    }
    
    // Proxy to main service
    return fetch(request)
  }
}

async function handleGateway(request, env) {
  const url = new URL(request.url)
  const path = url.pathname.replace('/api/gateway', '')
  
  // Forward to local gateway
  const gatewayUrl = \`http://localhost:3030\${path}\${url.search}\`
  
  return fetch(gatewayUrl, {
    method: request.method,
    headers: request.headers,
    body: request.body
  })
}
WORKER
  
  echo "✅ Created worker for ${SERVICE}"
done

echo ""
echo "📦 Deployment configs created in ~/copilot-agent-gateway/configs/"
echo ""
echo "🌐 Next steps:"
echo "  1. Deploy workers to Cloudflare: wrangler deploy"
echo "  2. Configure DNS to route /api/gateway/* to gateway"
echo "  3. Start gateway web server on each domain"
echo ""
echo "📝 Or use Railway for centralized gateway:"
echo "  railway up -d ~/copilot-agent-gateway/web-server.js"

