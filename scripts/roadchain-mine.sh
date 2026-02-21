#!/bin/bash
# roadchain-mine.sh — RoadChain Proof-of-Work Miner
# Mines ROAD blocks with SHA-256 PoW, awards block rewards
# Owner: ALEXALOUISEAMUNDSON.COM
#
# Usage:
#   ./roadchain-mine.sh mine [wallet] [blocks]   # Mine blocks (default: 1)
#   ./roadchain-mine.sh auto [wallet]             # Continuous mining
#   ./roadchain-mine.sh stats                     # Mining statistics
#   ./roadchain-mine.sh difficulty                # Current difficulty info
#   ./roadchain-mine.sh halving                   # Halving schedule
#   ./roadchain-mine.sh daemon [wallet]           # Background mining daemon

set -euo pipefail

ROADCHAIN_DIR="$HOME/.roadchain"
CHAIN_FILE="$ROADCHAIN_DIR/chain.json"
WALLETS_DIR="$ROADCHAIN_DIR/wallets"
MINING_LOG="$ROADCHAIN_DIR/mining.log"
MINING_STATS="$ROADCHAIN_DIR/mining-stats.json"
PID_FILE="$ROADCHAIN_DIR/miner-daemon.pid"

# ═══════════════════════════════════════════════════════════
# ROADCOIN ECONOMICS
# ═══════════════════════════════════════════════════════════
# Max supply:     21,000,000 ROAD (matches BTC)
# Initial reward: 50 ROAD per block (genesis already minted)
# Halving:        Every 210 MINED blocks (bridge blocks don't count)
# Min reward:     0.00000001 ROAD (1 sat equivalent)
# Difficulty:     Adjusts every 10 blocks, targets ~10s/block
# ═══════════════════════════════════════════════════════════

MAX_SUPPLY=21000000
INITIAL_REWARD=50
HALVING_INTERVAL=210  # Only PoW-mined blocks count toward halving
DIFFICULTY_ADJUST_INTERVAL=10
TARGET_BLOCK_TIME=10  # seconds

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
GREEN='\033[38;5;82m'
BLUE='\033[38;5;69m'
VIOLET='\033[38;5;135m'
RED='\033[38;5;196m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;240m'
BOLD='\033[1m'
RESET='\033[0m'

mkdir -p "$ROADCHAIN_DIR" "$WALLETS_DIR"

log_mine() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$MINING_LOG"
}

# ═══════════════════════════════════════════════════════════
# MINING ECONOMICS
# ═══════════════════════════════════════════════════════════

get_block_reward() {
    # Calculate reward based on block height with halving
    python3 -c "
height = $1
reward = $INITIAL_REWARD
halvings = height // $HALVING_INTERVAL
for i in range(halvings):
    reward /= 2
    if reward < 0.00000001:
        reward = 0
        break
print(f'{reward:.8f}')
"
}

get_total_mined() {
    python3 - "$CHAIN_FILE" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    chain = json.load(f)
total = 0
for block in chain['chain']:
    for tx in block.get('transactions', []):
        if tx.get('type') == 'MINING_REWARD' or tx.get('sender') in ('ROADCHAIN', 'COINBASE'):
            total += tx.get('amount', 0)
print(f'{total:.8f}')
PYEOF
}

get_difficulty() {
    # Difficulty = number of leading zero hex chars required
    # Starts at 4 (hash must start with "0000")
    # Adjusts based on recent block times
    python3 - "$CHAIN_FILE" "$DIFFICULTY_ADJUST_INTERVAL" "$TARGET_BLOCK_TIME" << 'PYEOF'
import json, sys

chain_file = sys.argv[1]
adjust_interval = int(sys.argv[2])
target_time = int(sys.argv[3])

with open(chain_file) as f:
    chain = json.load(f)

blocks = chain['chain']
height = len(blocks)

# Base difficulty: 4 leading zeros
difficulty = 4

# Find recent mined blocks (with PoW) to adjust
mined_blocks = [b for b in blocks if b.get('hash', '').startswith('0' * 4) and b.get('nonce', 0) > 0]

if len(mined_blocks) >= adjust_interval:
    recent = mined_blocks[-adjust_interval:]
    if len(recent) >= 2:
        time_span = recent[-1]['timestamp'] - recent[0]['timestamp']
        expected = target_time * (len(recent) - 1)
        if time_span > 0:
            ratio = expected / time_span
            if ratio > 2:
                difficulty = max(3, difficulty - 1)  # Too slow, easier
            elif ratio < 0.5:
                difficulty = min(6, difficulty + 1)  # Too fast, harder

print(difficulty)
PYEOF
}

