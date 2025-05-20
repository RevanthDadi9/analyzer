Param(
  # This block defines inputs the script can accept when you run it.
  # [string] means it expects text. '= '' ' sets an empty default if not provided.

  # Parameter for a path, likely related to the main backup process (e.g., "C:\Backups\WebApp_2023-10-28.zip").
  # This script will use this path to determine where to store the "self-managed" files.
  [string]$BackupPath = '',

  # Parameter for the root directory of the project you want to work with (e.g., "C:\Projects\MyWebApp").
  # This is the folder where files will be copied from, and later, cleaned out.
  [string]$RootPath = ''
)


## save the manually managed files
# This is a comment indicating the start of a section dedicated to backing up specific, important files.

# $directoryPath = Split-Path -Path $BackupPath -Parent
# This line is commented out (starts with '#').
# If active, 'Split-Path -Parent' would get the folder part of the $BackupPath.
# For example, if $BackupPath was "C:\Backups\MyZip.zip", this would give "C:\Backups".
# It's not currently used.

# Construct the path for storing the self-managed files.
# It takes the $BackupPath (e.g., "C:\Backups\WebApp.zip") and appends "-SelfManaged".
# So, $SelfMangedFilesPath might become "C:\Backups\WebApp.zip-SelfManaged". This will be a FOLDER name.
$SelfMangedFilesPath = "$BackupPath-SelfManaged"

# Ensure the Destination Path (for self-managed files) Exists.
# 'Test-Path -Path $SelfMangedFilesPath' checks if the folder (or file) at $SelfMangedFilesPath already exists.
# '!' means 'NOT'. So, 'if NOT (Test-Path ...)' means "if the path does NOT exist".
if (!(Test-Path -Path $SelfMangedFilesPath)) {
    # If the path doesn't exist, create it as a new directory.
    # -ItemType Directory: Specifies to create a folder.
    # -Path $SelfMangedFilesPath: The name and location of the new folder.
    # -Force: Creates parent directories if they don't exist and suppresses confirmation prompts.
    New-Item -ItemType Directory -Path $SelfMangedFilesPath -Force
}

# List of specific files (and their relative paths from $RootPath) that need to be copied.
# These are considered "manually managed" or important configuration files.
# '@(...)' creates an array (a list) of strings.
# Update $filesToCopy in npm-install.ps1 as well -> This is a comment for developers, indicating this list might be duplicated elsewhere.
$filesToCopy = @(".env", "config.js", "config-dev.js", "config-prod.js", "PSScripts\restartservice.ps1", "bin\www")

# Set the source directory for copying files to the $RootPath (your project's main folder).
$sourcePath = $RootPath
# Set the destination directory for these specific files to the path we created/verified earlier.
$destinationPath = $SelfMangedFilesPath

