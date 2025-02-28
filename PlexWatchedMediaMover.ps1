# Set API key and base URL
$apiKey = "860628d54c224533b70a3a176a75973d"
$baseUrl = "http://localhost:8181/api/v2"

# Configurable variables
$length = 1000  # Number of items to query
$watchedThreshold = 85  # Watched percentage to qualify for moving
$sourceDrive = "Z:"  # Source media drive (where Plex stores media)
$destinationDrive = "E:\Archived_Media"  # Destination drive for watched content
$logFile = "C:\watched_content_log.txt"  # Log file location
$movedLog = "C:\moved_files_log.txt"  # Tracks moved files

# Log setup
$dateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"=========================" | Out-File -Append $logFile
"Log Time: $dateTime" | Out-File -Append $logFile
"=========================" | Out-File -Append $logFile

# Fetch watched movies & episodes
$moviesUrl = "$baseUrl/?apikey=$apiKey&cmd=get_history&length=$length&media_type=movie"
$tvUrl = "$baseUrl/?apikey=$apiKey&cmd=get_history&length=$length&media_type=episode"

Write-Output "Fetching watched media..."
Write-Output "Fetching watched movies..."
$moviesResponse = Invoke-RestMethod -Uri $moviesUrl -Method Get
Write-Output "Fetching watched TV episodes..."
$tvResponse = Invoke-RestMethod -Uri $tvUrl -Method Get

# Merge results
$watchedItems = @()
if ($moviesResponse.response.data.data) { $watchedItems += $moviesResponse.response.data.data }
if ($tvResponse.response.data.data) { $watchedItems += $tvResponse.response.data.data }

# Filter: Only keep items with percent_complete >= threshold
$filteredItems = $watchedItems | Where-Object { $_.percent_complete -ge $watchedThreshold }
Write-Output "Found $($filteredItems.Count) watched items."
"Found $($filteredItems.Count) watched items." | Out-File -Append $logFile

# Fetch file paths
$validItems = @()
$movedFiles = @()
if (Test-Path $movedLog) { $movedFiles = Get-Content $movedLog }

Write-Output "Fetching File Paths for Watched Media..."
foreach ($item in $filteredItems) {
    $metadataUrl = "$baseUrl/?apikey=$apiKey&cmd=get_metadata&rating_key=$($item.rating_key)"
    "Metadata API Call: $metadataUrl" | Out-File -Append $logFile
    "Processing: $($item.full_title)" | Out-File -Append $logFile
    "Rating Key: $($item.rating_key)" | Out-File -Append $logFile
    
    try {
        $metadataResponse = Invoke-RestMethod -Uri $metadataUrl -Method Get
        
        if ($metadataResponse.response.data.media_info -and $metadataResponse.response.data.media_info[0].parts) {
            $filePath = $metadataResponse.response.data.media_info[0].parts[0].file
            if (![string]::IsNullOrEmpty($filePath) -and -not ($movedFiles -contains $filePath)) {
                $validItems += [PSCustomObject]@{ Title = $item.full_title; FilePath = $filePath }
            }
            "File Path Found: $filePath" | Out-File -Append $logFile
        } else {
            "Skipping: No file path found for '$($item.full_title)'." | Out-File -Append $logFile
        }
    } catch {
        "ERROR: Failed to fetch file path for '$($item.full_title)' - $($_.Exception.Message)" | Out-File -Append $logFile
    }
}

Write-Output "Found $($validItems.Count) files eligible for moving."
"Found $($validItems.Count) files eligible for moving." | Out-File -Append $logFile

if ($validItems.Count -gt 0) {
    "Eligible Files:" | Out-File -Append $logFile
    $validItems | ForEach-Object { "- $($_.Title) : $($_.FilePath)" | Out-File -Append $logFile }
}

# Move files to cold storage
$filesMoved = 0
foreach ($item in $validItems) {
    $relativePath = $item.FilePath -replace [regex]::Escape($sourceDrive), ""
    $destinationPath = "$destinationDrive$relativePath"
    $destinationFolder = Split-Path -Parent $destinationPath
    
    if (-not (Test-Path $destinationFolder)) { New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null }
    
    try {
        Move-Item -Path $item.FilePath -Destination $destinationPath -Force
        Write-Output "Moved: $($item.FilePath)"
        "$($item.FilePath)" | Out-File -Append $movedLog
        $filesMoved++
    } catch {}
}

Write-Output "$filesMoved files successfully moved."
"$filesMoved files successfully moved." | Out-File -Append $logFile