# ═══════════════════════════════════════════════════════════
# MINE A SINGLE BLOCK
# ═══════════════════════════════════════════════════════════

mine_block() {
    local wallet_name="${1:-alexa}"
    local wallet_file="$WALLETS_DIR/${wallet_name}.json"

    if [ ! -f "$wallet_file" ]; then
        echo -e "${RED}Wallet not found: $wallet_name${RESET}"
        return 1
    fi

    python3 - "$CHAIN_FILE" "$wallet_file" "$wallet_name" "$WALLETS_DIR" "$INITIAL_REWARD" "$HALVING_INTERVAL" "$MAX_SUPPLY" << 'PYEOF'
import json, hashlib, time, sys, os

chain_file = sys.argv[1]
wallet_file = sys.argv[2]
wallet_name = sys.argv[3]
wallets_dir = sys.argv[4]
initial_reward = float(sys.argv[5])
halving_interval = int(sys.argv[6])
max_supply = float(sys.argv[7])

# Load chain
with open(chain_file) as f:
    chain = json.load(f)

blocks = chain['chain']
height = len(blocks)
prev_hash = blocks[-1]['hash'] if blocks else '0' * 64

# Count only PoW-mined blocks for halving (bridge blocks don't count)
mined_block_count = 0
total_mined = 0
for b in blocks:
    for tx in b.get('transactions', []):
        if tx.get('type') == 'MINING_REWARD' or tx.get('sender') in ('ROADCHAIN', 'COINBASE'):
            total_mined += tx.get('amount', 0)
            mined_block_count += 1

# Calculate reward based on MINED blocks only
reward = initial_reward
halvings = mined_block_count // halving_interval
for i in range(halvings):
    reward /= 2
    if reward < 0.00000001:
        reward = 0
        break

if total_mined + reward > max_supply:
    reward = max(0, max_supply - total_mined)
    if reward < 0.00000001:
        print(f'\033[38;5;196mMax supply reached. No more ROAD to mine.\033[0m')
        sys.exit(1)

# Difficulty: number of leading zero hex chars
difficulty = 4
mined_blocks = [b for b in blocks if b.get('hash', '').startswith('0' * 4) and b.get('nonce', 0) > 0]
if len(mined_blocks) >= 10:
    recent = mined_blocks[-10:]
    if len(recent) >= 2:
        time_span = recent[-1]['timestamp'] - recent[0]['timestamp']
        expected = 10 * 9  # target 10s * 9 intervals
        if time_span > 0:
            ratio = expected / time_span
            if ratio > 2:
                difficulty = max(3, difficulty - 1)
            elif ratio < 0.5:
                difficulty = min(6, difficulty + 1)

target = '0' * difficulty
ts = time.time()

# Create coinbase transaction
tx_data = f"COINBASE:{height}:{wallet_name}:{reward}:{ts}"
tx_hash = hashlib.sha256(tx_data.encode()).hexdigest()

coinbase_tx = {
    'type': 'MINING_REWARD',
    'sender': 'COINBASE',
    'recipient': wallet_name,
    'amount': reward,
    'block_height': height,
    'timestamp': ts,
    'hash': tx_hash
}

# MINE — find nonce where hash starts with target
nonce = 0
start_time = time.time()
block_data_base = f'{height}:{ts}:{tx_hash}:{prev_hash}'

g = '\033[38;5;82m'
a = '\033[38;5;214m'
p = '\033[38;5;205m'
b = '\033[38;5;69m'
w = '\033[38;5;255m'
d = '\033[38;5;240m'
bold = '\033[1m'
x = '\033[0m'

print(f'{a}Mining block #{height}... (difficulty: {difficulty}, target: {target}...){x}', flush=True)

while True:
    block_data = f'{block_data_base}:{nonce}'
    block_hash = hashlib.sha256(block_data.encode()).hexdigest()

    if block_hash.startswith(target):
        elapsed = time.time() - start_time
        hashrate = nonce / elapsed if elapsed > 0 else 0

        # Build the block
        block = {
            'index': height,
            'timestamp': ts,
            'transactions': [coinbase_tx],
            'previous_hash': prev_hash,
            'nonce': nonce,
            'difficulty': difficulty,
            'miner': wallet_name,
            'hash': block_hash
        }

        # Append to chain
        chain['chain'].append(block)
        with open(chain_file, 'w') as f:
            json.dump(chain, f, indent=2)

        # Update wallet balance
        with open(wallet_file) as f:
            wallet = json.load(f)

        wallet['balance'] = wallet.get('balance', 0) + reward
        wallet['unbacked_balance'] = wallet.get('unbacked_balance', 0) + reward
        wallet['blocks_mined'] = wallet.get('blocks_mined', 0) + 1
        wallet['total_mined'] = wallet.get('total_mined', 0) + reward

        with open(wallet_file, 'w') as f:
            json.dump(wallet, f, indent=2)

        # Update mining stats
        stats_file = os.path.join(os.path.dirname(chain_file), 'mining-stats.json')
        try:
            with open(stats_file) as f:
                stats = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            stats = {'total_blocks_mined': 0, 'total_reward': 0, 'total_hashes': 0, 'sessions': []}

        stats['total_blocks_mined'] += 1
        stats['total_reward'] += reward
        stats['total_hashes'] += nonce
        stats['last_block'] = {
            'height': height,
            'hash': block_hash,
            'nonce': nonce,
            'reward': reward,
            'elapsed': elapsed,
            'hashrate': hashrate,
            'miner': wallet_name,
            'timestamp': ts
        }

        with open(stats_file, 'w') as f:
            json.dump(stats, f, indent=2)

        # Output
        print(f'{g}{"═" * 60}{x}')
        print(f'{bold}{p}  BLOCK MINED{x}')
        print(f'{g}{"═" * 60}{x}')
        print(f'  {w}Block:       #{height}{x}')
        print(f'  {w}Hash:        {block_hash[:32]}...{x}')
        print(f'  {w}Nonce:       {nonce:,}{x}')
        print(f'  {g}Reward:      {reward:.8f} ROAD{x}')
        print(f'  {w}Difficulty:  {difficulty} ({target}...){x}')
        print(f'  {w}Hashrate:    {hashrate:,.0f} H/s{x}')
        print(f'  {w}Time:        {elapsed:.2f}s{x}')
        print(f'  {w}Miner:       {wallet_name}{x}')
        print(f'{g}{"─" * 60}{x}')
        print(f'  {a}Halving:     every {halving_interval} blocks (current epoch: {halvings}){x}')
        print(f'  {a}Next halving: block #{(halvings + 1) * halving_interval} (in {(halvings + 1) * halving_interval - height} blocks){x}')
        print(f'  {a}Next reward: {reward / 2:.8f} ROAD{x}')
        print(f'{g}{"─" * 60}{x}')
        print(f'  {w}Wallet:      {wallet_name}{x}')
        print(f'  {g}Balance:     {wallet["balance"]:.8f} ROAD{x}')
        print(f'  {w}Total mined: {wallet.get("total_mined", reward):.8f} ROAD{x}')
        print(f'  {w}Blocks:      {wallet.get("blocks_mined", 1)}{x}')
        print(f'{g}{"═" * 60}{x}')
        break

    nonce += 1

    # Progress indicator every 100k hashes
    if nonce % 100000 == 0:
        elapsed = time.time() - start_time
        rate = nonce / elapsed if elapsed > 0 else 0
        print(f'  {d}  ...{nonce:,} hashes ({rate:,.0f} H/s){x}', flush=True)
PYEOF
}

