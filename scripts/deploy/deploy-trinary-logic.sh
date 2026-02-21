#!/bin/bash
# Deploy Trinary Logic Engine to all BlackRoad Pis

# Colors
AMBER='\033[38;5;214m'
BLUE='\033[38;5;33m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
RESET='\033[0m'

echo -e "${AMBER}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${AMBER}║${RESET}     ${BLUE}🌌 Deploying Trinary Logic to BlackRoad Fleet${RESET}          ${AMBER}║${RESET}"
echo -e "${AMBER}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Online Pis
PIS=(
    "cecilia:cecilia"
    "lucidia:lucidia"
    "alice:alice"
    "octavia:octavia"
    "anastasia:anastasia"
)

SUCCESS_COUNT=0
TOTAL=0

for pi_entry in "${PIS[@]}"; do
    name="${pi_entry%%:*}"
    host="${pi_entry##*:}"
    TOTAL=$((TOTAL + 1))
    
    echo -e "${BLUE}▸ Deploying to ${name}...${RESET}"
    
    # Copy trinary engine
    if scp -o ConnectTimeout=5 ~/trinary-logic-engine.py "${host}:~/trinary-logic-engine.py" 2>/dev/null; then
        # Run test
        if ssh -o ConnectTimeout=5 "${host}" "python3 ~/trinary-logic-engine.py" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✅ $name: Trinary logic engine deployed & tested${RESET}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo -e "  ${RED}❌ $name: Deployed but test failed${RESET}"
        fi
    else
        echo -e "  ${RED}❌ $name: Could not deploy${RESET}"
    fi
    echo ""
done

echo ""
echo -e "${AMBER}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${AMBER}║${RESET}                    ${BLUE}Deployment Complete${RESET}                       ${AMBER}║${RESET}"
echo -e "${AMBER}╠═══════════════════════════════════════════════════════════════╣${RESET}"
echo -e "${AMBER}║${RESET}  ${GREEN}Success:${RESET} $SUCCESS_COUNT/$TOTAL Pis now running trinary logic          ${AMBER}║${RESET}"
echo -e "${AMBER}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

if [ $SUCCESS_COUNT -eq $TOTAL ]; then
    echo -e "${GREEN}🎉 All Pis are now running trinary logic (1/0/-1)!${RESET}"
    echo ""
    echo -e "${BLUE}Next steps:${RESET}"
    echo "  • Test distributed consensus: ssh cecilia 'python3 ~/trinary-logic-engine.py'"
    echo "  • Build multi-agent paraconsistent system"
    echo "  • Enable contradiction-tolerant reasoning"
else
    echo -e "${AMBER}⚠️  Some deployments failed. Check network connectivity.${RESET}"
fi
