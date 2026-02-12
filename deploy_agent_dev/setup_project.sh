#!/usr/bin/env bash

set -e

read -p "Enter project name: " INPUT
BASE_DIR="attendance_tracker_${INPUT}"
ARCHIVE="attendance_tracker_${INPUT}_archive.tar.gz"

cleanup() {
    echo ""
    echo "Script interrupted. Archiving project..."

    if [ -d "$BASE_DIR" ]; then
        # Group the current state of the project
        tar -czf "$ARCHIVE" "$BASE_DIR"
        # Remove incomplete directory
        rm -rf "$BASE_DIR"
        echo "Archive created: $ARCHIVE"
        echo "Incomplete directory removed"
    fi
    exit 1
}

trap cleanup SIGINT

# creating a directory
echo " Creating directory architecture !!!!"
mkdir -p "$BASE_DIR/Helpers"
mkdir -p "$BASE_DIR/reports"

# creating attendance checker file
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
            if attendance_pct < config['level']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['level']['warning']:
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
# Creating assets

cat <<'EOF' > "$BASE_DIR/Helpers/assets.csv"
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

#
# Creating config file
cat <<'EOF' > "$BASE_DIR/Helpers/config.json"
{
  "level": {
    "warning": 75,
    "failure": 50
  },
  "run_mode": "live",
  "total_sessions": 15
}
EOF

# creating  reports file
touch "$BASE_DIR/reports/reports.log"

# Accepting or denying 
read -p "Do you want to update attendance level? (y/n): " CHOICE

if [ "$CHOICE" = "y" ]; then
    read -p "Enter Warning level (default 75): " WARNING
    read -p "Enter Failure level (default 50): " FAILURE

    WARNING=${WARNING:-75}
    FAILURE=${FAILURE:-50}

    sed -i "s/\"warning\": [0-9]\+/\"warning\": $WARNING/" "$BASE_DIR/Helpers/config.json"
    sed -i "s/\"failure\": [0-9]\+/\"failure\": $FAILURE/" "$BASE_DIR/Helpers/config.json"

    echo "level updated"
fi

echo "Checking if python is installed ... "

if python3 --version >/dev/null 2>&1; then
    echo "Python3 is installed"
else
    echo "Warning: Python3 is not installed. please install python i beg "
fi

# final validation
echo " Checking directory structure.."

if [ -f "$BASE_DIR/attendance_checker.py" ] &&
   [ -f "$BASE_DIR/Helpers/assets.csv" ] &&
   [ -f "$BASE_DIR/Helpers/config.json" ] &&
   [ -f "$BASE_DIR/reports/reports.log" ]; then
    echo " Project setup completed successfully"
else
    echo "ooh noooo!!!!!  Validation failed"
fi