# ═══════════════════════════════════════════════════════════
# MINE MULTIPLE BLOCKS
# ═══════════════════════════════════════════════════════════

cmd_mine() {
    local wallet_name="${1:-alexa}"
    local num_blocks="${2:-1}"

    echo -e "${BOLD}${PINK}RoadChain Miner${RESET}"
    echo -e "${GRAY}Wallet: ${wallet_name} | Blocks: ${num_blocks}${RESET}"
    echo ""

    for (( i=1; i<=num_blocks; i++ )); do
        echo -e "${AMBER}[${i}/${num_blocks}]${RESET}"
        mine_block "$wallet_name"
        echo ""
    done

    echo -e "${GREEN}Mining session complete: ${num_blocks} blocks${RESET}"
}

# ═══════════════════════════════════════════════════════════
# AUTO MINE — Continuous mining
# ═══════════════════════════════════════════════════════════

cmd_auto() {
    local wallet_name="${1:-alexa}"

    echo -e "${BOLD}${PINK}RoadChain Auto-Miner${RESET}"
    echo -e "${GRAY}Wallet: ${wallet_name} | Press Ctrl+C to stop${RESET}"
    echo ""

    local block_count=0
    trap 'echo -e "\n${GREEN}Auto-miner stopped. Mined ${block_count} blocks.${RESET}"; exit 0' INT

    while true; do
        mine_block "$wallet_name"
        block_count=$((block_count + 1))
        echo ""
        sleep 1
    done
}

