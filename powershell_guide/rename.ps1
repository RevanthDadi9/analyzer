# --- Script Parameters ---
# This block defines the inputs (parameters) that this script accepts when it's run.
Param(
  # Define a parameter named $RootPath.
  # [string] specifies that the value for this parameter should be text (a string).
  # 'D:\temp\SonarCloud_POC' is the default value. If the script is run without providing
  # a -RootPath argument, this default path will be used.
  [string]$RootPath = 'D:\temp\SonarCloud_POC'
)

# --- Prepare Folder Paths ---
# The next few lines are about figuring out the necessary path components.

# Get the parent directory of the $RootPath.
# For example, if $RootPath is 'D:\temp\SonarCloud_POC', $parentFolder will become 'D:\temp'.
# `Split-Path` is a cmdlet used to extract parts of a path.
# `-Path $RootPath`: Specifies the full path to work with.
# `-Parent`: Instructs `Split-Path` to return the parent directory of the given path.
$parentFolder = Split-Path -Path $RootPath -Parent

# Get the actual name of the folder specified in $RootPath (the last part of the path).
# For example, if $RootPath is 'D:\temp\SonarCloud_POC', $folderName will become 'SonarCloud_POC'.
# `-Leaf`: Instructs `Split-Path` to return the file or folder name component of the path.
$folderName = Split-Path -Path $RootPath -Leaf

# Construct the full path for the new backup folder name.
# This will be the original folder's parent path, plus the original folder's name with "-backup" appended.
# For example, if $parentFolder is 'D:\temp' and $folderName is 'SonarCloud_POC',
# $renamedFolder will become 'D:\temp\SonarCloud_POC-backup'.
# `Join-Path` is used to combine path segments correctly, handling backslashes automatically.
# `-ChildPath "$folderName-backup"`: Creates the new name for the backup folder.
$renamedFolder = Join-Path -Path $parentFolder -ChildPath "$folderName-backup"

# --- Clean Up Old Backup ---
# This section ensures that if a backup folder from a previous run exists, it's removed.

# Informational comment for the reader.
# Remove old backup folder if it exists
# Check if a folder already exists at the path we've determined for the backup ($renamedFolder).
# `Test-Path` returns $true if the path exists, and $false otherwise.
if (Test-Path -Path $renamedFolder) {
    # If the old backup folder exists, delete it.
    # `Remove-Item` is the cmdlet for deleting files and folders.
    # `-Path $renamedFolder`: Specifies the folder to delete.
    # `-Recurse`: If the item is a folder, this deletes all its contents (subfolders and files) as well.
    #             This is important because `Remove-Item` won't delete a non-empty folder by default.
    # `-Force`: Attempts to remove items that are read-only and suppresses confirmation prompts.
    Remove-Item -Path $renamedFolder -Recurse -Force
} # End of 'if' block for removing old backup.

# --- Rename Original Folder to Backup ---
# This is the core operation: renaming the original folder to become the backup.
# This is done within a 'try...catch' block to handle potential errors gracefully.
try {
    # Attempt to rename the original folder (specified by $RootPath).
    # `-Path $RootPath`: The item to rename.
    # `-NewName "$folderName-backup"`: The new name for the item. Since only a name (not a full path)
    #                                is provided, `Rename-Item` renames it in its current location ($parentFolder).
    #                                So, 'D:\temp\SonarCloud_POC' becomes 'D:\temp\SonarCloud_POC-backup'.
    # `-ErrorAction Stop`: If `Rename-Item` encounters an error (e.g., folder is in use, permissions issue),
    #                      it will stop script execution immediately and jump to the 'catch' block.
    Rename-Item -Path $RootPath -NewName "$folderName-backup" -ErrorAction Stop

    # If Rename-Item was successful (no error was thrown), print a success message to the console.
    # `Write-Host` is used to display messages.
    Write-Host "Folder renamed successfully from '$RootPath' to '$renamedFolder'."
}
catch {
    # This 'catch' block executes only if an error occurred in the 'try' block (due to -ErrorAction Stop).
    # Print an error message to the console.
    # `-ForegroundColor Red`: Displays the message text in red for emphasis.
    Write-Host "Error: Failed to rename folder. Exiting script." -ForegroundColor Red

    # Exit the script immediately with an exit code of 1.
    # An exit code other than 0 typically indicates that the script encountered an error and did not complete successfully.
    # This is useful for automated systems that might be running this script.
    exit 1
} # End of 'try...catch' block for renaming.

# --- Recreate the Original Folder (Now Empty) ---
# After the original folder has been successfully renamed (backed up),
# this section creates a new, empty folder with the original name and path.

# Informational comment for the reader.
# Recreate the original folder
# Check if a folder *still* exists at the original $RootPath.
# After a successful rename, this path should *not* exist anymore.
# This 'if' condition is a bit redundant if the 'try...catch' block for renaming worked as expected
# (because if rename failed, the script would have exited; if it succeeded, $RootPath shouldn't exist).
# However, it acts as an additional safety check or handles an unexpected state.
if (Test-Path -Path $RootPath) {
    # If, for some reason, the original path still exists (which is unexpected after a successful rename).
    Write-Host "Path Exists! (This is unexpected if rename was successful)"
}
else {
    # This 'else' block executes if $RootPath does NOT exist (the expected scenario after successful rename).
    # Create a new, empty directory at the original $RootPath.
    # `New-Item` is the cmdlet for creating new files or directories.
    # `-Path $RootPath`: Specifies the path where the new directory should be created.
    #                  Remember, $RootPath still holds the *original* path string (e.g., 'D:\temp\SonarCloud_POC').
    # `-ItemType Directory`: Specifies that we want to create a directory (folder).
    # `| Out-Null`: The `New-Item` cmdlet, when creating a directory, outputs an object describing the new directory.
    #               The `|` (pipe) sends this output object to `Out-Null`.
    #               `Out-Null` discards any input it receives, effectively suppressing the default output
    #               of `New-Item` from appearing on the console. The folder IS STILL CREATED.
    New-Item -Path $RootPath -ItemType Directory | Out-Null

    # Print a confirmation message that the new, empty folder has been created.
    Write-Host "Created new folder at '$RootPath'"
} # End of 'if...else' block for recreating the folder.
