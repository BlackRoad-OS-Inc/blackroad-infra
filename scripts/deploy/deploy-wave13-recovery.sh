#!/bin/bash
# Wave 13: Fleet Recovery & Expansion

echo "🔧 Wave 13: Fleet Recovery Strategy"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📊 Current Status:"
echo "  ✅ octavia (192.168.4.38) - Primary, 12 services"
echo "  ✅ cecilia (192.168.4.89) - Secondary, 3 services"
echo "  ❌ alice (192.168.4.49) - Network unreachable"
echo "  ⚠️  lucidia (unknown IP) - SSH config points to octavia"
echo ""

echo "🔍 Scanning from octavia to find lucidia..."
ssh octavia "nmap -sn 192.168.4.0/22 2>/dev/null | grep -B 2 'lucidia' || echo 'nmap not available, trying arp...'"

echo ""
ssh octavia "arp -a | grep -i '192.168' | head -20"

echo ""
echo "🔍 Checking octavia's known hosts..."
ssh octavia "cat /etc/hosts | grep -E '(alice|lucidia|cecilia)'"

echo ""
echo "📋 Strategy:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Option A: Work with what we have (2-node cluster)"
echo "  • octavia + cecilia are operational"
echo "  • Already have HA with failover"
echo "  • Can proceed with performance tuning"
echo ""
echo "Option B: Physical intervention needed"
echo "  • alice may be powered off or disconnected"
echo "  • lucidia IP changed or was incorrectly configured"
echo "  • Requires physical access to devices"
echo ""
echo "Option C: Deploy monitoring to detect when they come online"
echo "  • Create auto-discovery service"
echo "  • Alert when alice/lucidia become reachable"
echo "  • Auto-configure when detected"
echo ""

echo "🎯 Recommendation: Proceed with Wave 13B - Performance Optimization"
echo "   (2-node cluster is production-ready)"