# ═══════════════════════════════════════════════════════════
# MINING STATS
# ═══════════════════════════════════════════════════════════

cmd_stats() {
    python3 - "$CHAIN_FILE" "$WALLETS_DIR" "$INITIAL_REWARD" "$HALVING_INTERVAL" "$MAX_SUPPLY" << 'PYEOF'
import json, os, sys

chain_file = sys.argv[1]
wallets_dir = sys.argv[2]
initial_reward = float(sys.argv[3])
halving_interval = int(sys.argv[4])
max_supply = float(sys.argv[5])

with open(chain_file) as f:
    chain = json.load(f)

blocks = chain['chain']
height = len(blocks)

# Count mined blocks and rewards
mined_blocks = []
total_reward = 0
miners = {}

for b in blocks:
    for tx in b.get('transactions', []):
        if tx.get('type') == 'MINING_REWARD' or tx.get('sender') in ('ROADCHAIN', 'COINBASE'):
            total_reward += tx.get('amount', 0)
            miner = tx.get('recipient', b.get('miner', 'unknown'))
            miners[miner] = miners.get(miner, 0) + tx.get('amount', 0)
            if tx.get('type') == 'MINING_REWARD':
                mined_blocks.append(b)

# Current epoch
halvings = height // halving_interval
current_reward = initial_reward
for i in range(halvings):
    current_reward /= 2

remaining = max_supply - total_reward

g = '\033[38;5;82m'
a = '\033[38;5;214m'
p = '\033[38;5;205m'
b = '\033[38;5;69m'
w = '\033[38;5;255m'
d = '\033[38;5;240m'
bold = '\033[1m'
x = '\033[0m'

print(f'{g}{"═" * 60}{x}')
print(f'{bold}{p}  ROADCHAIN MINING STATS{x}')
print(f'{g}{"═" * 60}{x}')
print()
print(f'  {bold}{a}Chain{x}')
print(f'  {w}Block Height:       {height:,}{x}')
print(f'  {w}PoW Blocks Mined:   {len(mined_blocks):,}{x}')
print(f'  {w}Bridge Blocks:      {height - len(mined_blocks) - 2:,}{x}')
print()
print(f'  {bold}{a}Supply{x}')
print(f'  {w}Total Mined:        {total_reward:,.8f} ROAD{x}')
print(f'  {w}Max Supply:         {max_supply:,.8f} ROAD{x}')
print(f'  {w}Remaining:          {remaining:,.8f} ROAD{x}')
print(f'  {w}Mined %:            {(total_reward/max_supply)*100:.6f}%{x}')
print()
print(f'  {bold}{a}Rewards{x}')
print(f'  {w}Current Reward:     {current_reward:.8f} ROAD/block{x}')
print(f'  {w}Halving Epoch:      {halvings}{x}')
print(f'  {w}Next Halving:       Block #{(halvings+1)*halving_interval} (in {(halvings+1)*halving_interval - height} blocks){x}')
print(f'  {w}Post-halving Reward: {current_reward/2:.8f} ROAD/block{x}')
print()
print(f'  {bold}{a}Miners{x}')
for miner, amount in sorted(miners.items(), key=lambda x: -x[1]):
    print(f'  {w}  {miner:12s}  {amount:>14,.8f} ROAD{x}')
print()

# Stats file
stats_file = os.path.join(os.path.dirname(chain_file), 'mining-stats.json')
if os.path.exists(stats_file):
    with open(stats_file) as f:
        stats = json.load(f)
    lb = stats.get('last_block', {})
    if lb:
        print(f'  {bold}{a}Last Mined Block{x}')
        print(f'  {w}Height:     #{lb.get("height", "?")}{x}')
        print(f'  {w}Hash:       {lb.get("hash", "?")[:32]}...{x}')
        print(f'  {w}Nonce:      {lb.get("nonce", 0):,}{x}')
        print(f'  {w}Hashrate:   {lb.get("hashrate", 0):,.0f} H/s{x}')
        print(f'  {w}Time:       {lb.get("elapsed", 0):.2f}s{x}')

print(f'{g}{"═" * 60}{x}')
PYEOF
}

