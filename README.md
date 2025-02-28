# Plex Watched Media Mover

## Overview
This PowerShell script automates the process of moving **watched** movies and TV episodes from a primary media storage drive to a **cold storage** drive. It utilises **Tautulli's API** to identify watched media and moves the files accordingly while maintaining logs.

## Features
- Fetches **watched media** from Plex via **Tautulli**
- Logs and lists **watched items**
- Retrieves **file paths** for watched content
- Moves **valid** watched files to cold storage
- Skips files that have **no file path** or have already been moved
- Generates detailed logs with **metadata API calls, processed items, and movement actions**

## Requirements
- **Windows 10 or later** (PowerShell required)
- **Plex Media Server**
- **Tautulli** running on the same network
- **Tautulli API Key** (See below for setup)

## Setup
### Configure Tautulli API Key
1. Open **Tautulli**
2. Navigate to **Settings > Web Interface > API**
3. Copy the **API Key** and replace it in the script:
   ```powershell
   $apiKey = "YOUR_TAUTULLI_API_KEY"
   ```

### Modify Configuration Variables
Modify these settings to fit your Plex setup:
```powershell
$length = 1000  # Number of items to query
$watchedThreshold = 85  # Watched percentage to qualify for moving
$sourceDrive = "Z:"  # Source media drive
$destinationDrive = "E:\Archived_Media"  # Destination cold storage drive
$logFile = "C:\watched_content_log.txt"  # Log file location
$movedLog = "C:\moved_files_log.txt"  # Moved files tracking
```

## How It Works
### Fetch Watched Media
- Queries Tautulli for **movies & TV episodes** with a **watched status ≥ 85%**
- Logs **watched media count** and **rating keys**

### Retrieve File Paths
- Calls the **Tautulli metadata API** for each watched item
- Extracts the **file path** (if available)
- Skips items with **no file path**

### Move Files to Cold Storage
- Ensures the **destination folder** exists
- Moves **valid files** from `Z:` to `E:\Archived_Media`
- Updates the **moved files log** to prevent duplicates

## Running the Script
### Manual Execution
Run the script in **PowerShell**:
```powershell
.\PlexWatchedMover.ps1
```

### Automate with Task Scheduler
1. Open **Task Scheduler**
2. Create a new **Basic Task**
3. Set **Trigger** (e.g., **daily at midnight**)
4. Set **Action** > **Start a program**
5. Browse to the **PowerShell script** and select it
6. Click **Finish**

## Logs & Tracking
The script generates logs in:
- **Watched media log**: `C:\watched_content_log.txt`
- **Moved files log**: `C:\moved_files_log.txt`

Example log entry:
```
=========================
Log Time: 2025-02-28 18:30:45
=========================
Found 35 watched items.
Metadata API Call: http://localhost:8181/api/v2/?apikey=xxxx&cmd=get_metadata&rating_key=12345
Processing: Breaking Bad - Episode 5
Rating Key: 12345
File Path Found: Z:\TV Shows\Breaking Bad\Season 01\Episode 05.mkv
Found 10 files eligible for moving.
Eligible Files:
- Breaking Bad - Episode 5 : Z:\TV Shows\Breaking Bad\Season 01\Episode 05.mkv
10 files successfully moved.
```

## Troubleshooting
### Tautulli API Not Responding
- Ensure **Tautulli is running** and **API Key is correct**
- Try opening **http://localhost:8181/api/v2** in a browser

### Files Not Moving
- Check **log file** for errors
- Ensure **source and destination drives** exist
- Run PowerShell as **Administrator**

### Skipping Files Unexpectedly
- If a file is **already in moved log**, it will be skipped
- If Plex library **renamed/moved** the file, rescan the library

## Contributing
Feel free to fork, modify, and improve the script! Submit PRs on **GitHub** to add features or fixes.

## License
This script is open-source under the **MIT License**.

---

