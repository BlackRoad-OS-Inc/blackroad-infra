#!/bin/bash
# 🚀 Social Media CLI Setup Guide
# Automate posting to Twitter, LinkedIn, etc.

echo "🤖 BlackRoad Social Media CLI Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check what's available
echo "📋 Checking available tools..."
echo ""

# Twitter CLI options
echo "1️⃣  TWITTER CLI OPTIONS:"
echo ""
echo "   Option A: Install 'twurl' (Official Twitter CLI)"
echo "   $ gem install twurl"
echo "   $ twurl authorize --consumer-key YOUR_KEY --consumer-secret YOUR_SECRET"
echo ""
echo "   Option B: Install 't' (Popular Ruby gem)"
echo "   $ gem install t"
echo "   $ t authorize"
echo ""
echo "   Option C: Use Twitter API directly with curl"
echo "   (Need API keys from: https://developer.twitter.com/)"
echo ""

# LinkedIn CLI
echo "2️⃣  LINKEDIN CLI:"
echo "   $ npm install -g linkedin-cli"
echo "   $ linkedin-cli auth"
echo ""

# Reddit CLI
echo "3️⃣  REDDIT CLI:"
echo "   $ pip install praw"
echo "   (Need API keys from: https://www.reddit.com/prefs/apps)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 TO ENABLE CLI POSTING, YOU NEED:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Twitter API Keys:"
echo "   1. Go to: https://developer.twitter.com/en/portal/dashboard"
echo "   2. Create app (name: BlackRoad CLI)"
echo "   3. Get API Key + Secret"
echo "   4. Enable OAuth 2.0"
echo ""
echo "LinkedIn API Keys:"
echo "   1. Go to: https://www.linkedin.com/developers/apps"
echo "   2. Create app"
echo "   3. Get Client ID + Secret"
echo ""
echo "Reddit API Keys:"
echo "   1. Go to: https://www.reddit.com/prefs/apps"
echo "   2. Create app (script type)"
echo "   3. Get Client ID + Secret"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ QUICK OPTION: I can create posting scripts NOW"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Choose:"
echo "   A) Get API keys first (15 min) - Then full automation"
echo "   B) Manual posting now (5 min) - Fast but manual"
echo ""
read -p "Choose (A/B): " choice

if [[ "$choice" == "A" || "$choice" == "a" ]]; then
    echo ""
    echo "✅ Great choice! Here's the fastest path:"
    echo ""
    echo "1. TWITTER API (5 min):"
    echo "   → Open: https://developer.twitter.com/en/portal/dashboard"
    echo "   → Create app: 'BlackRoad CLI'"
    echo "   → Copy API Key + Secret"
    echo "   → Come back here with keys"
    echo ""
    echo "2. I'LL INSTALL & CONFIGURE:"
    echo "   → gem install twurl"
    echo "   → twurl authorize (with your keys)"
    echo "   → Test post"
    echo ""
    echo "3. THEN WE CAN POST WITH ONE COMMAND:"
    echo "   → ./post-to-twitter.sh 'Your message'"
    echo "   → DONE!"
    echo ""
    echo "🔥 Ready to get API keys? (y/n)"
    read -p "> " ready
    
    if [[ "$ready" == "y" || "$ready" == "Y" ]]; then
        echo ""
        echo "🚀 Opening Twitter Developer Portal..."
        open "https://developer.twitter.com/en/portal/dashboard" 2>/dev/null || \
        echo "   Go to: https://developer.twitter.com/en/portal/dashboard"
        echo ""
        echo "When you have keys, run:"
        echo "   ./setup-twitter-cli.sh YOUR_API_KEY YOUR_API_SECRET"
    fi
else
    echo ""
    echo "✅ No problem! Manual posting is fast:"
    echo ""
    echo "   Run: ./LAUNCH_NOW.sh"
    echo ""
    echo "   Copy-paste posts in 5 minutes!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
