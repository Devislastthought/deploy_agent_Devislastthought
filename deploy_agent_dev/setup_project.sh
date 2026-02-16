#!/usr/bin/bash 

set -e

read -p "Enter project name: " INPUT
ROOT_DIR="attendance_tracker_${INPUT}"
ARCHIVE="attendance_tracker_${INPUT}_archive"

cleanup() {
    echo ""
    echo "Script interrupted. Archiving project..."

    if [ -d "$ROOT_DIR" ]; then
        # Group the current state of the project
        tar -czf "$ARCHIVE" "$ROOT_DIR"
        # Remove incomplete directory
        rm -rf "$ROOT_DIR"
        echo "Archive created: $ARCHIVE"
        echo "Incomplete directory removed"
    fi
    exit 1
}

trap cleanup SIGINT

# creating a directory
echo " Creating directory architecture !!!!"
mkdir -p "$ROOT_DIR/Helpers"
mkdir -p "$ROOT_DIR/reports"

# creating attendance checker file
cat <<'EOF' > "$ROOT_DIR/attendance_checker.py"
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

# Creating assets
cat <<'EOF' > "$ROOT_DIR/Helpers/assets.csv"
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

# Creating config file
cat <<'EOF' > "$ROOT_DIR/Helpers/config.json"
{
  "thresholds": {
    "warning": 75,
    "failure": 50
  },
  "run_mode": "live",
  "total_sessions": 15
}
EOF

# creating reports file
touch "$ROOT_DIR/reports/reports.log"

# Accepting or denying
read -p "Do you want to update attendance thresholds? (y/n): " CHOICE

if [ "$CHOICE" = "y" ]; then
    read -p "Enter Warning thresholds (default 75): " WARNING
    read -p "Enter Failure thresholds (default 50): " FAILURE

    WARNING=${WARNING:-75}
    FAILURE=${FAILURE:-50}

    sed -i "s/\"warning\": [0-9]\+/\"warning\": $WARNING/" "$ROOT_DIR/Helpers/config.json"
    sed -i "s/\"failure\": [0-9]\+/\"failure\": $FAILURE/" "$ROOT_DIR/Helpers/config.json"

    echo "thresholds updated"
fi

echo "Checking if python is installed ... "

if python3 --version >/dev/null 2>&1; then
    echo "Python3 is installed"
else
    echo "Warning: Python3 is not installed. please install python i beg"
fi

# final validation
echo " Checking directory structure.."

if [ -f "$ROOT_DIR/attendance_checker.py" ] &&
   [ -f "$ROOT_DIR/Helpers/assets.csv" ] &&
   [ -f "$ROOT_DIR/Helpers/config.json" ] &&
   [ -f "$ROOT_DIR/reports/reports.log" ]; then
    echo " Project setup completed successfully"
else
    echo "ooh noooo!!!!!  Validation failed"
fi
