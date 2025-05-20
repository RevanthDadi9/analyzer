# Script to back up specified project files and folders, and then clean up old backups.

# --- Script Parameters ---
# This block defines inputs the script can accept when you run it.
Param(
  # Define a parameter for the full path (including filename) where the backup ZIP file will be saved.
  # [string] means it expects text. '= '' ' sets an empty default if not provided.
  [string]$BackupPath = '',

  # Define a parameter for the root directory of the project you want to back up.
  # [string] means it expects text. '= '' ' sets an empty default if not provided.
  [string]$RootPath = ''
)

# --- (Optional) Old/Alternative Backup Method - Currently Commented Out ---
# The following lines show a previous way the backup might have been done.
# They are disabled because of the '#' at the beginning of each line.

# # (If active) Get a list of all individual files directly under the $RootPath.
# # $files = Get-ChildItem -Path $RootPath -File

# # (If active) Get a list of all sub-directories under $RootPath, including their contents (recursively).
# # Exclude specific directories like __pycache__, models, etc.
# # $directories = Get-ChildItem -Path $RootPath -Recurse -Directory -Exclude __pycache__, models, poppler-0.68.0, socr-preprod

# # (If active) Create a ZIP archive from the $files and $directories lists found above.
# # Save it to $BackupPath. The -Update switch updates existing archives with newer files.
# # Compress-Archive -Path $($files + $directories) -DestinationPath $BackupPath -Update


# --- Current Backup Method ---

# Prepare a collection of settings (a "hashtable") for the Compress-Archive command.
# This makes the Compress-Archive command cleaner to read later.
$compress = @{
    # Specify the exact list of files and folders to be included in the ZIP archive.
    # Each item is formed by joining the $RootPath with a specific subfolder or file name.
    LiteralPath = "${RootPath}\api", 
                  "${RootPath}\backend-modules",  
                  "${RootPath}\bin", 
                  "${RootPath}\common", 
                  "${RootPath}\controller", 
                  "${RootPath}\PSScripts",
                  "${RootPath}\public", 
                  "${RootPath}\routes", 
                  "${RootPath}\ssl", 
                  "${RootPath}\stripe-server", 
                  "${RootPath}\utils",
                  "${RootPath}\views", 
                  "${RootPath}\xml", 
                  "${RootPath}\app.js", 
                  "${RootPath}\config.js", 
                  "${RootPath}\package.json",
                  "${RootPath}\www"

    # Set the compression level. "Fastest" creates the ZIP quickly, but it might be slightly larger.
    CompressionLevel = "Fastest"

    # Specify the full path (including filename) where the final ZIP archive will be saved.
    # This uses the $BackupPath parameter provided to the script.
    DestinationPath = $BackupPath
} # End of the hashtable definition

# Create the ZIP archive using the settings defined in the $compress hashtable.
# The '@' symbol before 'compress' is called "splatting" - it applies the hashtable's key-value pairs as parameters.
# -Update: If the destination ZIP file already exists, this will add new files or update existing ones if the source is newer.
Compress-Archive @compress -Update

# --- Backup Retention Policy: Clean up old backups ---
# This section aims to keep only a certain number of recent backups.
# The comment below says "retain last 20", but the code actually retains the last 15.
# retain last 20 deployment

# Get the directory (folder) path where the backup ZIP file was saved.
# For example, if $BackupPath is "C:\backups\myzip.zip", $backupdirectory will be "C:\backups".
$backupdirectory = Split-Path $backupPath

# Display the path of the backup directory in the console (useful for logging or debugging).
Write-Host "Backup directory is: $backupDirectory"

# Change PowerShell's current working location to the backup directory.
# This makes the next command simpler as it will operate within this directory.
Set-Location $backupDirectory

# Manage old backup files:
Get-ChildItem -file | # Get all *files* in the current directory (the backup directory).
  Sort-Object LastWriteTime -Descending | # Sort these files by their modification date, newest files first.
  Select-Object -Skip 15 | # Skip the 15 newest files from the sorted list (so, select all files *older* than the 15 newest).
  Remove-Item # Delete the selected older files. This keeps the 15 most recent backups.
