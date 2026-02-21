#!/bin/bash
# Deploy landing pages as Cloudflare Workers

echo "🚀 Deploying landing pages as Workers..."

# Create Workers for each landing page
for PAGE in lucidia roadauth; do
  echo ""
  echo "📄 Creating ${PAGE} Worker..."
  
  # Read the HTML
  HTML=$(cat ${PAGE}-landing.html | sed 's/"/\\"/g' | sed "s/'/\\\\'/g")
  
  # Create Worker script
  cat > ${PAGE}-worker.js << EOF
export default {
  async fetch(request) {
    const html = \`$(cat ${PAGE}-landing.html)\`;
    return new Response(html, {
      headers: { 'content-type': 'text/html;charset=UTF-8' }
    });
  }
};
EOF
  
  echo "✓ Worker script created: ${PAGE}-worker.js"
done

echo ""
echo "✅ Worker scripts ready!"
echo ""
echo "📋 Next steps:"
echo "1. Go to https://dash.cloudflare.com"
echo "2. Navigate to Workers & Pages"
echo "3. Create Worker → Paste script → Deploy"
echo "4. Add custom domain (lucidia.earth, roadauth.io)"
