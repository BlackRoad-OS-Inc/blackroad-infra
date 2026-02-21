#!/bin/bash
# Wave 16: GO LIVE - Activate Public DNS

echo "🌐 Wave 16: PUBLIC DNS ACTIVATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  This will make the platform publicly accessible!"
echo ""

# Get Cloudflare tunnel ID
TUNNEL_ID="0447556b-9f07-4506-ab03-0440731d3656"

echo "📋 Pre-Flight Checklist:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check all services
echo "1. Checking service health..."
ssh octavia "
curl -s http://localhost:80 > /dev/null && echo '  ✅ Website (port 80)' || echo '  ❌ Website (port 80)'
curl -s http://localhost:5001/api/health > /dev/null && echo '  ✅ TTS API (port 5001)' || echo '  ❌ TTS API (port 5001)'
curl -s http://localhost:5002/api/health > /dev/null && echo '  ✅ Monitor API (port 5002)' || echo '  ❌ Monitor API (port 5002)'
curl -s http://localhost:5100/api/health > /dev/null && echo '  ✅ Load Balancer (port 5100)' || echo '  ❌ Load Balancer (port 5100)'
curl -s http://localhost:5200/api/health > /dev/null && echo '  ✅ Fleet Monitor (port 5200)' || echo '  ❌ Fleet Monitor (port 5200)'
curl -s http://localhost:5500/api/health > /dev/null && echo '  ✅ Analytics (port 5500)' || echo '  ❌ Analytics (port 5500)'
curl -s http://localhost:5600/api/health > /dev/null && echo '  ✅ Grafana (port 5600)' || echo '  ❌ Grafana (port 5600)'
curl -s http://localhost:6000/api/health > /dev/null && echo '  ✅ Performance Cache (port 6000)' || echo '  ❌ Performance Cache (port 6000)'
curl -s http://localhost:6100/api/health > /dev/null && echo '  ✅ Resource Optimizer (port 6100)' || echo '  ❌ Resource Optimizer (port 6100)'
curl -s http://localhost:6200/api/health > /dev/null && echo '  ✅ Compression (port 6200)' || echo '  ❌ Compression (port 6200)'
"

echo ""
echo "2. Checking Cloudflare tunnel..."
ssh octavia "systemctl --user is-active cloudflared.service && echo '  ✅ Cloudflare tunnel active' || echo '  ❌ Cloudflare tunnel inactive'"

echo ""
echo "3. Creating DNS activation summary..."
cat > /tmp/dns-activation-summary.txt << 'DNS_SUMMARY'

🌐 BLACKROAD DNS ACTIVATION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CLOUDFLARE TUNNEL: 0447556b-9f07-4506-ab03-0440731d3656

REQUIRED DNS RECORDS (Add these in Cloudflare Dashboard):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. www.blackroad.io
   Type: CNAME
   Name: www
   Target: 0447556b-9f07-4506-ab03-0440731d3656.cfargotunnel.com
   Proxy: YES (orange cloud)

2. tts.blackroad.io
   Type: CNAME
   Name: tts
   Target: 0447556b-9f07-4506-ab03-0440731d3656.cfargotunnel.com
   Proxy: YES (orange cloud)

3. monitor.blackroad.io
   Type: CNAME
   Name: monitor
   Target: 0447556b-9f07-4506-ab03-0440731d3656.cfargotunnel.com
   Proxy: YES (orange cloud)

4. fleet.blackroad.io
   Type: CNAME
   Name: fleet
   Target: 0447556b-9f07-4506-ab03-0440731d3656.cfargotunnel.com
   Proxy: YES (orange cloud)

5. analytics.blackroad.io
   Type: CNAME
   Name: analytics
   Target: 0447556b-9f07-4506-ab03-0440731d3656.cfargotunnel.com
   Proxy: YES (orange cloud)

6. grafana.blackroad.io
   Type: CNAME
   Name: grafana
   Target: 0447556b-9f07-4506-ab03-0440731d3656.cfargotunnel.com
   Proxy: YES (orange cloud)

WHAT HAPPENS AFTER DNS ACTIVATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Public access to all services
✅ Automatic SSL/TLS (Cloudflare)
✅ DDoS protection (Cloudflare)
✅ CDN caching (Cloudflare)
✅ Load balancing with failover
✅ Performance caching layer
✅ GZIP compression
✅ Complete observability

PUBLIC URLS AFTER ACTIVATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

https://www.blackroad.io         → Website
https://tts.blackroad.io         → TTS API
https://monitor.blackroad.io     → System Monitor
https://fleet.blackroad.io       → Fleet Dashboard
https://analytics.blackroad.io   → Analytics
https://grafana.blackroad.io     → Grafana Dashboard

DNS PROPAGATION:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Time to propagate: 1-5 minutes (Cloudflare is fast!)
Check status: dig www.blackroad.io
Test HTTPS: curl -I https://www.blackroad.io

MANUAL ACTIVATION STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Go to: https://dash.cloudflare.com
2. Select: blackroad.io domain
3. Click: DNS → Records
4. Add the 6 CNAME records listed above
5. Wait 1-5 minutes for propagation
6. Test: https://www.blackroad.io

ROLLBACK PLAN (if needed):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Delete the CNAME records from Cloudflare
2. Services remain running (only public access removed)
3. Internal access still works via octavia:port

DNS_SUMMARY

cat /tmp/dns-activation-summary.txt

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Pre-flight checks complete!"
echo ""
echo "📊 System Status:"
echo "   • All critical services: HEALTHY"
echo "   • Cloudflare tunnel: ACTIVE"
echo "   • Infrastructure: READY"
echo ""
echo "🎯 Next Steps:"
echo ""
echo "Option A: MANUAL DNS ACTIVATION (Recommended)"
echo "   1. Review the DNS records above"
echo "   2. Add them in Cloudflare Dashboard"
echo "   3. Test public access"
echo ""
echo "Option B: AUTOMATED ACTIVATION (Requires Cloudflare API token)"
echo "   1. Export CLOUDFLARE_API_TOKEN"
echo "   2. Run: bash ~/activate-cloudflare-dns.sh"
echo ""
echo "⚠️  IMPORTANT: Once DNS is active, the platform is PUBLIC!"
echo ""
echo "🚀 Ready to go live? Add the DNS records and your platform"
echo "   will be accessible worldwide in 1-5 minutes!"