# ═══════════════════════════════════════════════════════════
# HALVING SCHEDULE
# ═══════════════════════════════════════════════════════════

cmd_halving() {
    python3 - "$CHAIN_FILE" "$INITIAL_REWARD" "$HALVING_INTERVAL" "$MAX_SUPPLY" << 'PYEOF'
import json, sys

chain_file = sys.argv[1]
initial_reward = float(sys.argv[2])
halving_interval = int(sys.argv[3])
max_supply = float(sys.argv[4])

with open(chain_file) as f:
    chain = json.load(f)
height = len(chain['chain'])

g = '\033[38;5;82m'
a = '\033[38;5;214m'
p = '\033[38;5;205m'
w = '\033[38;5;255m'
d = '\033[38;5;240m'
bold = '\033[1m'
x = '\033[0m'

print(f'{a}{"═" * 60}{x}')
print(f'{bold}{p}  ROADCOIN HALVING SCHEDULE{x}')
print(f'{a}{"═" * 60}{x}')
print(f'  {d}{"Epoch":<8} {"Block Range":<20} {"Reward/Block":<18} {"Epoch Supply":<15}{x}')
print(f'{a}{"─" * 60}{x}')

reward = initial_reward
cumulative = 0

for epoch in range(20):
    start = epoch * halving_interval
    end = start + halving_interval - 1
    epoch_supply = reward * halving_interval
    cumulative += epoch_supply

    if cumulative > max_supply:
        epoch_supply = max(0, max_supply - (cumulative - epoch_supply))
        cumulative = max_supply

    current = "  ◄ NOW" if start <= height <= end else ""
    color = g if start <= height <= end else w if cumulative < max_supply else d

    if reward < 0.00000001:
        print(f'  {d}{epoch:<8} {f"{start:,}-{end:,}":<20} {"0 (exhausted)":<18} {cumulative:>13,.2f}{x}')
        break

    print(f'  {color}{epoch:<8} {f"{start:,}-{end:,}":<20} {reward:<18.8f} {cumulative:>13,.2f}{current}{x}')
    reward /= 2

print(f'{a}{"─" * 60}{x}')
print(f'  {w}Max Supply:      {max_supply:>15,.2f} ROAD{x}')
print(f'  {w}Current Height:  {height:>15,}{x}')
print(f'{a}{"═" * 60}{x}')
PYEOF
}

# ═══════════════════════════════════════════════════════════
# DIFFICULTY INFO
# ═══════════════════════════════════════════════════════════

