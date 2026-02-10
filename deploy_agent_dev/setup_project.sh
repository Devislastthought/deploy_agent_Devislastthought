#!/usr/bin/env bash

set -e

# ===============================
# Automated Project Bootstrapper
# ===============================

read -p "Enter project name: " INPUT
BASE_DIR="attendance_tracker_${INPUT}"
ARCHIVE="attendance_tracker_${INPUT}_archive.tar.gz"

# -------------------------------
# TRAP: Handle Ctrl + C
# -------------------------------
cleanup() {
    echo ""
    echo "⚠️ Script interrupted. Archiving project..."

    if [ -d "$BASE_DIR" ]; then
        # Bundle the current state of the project
        tar -czf "$ARCHIVE" "$BASE_DIR"
        # Remove incomplete directory
        rm -rf "$BASE_DIR"
        echo "📦 Archive created: $ARCHIVE"
        echo "🧹 Incomplete directory removed"
    fi
    exit 1
}

trap cleanup SIGINT

# -------------------------------
# CREATE DIRECTORY STRUCTURE
# -------------------------------
echo "📁 Creating directory architecture..."
mkdir -p "$BASE_DIR/Helpers"
mkdir -p "$BASE_DIR/reports"

# -------------------------------
# CREATE attendance_checker.py
# -------------------------------
cat <<'EOF' > "$BASE_DIR/attendance_checker.py"
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            attendance_pct = (attended / total_sessions) * 100
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

# -------------------------------
# CREATE assets.csv
# -------------------------------
cat <<'EOF' > "$BASE_DIR/Helpers/assets.csv"
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

# -------------------------------
# CREATE config.json
# -------------------------------
cat <<'EOF' > "$BASE_DIR/Helpers/config.json"
{
  "thresholds": {
    "warning": 75,
    "failure": 50
  },
  "run_mode": "live",
  "total_sessions": 15
}
EOF

# -------------------------------
# CREATE reports.log
# -------------------------------
touch "$BASE_DIR/reports/reports.log"

# -------------------------------
# DYNAMIC CONFIGURATION (sed)
# -------------------------------
read -p "Do you want to update attendance thresholds? (y/n): " CHOICE

if [ "$CHOICE" = "y" ]; then
    read -p "Enter Warning threshold (default 75): " WARNING
    read -p "Enter Failure threshold (default 50): " FAILURE

    WARNING=${WARNING:-75}
    FAILURE=${FAILURE:-50}

    sed -i "s/\"warning\": [0-9]\+/\"warning\": $WARNING/" "$BASE_DIR/Helpers/config.json"
    sed -i "s/\"failure\": [0-9]\+/\"failure\": $FAILURE/" "$BASE_DIR/Helpers/config.json"

    echo "✅ Thresholds updated in config.json"
fi

# -------------------------------
# ENVIRONMENT HEALTH CHECK
# -------------------------------
echo "🔍 Checking Python installation..."

if python3 --version >/dev/null 2>&1; then
    echo "✅ Python3 is installed"
else
    echo "⚠️ Warning: Python3 is not installed"
fi

# -------------------------------
# FINAL VALIDATION
# -------------------------------
echo "🔎 Validating directory structure..."

if [ -f "$BASE_DIR/attendance_checker.py" ] &&
   [ -f "$BASE_DIR/Helpers/assets.csv" ] &&
   [ -f "$BASE_DIR/Helpers/config.json" ] &&
   [ -f "$BASE_DIR/reports/reports.log" ]; then
    echo "🎉 Project setup completed successfully"
else
    echo "❌ Validation failed"
fi

