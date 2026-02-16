Attendance Tracker

Hey! This tool helps you track attendance, generate reports, and alert people if their attendance is low. It’s simple, runs on Bash + Python, and takes care of setting up everything automatically.

What it does

Creates a clean project folder with all the files you need.

Checks attendance from a CSV file (Helpers/assets.csv).

Sends alerts if someone’s attendance is below the warning or failure threshold.

Saves logs in reports/reports.log and timestamps old reports.

If you stop the script midway, it archives the current project so you don’t lose work.

How to use it

Run the script:

./your_script_name.sh


Enter a project name when asked.
The folder will look like attendance_tracker_<yourproject>.

Update thresholds (optional):

Type y when prompted.

Enter new Warning or Failure percentages, or press Enter to keep defaults (Warning = 75%, Failure = 50%).

Check attendance:

python3 attendance_checker.py


In live mode, alerts are written to reports/reports.log.

In dry run mode, messages are just printed no alerts are sent.

What happens if you stop the script

If you hit Ctrl+C while the script is running:

The script saves everything that’s been created into an archive named attendance_tracker_<yourproject>_archive.

It cleans up the incomplete folder so your workspace stays tidy.

The incomplete folder is deleted to keep your workspace tidy.