cmd_difficulty() {
    local diff
    diff=$(get_difficulty)

    python3 - "$CHAIN_FILE" "$diff" << 'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    chain = json.load(f)

diff = int(sys.argv[2])
blocks = chain['chain']

mined = [b for b in blocks if b.get('nonce', 0) > 0 and b.get('hash', '').startswith('0' * 4)]

a = '\033[38;5;214m'
g = '\033[38;5;82m'
p = '\033[38;5;205m'
w = '\033[38;5;255m'
d = '\033[38;5;240m'
bold = '\033[1m'
x = '\033[0m'

print(f'{a}{"═" * 50}{x}')
print(f'{bold}{p}  MINING DIFFICULTY{x}')
print(f'{a}{"═" * 50}{x}')
print(f'  {w}Current Difficulty:  {diff} ({"0" * diff}...){x}')
print(f'  {w}Search Space:        ~{16**diff:,} hashes avg{x}')
print(f'  {w}Target Block Time:   10s{x}')
print(f'  {w}Adjusts Every:       10 mined blocks{x}')
print(f'  {w}PoW Blocks Mined:    {len(mined)}{x}')

if len(mined) >= 2:
    times = []
    for i in range(1, len(mined)):
        dt = mined[i]['timestamp'] - mined[i-1]['timestamp']
        times.append(dt)
    avg = sum(times) / len(times)
    print(f'  {w}Avg Block Time:      {avg:.2f}s{x}')

print(f'{a}{"═" * 50}{x}')
PYEOF
}

# ═══════════════════════════════════════════════════════════
# DAEMON MODE
# ═══════════════════════════════════════════════════════════

cmd_daemon() {
    local wallet_name="${1:-alexa}"

    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo -e "${AMBER}Miner daemon already running (PID: $(cat "$PID_FILE"))${RESET}"
        return 1
    fi

    echo -e "${GREEN}Starting mining daemon for wallet: ${wallet_name}${RESET}"
    echo -e "${GRAY}Log: ${MINING_LOG}${RESET}"

    (
        while true; do
            mine_block "$wallet_name" >> "$MINING_LOG" 2>&1
            sleep 2
        done
    ) &

    echo $! > "$PID_FILE"
    echo -e "${GREEN}Miner daemon started (PID: $!)${RESET}"
}

cmd_stop() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PID_FILE"
            echo -e "${GREEN}Miner daemon stopped (PID: $pid)${RESET}"
        else
            rm -f "$PID_FILE"
            echo -e "${AMBER}Daemon was not running${RESET}"
        fi
    else
        echo -e "${GRAY}No daemon running${RESET}"
    fi
}

# ═══════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════

case "${1:-help}" in
    mine)       cmd_mine "${2:-alexa}" "${3:-1}" ;;
    auto)       cmd_auto "${2:-alexa}" ;;
    stats)      cmd_stats ;;
    difficulty)  cmd_difficulty ;;
    halving)    cmd_halving ;;
    daemon)     cmd_daemon "${2:-alexa}" ;;
    stop)       cmd_stop ;;
    help|--help|-h)
        echo -e "${BOLD}${PINK}RoadChain Miner${RESET}"
        echo ""
        echo -e "  ${GREEN}mine${RESET} [wallet] [count]   Mine blocks (default: 1)"
        echo -e "  ${GREEN}auto${RESET} [wallet]           Continuous mining (Ctrl+C to stop)"
        echo -e "  ${GREEN}stats${RESET}                   Mining statistics"
        echo -e "  ${GREEN}difficulty${RESET}              Current difficulty info"
        echo -e "  ${GREEN}halving${RESET}                 Halving schedule"
        echo -e "  ${GREEN}daemon${RESET} [wallet]         Background mining daemon"
        echo -e "  ${GREEN}stop${RESET}                    Stop mining daemon"
        echo ""
        echo -e "  ${GRAY}Max supply: 21,000,000 ROAD | Halving every 210 blocks${RESET}"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${RESET}"
        echo "Run: $0 help"
        exit 1
        ;;
esac
