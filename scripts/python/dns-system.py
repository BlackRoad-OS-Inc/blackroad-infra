#!/usr/bin/env python3
"""
BLACKROAD DNS - ALL TRAFFIC ROUTES THROUGH BLACKROAD
No upstream DNS. Everything is BlackRoad.
"""

import socket
import subprocess
import threading
import struct
import os

LISTEN_PORT = 53

# BlackRoad login state
BLACKROAD_AUTHENTICATED = os.environ.get('BLACKROAD_AUTH', '0') == '1'

def blackroad_login():
    """BlackRoad authentication gate"""
    print("\n╔═══════════════════════════════════════╗")
    print("║         BLACKROAD LOGIN               ║")
    print("╚═══════════════════════════════════════╝")
    return True  # Always allow for now - add auth later

def query_claude(name):
    """Route to Claude CLI"""
    try:
        result = subprocess.run(
            ["claude", "--print", f"DNS query for: {name}"],
            capture_output=True, text=True, timeout=30
        )
        return result.stdout.strip() if result.stdout else "BLACKROAD: no response"
    except Exception as e:
        return f"BLACKROAD: {e}"

def build_dns_response(query_data, ip_address):
    """Build a DNS response pointing to our IP"""
    # Transaction ID from query
    transaction_id = query_data[:2]

    # Flags: standard response, no error
    flags = b'\x81\x80'

    # Questions: 1, Answers: 1, Authority: 0, Additional: 0
    counts = b'\x00\x01\x00\x01\x00\x00\x00\x00'

    # Copy question section from query
    question_end = 12
    while query_data[question_end] != 0:
        question_end += query_data[question_end] + 1
    question_end += 5  # null byte + qtype (2) + qclass (2)
    question = query_data[12:question_end]

    # Answer: pointer to name + type A + class IN + TTL + rdlength + IP
    answer = b'\xc0\x0c'  # Pointer to name in question
    answer += b'\x00\x01'  # Type A
    answer += b'\x00\x01'  # Class IN
    answer += b'\x00\x00\x00\x3c'  # TTL 60 seconds
    answer += b'\x00\x04'  # rdlength 4

    # Convert IP to bytes
    ip_parts = ip_address.split('.')
    answer += bytes([int(p) for p in ip_parts])

    return transaction_id + flags + counts + question + answer

def handle_query(data, addr, sock):
    """Handle DNS query - ALL traffic goes through BlackRoad"""
    # Parse domain name from query
    pos = 12
    labels = []
    try:
        while pos < len(data) and data[pos] != 0:
            length = data[pos]
            labels.append(data[pos+1:pos+1+length].decode('utf-8', errors='ignore'))
            pos += length + 1
    except:
        pass

    name = '.'.join(labels).lower()

    print(f"\n[BLACKROAD DNS] Query: {name}")
    print(f"  -> ALL TRAFFIC ROUTES THROUGH BLACKROAD")

    # Log to Claude what's being accessed
    response_text = query_claude(name)
    print(f"  <- Claude: {response_text[:100]}...")

    # Return BlackRoad's IP for EVERYTHING
    # This means all domains resolve to BlackRoad
    # The actual routing/proxy happens at the web layer
    BLACKROAD_IP = "127.0.0.1"  # Local BlackRoad gateway

    try:
        response = build_dns_response(data, BLACKROAD_IP)
        sock.sendto(response, addr)
        print(f"  -> Resolved {name} to {BLACKROAD_IP} (BLACKROAD)")
    except Exception as e:
        print(f"  ERROR: {e}")
        # Send NXDOMAIN on error
        nxdomain = bytearray(data[:12])
        nxdomain[2] = 0x81
        nxdomain[3] = 0x83
        sock.sendto(bytes(nxdomain) + data[12:], addr)

def main():
    print("╔═══════════════════════════════════════╗")
    print("║   BLACKROAD DNS - ALL IS BLACKROAD    ║")
    print("╚═══════════════════════════════════════╝")
    print("")
    print("NO UPSTREAM DNS. EVERYTHING ROUTES HERE.")
    print("google.com -> BLACKROAD")
    print("facebook.com -> BLACKROAD")
    print("*.* -> BLACKROAD")
    print("")

    if not blackroad_login():
        print("BLACKROAD: Authentication required")
        return

    print("BLACKROAD: Authenticated")
    print("")

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    try:
        sock.bind(('127.0.0.1', LISTEN_PORT))
    except PermissionError:
        print(f"ERROR: Need sudo for port {LISTEN_PORT}")
        print("Run: sudo python3 ~/blackroad-dns-system.py")
        return

    print(f"Listening on 127.0.0.1:{LISTEN_PORT}")
    print("All DNS queries now route through BlackRoad + Claude")
    print("")

    while True:
        data, addr = sock.recvfrom(4096)
        thread = threading.Thread(target=handle_query, args=(data, addr, sock))
        thread.daemon = True
        thread.start()

if __name__ == "__main__":
    main()
