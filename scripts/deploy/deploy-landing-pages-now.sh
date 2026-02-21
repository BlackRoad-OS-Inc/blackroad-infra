#!/bin/bash
# Deploy 3 landing pages to Cloudflare Pages with real payment links

set -e

PINK='\033[38;5;205m'
GREEN='\033[38;5;82m'
BLUE='\033[38;5;69m'
RESET='\033[0m'

echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${PINK}    🚀 LANDING PAGES - DEPLOY TO CLOUDFLARE${RESET}"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo

# Create temp directory for deployment
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}Working directory:${RESET} $TEMP_DIR"
echo

# 1. Context Bridge
echo -e "${GREEN}1/3${RESET} Deploying Context Bridge..."
mkdir -p "$TEMP_DIR/context-bridge"
cat > "$TEMP_DIR/context-bridge/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Context Bridge - Unlimited AI Context</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #fff;
            line-height: 1.618;
        }
        .hero {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 55px 21px;
        }
        .hero h1 {
            font-size: 55px;
            margin-bottom: 21px;
            background: linear-gradient(135deg, #FF1D6C 38.2%, #F5A623 61.8%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .hero p {
            font-size: 21px;
            margin-bottom: 34px;
            opacity: 0.9;
        }
        .cta-buttons {
            display: flex;
            gap: 21px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .btn {
            padding: 13px 34px;
            font-size: 21px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: transform 0.2s;
        }
        .btn:hover { transform: translateY(-2px); }
        .btn-primary {
            background: linear-gradient(135deg, #FF1D6C 38.2%, #F5A623 61.8%);
            color: #fff;
        }
        .btn-secondary {
            background: rgba(255, 255, 255, 0.1);
            color: #fff;
            border: 2px solid rgba(255, 255, 255, 0.3);
        }
    </style>
</head>
<body>
    <div class="hero">
        <div>
            <h1>Context Bridge</h1>
            <p>Unlimited context for AI coding assistants.<br>Never lose context again.</p>
            <div class="cta-buttons">
                <a href="https://buy.stripe.com/3cIdR88lZ6bYbvieW14ko0c" class="btn btn-primary">
                    Start Monthly ($10/mo)
                </a>
                <a href="https://buy.stripe.com/28EbJ01XBeIu6aYg054ko0b" class="btn btn-secondary">
                    Annual Plan ($100/yr)
                </a>
            </div>
        </div>
    </div>
</body>
</html>
EOF

wrangler pages deploy "$TEMP_DIR/context-bridge" --project-name=context-bridge --branch=main 2>&1 | tail -5

# 2. Lucidia
echo
echo -e "${GREEN}2/3${RESET} Deploying Lucidia..."
mkdir -p "$TEMP_DIR/lucidia"
cat > "$TEMP_DIR/lucidia/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lucidia Pro - AI Simulation Engine</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #fff;
            line-height: 1.618;
        }
        .hero {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 55px 21px;
        }
        .hero h1 {
            font-size: 55px;
            margin-bottom: 21px;
            background: linear-gradient(135deg, #9C27B0 38.2%, #2979FF 61.8%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .hero p {
            font-size: 21px;
            margin-bottom: 34px;
            opacity: 0.9;
        }
        .btn {
            padding: 13px 34px;
            font-size: 21px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            background: linear-gradient(135deg, #9C27B0 38.2%, #2979FF 61.8%);
            color: #fff;
            transition: transform 0.2s;
        }
        .btn:hover { transform: translateY(-2px); }
    </style>
</head>
<body>
    <div class="hero">
        <div>
            <h1>Lucidia Pro</h1>
            <p>Advanced AI simulation engine with quantum computing.<br>Reality-bending intelligence.</p>
            <a href="https://buy.stripe.com/bJedR8fOreIu1UI0174ko0a" class="btn">
                Start Pro ($49/mo)
            </a>
        </div>
    </div>
</body>
</html>
EOF

wrangler pages deploy "$TEMP_DIR/lucidia" --project-name=lucidia-pro --branch=main 2>&1 | tail -5

# 3. RoadAuth
echo
echo -e "${GREEN}3/3${RESET} Deploying RoadAuth..."
mkdir -p "$TEMP_DIR/roadauth"
cat > "$TEMP_DIR/roadauth/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RoadAuth - Authentication Platform</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #fff;
            line-height: 1.618;
        }
        .hero {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 55px 21px;
        }
        .hero h1 {
            font-size: 55px;
            margin-bottom: 21px;
            background: linear-gradient(135deg, #F5A623 38.2%, #FF1D6C 61.8%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .hero p {
            font-size: 21px;
            margin-bottom: 34px;
            opacity: 0.9;
        }
        .pricing {
            display: flex;
            gap: 21px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .plan {
            background: rgba(255, 255, 255, 0.05);
            padding: 34px;
            border-radius: 13px;
            border: 2px solid rgba(255, 255, 255, 0.1);
            min-width: 200px;
        }
        .plan h3 { margin-bottom: 13px; }
        .plan .price { font-size: 34px; margin-bottom: 21px; color: #F5A623; }
        .btn {
            padding: 13px 34px;
            font-size: 16px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            background: linear-gradient(135deg, #F5A623 38.2%, #FF1D6C 61.8%);
            color: #fff;
            transition: transform 0.2s;
        }
        .btn:hover { transform: translateY(-2px); }
    </style>
</head>
<body>
    <div class="hero">
        <div>
            <h1>RoadAuth</h1>
            <p>Authentication platform that scales with your business.<br>From startup to enterprise.</p>
            <div class="pricing">
                <div class="plan">
                    <h3>Startup</h3>
                    <div class="price">$29<span style="font-size: 16px;">/mo</span></div>
                    <p style="font-size: 14px; margin-bottom: 21px;">For growing teams</p>
                    <a href="https://buy.stripe.com/6oUaEWfOr1VI1UI5lr4ko09" class="btn">Get Started</a>
                </div>
                <div class="plan">
                    <h3>Business</h3>
                    <div class="price">$49<span style="font-size: 16px;">/mo</span></div>
                    <p style="font-size: 14px; margin-bottom: 21px;">For established companies</p>
                    <a href="https://buy.stripe.com/5kQ14meKnfMy6aY8xD4ko08" class="btn">Get Started</a>
                </div>
                <div class="plan">
                    <h3>Enterprise</h3>
                    <div class="price">$2,499<span style="font-size: 16px;">/mo</span></div>
                    <p style="font-size: 14px; margin-bottom: 21px;">Mission-critical apps</p>
                    <a href="https://buy.stripe.com/fZu3cubyb2ZMdDqcNT4ko07" class="btn">Get Started</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF

wrangler pages deploy "$TEMP_DIR/roadauth" --project-name=roadauth --branch=main 2>&1 | tail -5

# Cleanup
rm -rf "$TEMP_DIR"

echo
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}✅ DEPLOYED!${RESET} All 3 landing pages are LIVE"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo
echo -e "${BLUE}Live URLs (check Cloudflare dashboard for exact URLs):${RESET}"
echo "  • https://context-bridge.pages.dev"
echo "  • https://lucidia-pro.pages.dev"
echo "  • https://roadauth.pages.dev"
echo
