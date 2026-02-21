#!/usr/bin/env python3
"""
BlackRoad Memory Index Auto-Update Daemon
Watches journal file and automatically updates search index when new entries are added.
"""

import os
import sys
import time
import signal
import subprocess
from pathlib import Path
from datetime import datetime
import hashlib

# Configuration
MEMORY_DIR = Path.home() / ".blackroad" / "memory"
JOURNAL_FILE = MEMORY_DIR / "journals" / "master-journal.jsonl"
INDEX_DB = MEMORY_DIR / "memory-index.db"
PID_FILE = MEMORY_DIR / "memory-index-daemon.pid"
LOG_FILE = MEMORY_DIR / "memory-index-daemon.log"
INDEXER_SCRIPT = Path.home() / "memory-indexer.py"

# Settings
CHECK_INTERVAL = 5  # seconds between checks
BATCH_DELAY = 2     # seconds to wait before indexing (batch multiple writes)

# ANSI Colors
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
CYAN = '\033[0;36m'
RED = '\033[0;31m'
NC = '\033[0m'

class MemoryIndexDaemon:
    def __init__(self):
        self.running = False
        self.last_size = 0
        self.last_mtime = 0
        self.pending_update = False
        self.update_scheduled_at = 0
        
    def log(self, message, level="INFO"):
        """Log message to file and optionally stdout"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}\n"
        
        # Write to log file
        try:
            with open(LOG_FILE, 'a') as f:
                f.write(log_entry)
        except Exception as e:
            print(f"Failed to write log: {e}", file=sys.stderr)
        
        # Also print if running in foreground
        if not self.is_background():
            print(f"{CYAN}[{level}]{NC} {message}")
    
    def is_background(self):
        """Check if running in background"""
        return os.getppid() != os.getpgrp()
    
    def write_pid(self):
        """Write PID file"""
        try:
            with open(PID_FILE, 'w') as f:
                f.write(str(os.getpid()))
            self.log(f"PID file created: {PID_FILE}")
        except Exception as e:
            self.log(f"Failed to create PID file: {e}", "ERROR")
    
    def remove_pid(self):
        """Remove PID file"""
        try:
            if PID_FILE.exists():
                PID_FILE.unlink()
                self.log("PID file removed")
        except Exception as e:
            self.log(f"Failed to remove PID file: {e}", "WARNING")
    
    def check_already_running(self):
        """Check if daemon is already running"""
        if not PID_FILE.exists():
            return False
        
        try:
            with open(PID_FILE, 'r') as f:
                pid = int(f.read().strip())
            
            # Check if process exists
            try:
                os.kill(pid, 0)  # Doesn't actually kill, just checks
                return True
            except OSError:
                # Process doesn't exist, remove stale PID file
                PID_FILE.unlink()
                return False
        except Exception:
            return False
    
    def get_file_info(self):
        """Get journal file size and modification time"""
        if not JOURNAL_FILE.exists():
            return 0, 0
        
        stat = JOURNAL_FILE.stat()
        return stat.st_size, stat.st_mtime
    
    def run_indexer(self):
        """Run memory-indexer.py update"""
        try:
            self.log("Running index update...")
            result = subprocess.run(
                [sys.executable, str(INDEXER_SCRIPT), 'update'],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                # Parse output for indexed count
                output = result.stdout
                if 'new entries' in output:
                    for line in output.split('\n'):
                        if 'Indexed' in line and 'new entries' in line:
                            self.log(f"✓ {line.strip()}")
                            break
                else:
                    self.log("✓ Index updated (no new entries)")
            else:
                self.log(f"Indexer failed: {result.stderr}", "ERROR")
                
        except subprocess.TimeoutExpired:
            self.log("Indexer timeout", "ERROR")
        except Exception as e:
            self.log(f"Indexer error: {e}", "ERROR")
    
    def check_and_update(self):
        """Check for changes and schedule update if needed"""
        current_size, current_mtime = self.get_file_info()
        
        # Check if file has changed
        if current_size != self.last_size or current_mtime != self.last_mtime:
            if not self.pending_update:
                self.log(f"Journal changed (size: {current_size} bytes)")
                self.pending_update = True
                self.update_scheduled_at = time.time() + BATCH_DELAY
            
            self.last_size = current_size
            self.last_mtime = current_mtime
        
        # Check if it's time to run scheduled update
        if self.pending_update and time.time() >= self.update_scheduled_at:
            self.run_indexer()
            self.pending_update = False
            self.update_scheduled_at = 0
    
    def signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        self.log(f"Received signal {signum}, shutting down...")
        self.running = False
    
    def start(self, foreground=False):
        """Start the daemon"""
        # Check if already running
        if self.check_already_running():
            print(f"{RED}[✗]{NC} Daemon already running")
            return 1
        
        # Check dependencies
        if not INDEXER_SCRIPT.exists():
            print(f"{RED}[✗]{NC} Indexer script not found: {INDEXER_SCRIPT}")
            return 1
        
        if not JOURNAL_FILE.exists():
            print(f"{YELLOW}[!]{NC} Journal file not found, will wait for it")
        
        # Setup signal handlers
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        # Write PID file
        self.write_pid()
        
        # Initialize state
        self.last_size, self.last_mtime = self.get_file_info()
        self.running = True
        
        self.log("=" * 60)
        self.log("Memory Index Daemon Started")
        self.log(f"Watching: {JOURNAL_FILE}")
        self.log(f"Check interval: {CHECK_INTERVAL}s")
        self.log(f"Batch delay: {BATCH_DELAY}s")
        self.log("=" * 60)
        
        if not foreground:
            print(f"{GREEN}[✓]{NC} Memory index daemon started")
            print(f"{CYAN}[→]{NC} PID: {os.getpid()}")
            print(f"{CYAN}[→]{NC} Log: {LOG_FILE}")
        
        # Main loop
        try:
            while self.running:
                self.check_and_update()
                time.sleep(CHECK_INTERVAL)
        except KeyboardInterrupt:
            self.log("Interrupted by user")
        finally:
            self.log("Daemon stopped")
            self.remove_pid()
        
        return 0

def stop_daemon():
    """Stop running daemon"""
    if not PID_FILE.exists():
        print(f"{YELLOW}[!]{NC} Daemon not running (no PID file)")
        return 1
    
    try:
        with open(PID_FILE, 'r') as f:
            pid = int(f.read().strip())
        
        print(f"{CYAN}[→]{NC} Stopping daemon (PID: {pid})...")
        os.kill(pid, signal.SIGTERM)
        
        # Wait for process to exit
        for _ in range(10):
            try:
                os.kill(pid, 0)
                time.sleep(0.5)
            except OSError:
                break
        
        print(f"{GREEN}[✓]{NC} Daemon stopped")
        return 0
        
    except Exception as e:
        print(f"{RED}[✗]{NC} Failed to stop daemon: {e}")
        return 1

def status_daemon():
    """Check daemon status"""
    if not PID_FILE.exists():
        print(f"{YELLOW}[STATUS]{NC} Daemon is not running")
        return 1
    
    try:
        with open(PID_FILE, 'r') as f:
            pid = int(f.read().strip())
        
        try:
            os.kill(pid, 0)
            print(f"{GREEN}[STATUS]{NC} Daemon is running")
            print(f"{CYAN}[→]{NC} PID: {pid}")
            print(f"{CYAN}[→]{NC} Log: {LOG_FILE}")
            
            # Show recent log entries
            if LOG_FILE.exists():
                print(f"\n{CYAN}Recent log entries:{NC}")
                with open(LOG_FILE, 'r') as f:
                    lines = f.readlines()
                    for line in lines[-5:]:
                        print(f"  {line.rstrip()}")
            
            return 0
        except OSError:
            print(f"{YELLOW}[STATUS]{NC} Daemon not running (stale PID file)")
            PID_FILE.unlink()
            return 1
            
    except Exception as e:
        print(f"{RED}[✗]{NC} Error checking status: {e}")
        return 1

def show_logs(follow=False, lines=20):
    """Show daemon logs"""
    if not LOG_FILE.exists():
        print(f"{YELLOW}[!]{NC} No log file found: {LOG_FILE}")
        return 1
    
    if follow:
        # Follow mode (like tail -f)
        try:
            with open(LOG_FILE, 'r') as f:
                # Go to end
                f.seek(0, 2)
                print(f"{CYAN}Following log (Ctrl+C to stop):{NC}\n")
                
                while True:
                    line = f.readline()
                    if line:
                        print(line.rstrip())
                    else:
                        time.sleep(0.1)
        except KeyboardInterrupt:
            print(f"\n{CYAN}[→]{NC} Stopped following")
        return 0
    else:
        # Show last N lines
        with open(LOG_FILE, 'r') as f:
            all_lines = f.readlines()
            recent = all_lines[-lines:] if len(all_lines) > lines else all_lines
            
            print(f"{CYAN}Last {len(recent)} log entries:{NC}\n")
            for line in recent:
                print(line.rstrip())
        return 0

def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Memory Index Auto-Update Daemon",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  memory-index-daemon.py start              # Start daemon in background
  memory-index-daemon.py start --foreground # Start in foreground (testing)
  memory-index-daemon.py stop               # Stop daemon
  memory-index-daemon.py status             # Check if running
  memory-index-daemon.py logs               # Show recent logs
  memory-index-daemon.py logs --follow      # Follow logs in real-time
        """
    )
    
    parser.add_argument('command', choices=['start', 'stop', 'status', 'logs', 'restart'],
                        help='Command to execute')
    parser.add_argument('--foreground', '-f', action='store_true',
                        help='Run in foreground (for start command)')
    parser.add_argument('--follow', action='store_true',
                        help='Follow logs in real-time (for logs command)')
    parser.add_argument('--lines', '-n', type=int, default=20,
                        help='Number of log lines to show (default: 20)')
    
    args = parser.parse_args()
    
    # Ensure memory directory exists
    MEMORY_DIR.mkdir(parents=True, exist_ok=True)
    
    if args.command == 'start':
        daemon = MemoryIndexDaemon()
        
        if args.foreground:
            return daemon.start(foreground=True)
        else:
            # Daemonize
            pid = os.fork()
            if pid > 0:
                # Parent process
                return 0
            
            # Child process continues
            os.setsid()
            return daemon.start(foreground=False)
            
    elif args.command == 'stop':
        return stop_daemon()
        
    elif args.command == 'status':
        return status_daemon()
        
    elif args.command == 'logs':
        return show_logs(follow=args.follow, lines=args.lines)
        
    elif args.command == 'restart':
        print(f"{CYAN}[→]{NC} Restarting daemon...")
        stop_daemon()
        time.sleep(1)
        daemon = MemoryIndexDaemon()
        
        # Fork for background
        pid = os.fork()
        if pid > 0:
            return 0
        os.setsid()
        return daemon.start(foreground=False)

if __name__ == '__main__':
    sys.exit(main())