# Loop through each file/path string in the $filesToCopy list.
# For each iteration, the current item from the list is stored in the variable '$file'.
foreach ($file in $filesToCopy) {
    # Check if the current file (e.g., ".env" or "PSScripts\restartservice.ps1") actually exists inside the $sourcePath (your project root).
    # "$sourcePath\$file" combines the source directory path and the relative file path.
    if ((Test-Path -Path "$sourcePath\$file")) {
      # If the source file exists:
      # Get the file item(s). -Filter $file helps find the specific file.
      # This step might seem redundant after Test-Path, but Get-ChildItem returns richer file objects with more properties.
      # It's written to handle cases where $file might be a pattern, though here it's specific names.
      $files = Get-ChildItem -Path $sourcePath -Filter $file -File

      # Loop through the file(s) found by Get-ChildItem (usually just one in this specific script's case, per $file entry).
      foreach ($fileItem in $files) {
          # Calculate the path of the file *relative* to the $sourcePath.
          # $fileItem.FullName is the full path (e.g., "C:\Projects\MyWebApp\PSScripts\restartservice.ps1").
          # .Substring($sourcePath.Length) removes the $sourcePath part (e.g., "C:\Projects\MyWebApp").
          # .TrimStart("\") removes any leading backslash from the result (e.g., "PSScripts\restartservice.ps1").
          $relativePath = $fileItem.FullName.Substring($sourcePath.Length).TrimStart("\")

          # Construct the full destination file path by joining the $destinationPath (e.g., "...-SelfManaged")
          # with the $relativePath.
          $destFilePath = Join-Path -Path $destinationPath -ChildPath $relativePath

          # Get the parent directory of where the destination file will be copied.
          # For example, if $destFilePath is "...-SelfManaged\PSScripts\restartservice.ps1",
          # $destDirectory will be "...-SelfManaged\PSScripts".
          $destDirectory = Split-Path -Path $destFilePath -Parent

          # Check if this destination subdirectory (e.g., "...-SelfManaged\PSScripts") exists.
          if (!(Test-Path -Path $destDirectory)) {
              # If the destination subdirectory doesn't exist, create it.
              New-Item -ItemType Directory -Path $destDirectory -Force
          }

          # Copy the source file ($fileItem.FullName) to the calculated destination path ($destFilePath).
          # -Force: Overwrites the destination file if it already exists.
          Copy-Item -Path $fileItem.FullName -Destination $destFilePath -Force
          # Print a message to the console confirming the copy operation.
          Write-Output "Copied: $($fileItem.FullName) to $destFilePath"
      }
  } else{
      # If the source file specified in $filesToCopy does not exist in $sourcePath.
      Write-Host "File $file does not exists"
  }
} # End of the loop for copying self-managed files.

# Print a message indicating that the backup of self-managed files is complete.
Write-Output "Self Managed File Backup Process Completed"


# --- Cleaning the root path ---
# This section will delete files from the $RootPath directory.

# Set the target path for cleaning to the $RootPath (your project's main folder).
$targetPath = $RootPath

# Check if the $targetPath (which is $RootPath) actually exists.
if (!(Test-Path -Path $targetPath)) {
    # If the folder doesn't exist, print an error message.
    Write-Output "The folder does not exist: $targetPath"
    # Exit the script because we can't clean a non-existent folder.
    exit
}


# Get a list of all files within $targetPath and its subdirectories (-Recurse).
# -File ensures only files are listed, not directories.
# The '|' (pipe) sends this list to the 'Where-Object' command.
# Where-Object filters this list: '$_' represents the current file being checked.
# '$_.Extension -ne ".log"' means "keep the file if its extension is NOT .log".
# So, $filesToDelete will contain all files in $targetPath (and subfolders) *except* for .log files.
$filesToDelete = Get-ChildItem -Path $targetPath -File -Recurse | Where-Object { $_.Extension -ne ".log" }

# Loop through each file in the $filesToDelete list.
foreach ($file in $filesToDelete) {
    # 'try...catch' block: This is for error handling.
    # The code in 'try' will be attempted. If an error occurs that stops the command, the 'catch' block runs.
    try {
        # Attempt to delete the current file.
        # -Path $file.FullName: Specifies the full path of the file to delete.
        # -Force: Attempts to delete read-only files and bypasses confirmation prompts.
        # -ErrorAction Stop: If Remove-Item encounters an error (like file locked), it stops and triggers the 'catch' block.
        Remove-Item -Path $file.FullName -Force -ErrorAction Stop
        # If deletion was successful, print a confirmation message.
        Write-Output "Deleted: $($file.FullName)"
    } catch {
        # This block runs if Remove-Item in the 'try' block failed (e.g., file is locked).
        Write-Output "Could not delete: $($file.FullName). Attempting force unlock..."

        # Attempt to find processes that might be locking the file.
        # Get-WmiObject Win32_Process: Gets a list of all running processes.
        # '| Where-Object { ... }': Filters this list.
        # $_.CommandLine -match [regex]::Escape($file.FullName): Checks if the file's full path appears in the command line
        # that started the process. This is an attempt to identify locking processes, but it's not always perfectly reliable.
        $lockedProcesses = Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -match [regex]::Escape($file.FullName) }
        
        # Loop through any processes found that might be locking the file.
        foreach ($proc in $lockedProcesses) {
            # Forcefully stop (kill) the identified process.
            # -Id $proc.ProcessId: Specifies the process by its ID.
            # -Force: Kills the process without prompting. This can lead to data loss for that process.
            Stop-Process -Id $proc.ProcessId -Force
            Write-Output "Killed process: $($proc.Name) (PID: $($proc.ProcessId))"
        }

        # Try deleting the file again, now that potentially locking processes have been stopped.
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            Write-Output "Deleted after unlock: $($file.FullName)"
        } catch {
            # If deletion still fails after attempting to unlock.
            Write-Output "Failed to delete: $($file.FullName). Manual intervention required."
        }
    } # End of the try...catch block for a single file.
} # End of the loop for deleting files.

# Print a message indicating the file deletion process is complete.
Write-Output "File deletion process completed."


# restor self managed file script moved from here
# This is a comment indicating that a part of the script that would restore
# the "self-managed" files (copied at the beginning) has been moved out of this script.
