#!/usr/bin/env bash
# ============================================================
#  br-nginx-deploy — push nginx + cloudflared config to Pi fleet
#  Usage: ./scripts/pi-nginx-router.sh [install|deploy|tunnel|status|all]
#
#  What this does:
#    1. apt install nginx on all Pis (idempotent)
#    2. Upload site configs → /etc/nginx/sites-available/
#    3. Enable sites + reload nginx
#    4. Update cloudflared tunnel config
#    5. Restart cloudflared
#
#  After this runs:
#    Internet → Cloudflare edge
#             → cloudflared on Pi 192.168.4.64
#             → nginx (routes by subdomain)
#             → upstream services on Pi fleet
#
#  DNS records needed in Cloudflare (all CNAME → <tunnel-id>.cfargotunnel.com):
#    blackroad.io          CNAME  52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com
#    www.blackroad.io      CNAME  52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com
#    agents.blackroad.io   CNAME  52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com
#    api.blackroad.io      CNAME  52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com
#    ollama.blackroad.io   CNAME  52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com
#    dashboard.blackroad.io CNAME 52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com
#    docs.blackroad.io     CNAME  52915859-da18-4aa6-add5-7bd9fcac2e0b.cfargotunnel.com
#
#  All with Proxy = ON (orange cloud) in Cloudflare dashboard.
#  Zero ports open on your router. Zero public IPs exposed. $0/mo.
# ============================================================
echo "Run: ./blackroad-infra/scripts/pi-nginx-router.sh all"
