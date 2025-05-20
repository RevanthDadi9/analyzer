# --- Script Parameters ---
# This block defines the inputs (parameters) that this script accepts when it's run.
Param(
  # Parameter: The name of the Windows service that this script will manage.
  # This name should match the service name registered in Windows (e.g., with NSSM).
  # Example: "MyNodeAppService"
  [string]$ServiceName = '',

  # Parameter: The full path to the root directory of the application/service.
  # The script will change its working directory to this path.
  # Example: "C:\MyApplication"
  [string]$RootPath = '',

  # Parameter: The name of the Windows Scheduled Task associated with this service.
  # This task might be used to auto-start the service or perform other related actions.
  # Example: "MyNodeAppAutoStartTask"
  [string]$taskSchedulerName = '',

  # Parameter: A boolean (true/false) switch.
  # If $true, the script will attempt to STOP the service and DISABLE the scheduled task.
  # If $false (default), the script will attempt to START the service and ENABLE the scheduled task.
  [bool]$stopService=$false
)

# --- Function Definition: StartService ---
# This function encapsulates the logic to start (or restart) the specified Windows service.
Function StartService(){
   # Define parameters specifically for this function.
   param
   (
     # Mandatory parameter: The name of the service to start.
     # This ensures the function is always called with a service name.
     [Parameter(Mandatory=$true)] [string] $ServiceName
   )

   # Initialize a variable to hold the status of the service.
   $SERVICE_STATUS=''

   # Start a 'try' block for error handling when querying service status.
   try {
      # Execute 'nssm status' for the given $ServiceName.
      # 'nssm' is an external tool (Non-Sucking Service Manager) used to manage applications as services.
      # '2>&1' redirects standard error (stream 2) to standard output (stream 1).
      # This ensures that any error messages from 'nssm' are captured in $SERVICE_STATUS.
      $SERVICE_STATUS = nssm status $ServiceName 2>&1

      # '$LASTEXITCODE' is an automatic PowerShell variable holding the exit code of the last executed external command.
      # A non-zero exit code typically indicates an error from the external command (nssm).
      if ($LASTEXITCODE -ne 0) {
          # If nssm failed (e.g., service not found), explicitly 'throw' a PowerShell error.
          # This will cause execution to jump to the 'catch' block below.
          throw "Service not found or failed to query status"
      }
      # If nssm executed successfully, display the retrieved service status.
      Write-Host "Service Status: $SERVICE_STATUS"
   } catch {
         # This 'catch' block executes if an error occurred in the 'try' block (e.g., the 'throw' statement).
         Write-Host "Service not found. Setting status to NOT_FOUND"
         # Set a custom status indicating the service was not found or query failed.
         $SERVICE_STATUS = "NOT_FOUND"
   } # End of try-catch block for service status query.

   # Display a message indicating the script's intent to start the service.
   Write-Host "Starting service $ServiceName"

   # Check the determined $SERVICE_STATUS to decide the appropriate action.
   if( $SERVICE_STATUS -eq "SERVICE_STOPPED" ){
      # If the service is reported as "SERVICE_STOPPED" by nssm.
      # Use the standard Windows 'net start' command to start the service.
      net start $ServiceName
      Write-Host "Service $ServiceName started."
   } elseif ( $SERVICE_STATUS -eq "SERVICE_RUNNING" -or $SERVICE_STATUS -eq "SERVICE_PAUSED"  ){
      # If the service is reported as "SERVICE_RUNNING" or "SERVICE_PAUSED".
      # The script will effectively restart it.
      # '# nssm restart $ServiceName' -> This is a commented-out alternative command to restart using nssm directly.
      # Stop the service using the standard Windows 'net stop' command.
      net stop $ServiceName
      # Start the service again using 'net start'.
      net start $ServiceName
      Write-Host "Service $ServiceName restarted."
   } else {
      # If the $SERVICE_STATUS is "NOT_FOUND" or any other unexpected value.
      Write-Host "Service $ServiceName does not exist."
      # '# uncomment function call to create service'
      # '# createService'
      # These comments indicate that a function 'createService' (defined later but commented out)
      # could be called here to create the service if it doesn't exist. This is currently disabled.
   } # End of if-elseif-else block for starting/restarting the service.
} # End of Function StartService

# --- Function Definition: StopService ---
# This function encapsulates the logic to stop the specified Windows service.
Function StopService(){
   # Define parameters specifically for this function.
   param
   (
     # Mandatory parameter: The name of the service to stop.
     [Parameter(Mandatory=$true)] [string] $ServiceName
   )

   # Initialize a variable to hold the status of the service.
   $SERVICE_STATUS=''

   # Start a 'try' block for error handling when querying service status (similar to StartService).
   try {
      # Execute 'nssm status' for the given $ServiceName, redirecting stderr to stdout.
      $SERVICE_STATUS = nssm status $ServiceName 2>&1
      # Check if nssm reported an error.
      if ($LASTEXITCODE -ne 0) {
          # If so, throw a PowerShell error to be caught by the 'catch' block.
          throw "Service not found or failed to query status"
      }
      # Display the retrieved service status.
      Write-Host "Service Status:: $SERVICE_STATUS"
   } catch {
         # If an error occurred querying the service.
         Write-Host "Service not found. Setting status to NOT_FOUND"
         # Set a custom status.
         $SERVICE_STATUS = "NOT_FOUND"
   } # End of try-catch block for service status query.
  
   # Display a message indicating the script's intent to stop the service.
   Write-Host "Stopping service $ServiceName"

   # Check the determined $SERVICE_STATUS to decide the appropriate action.
   if ($SERVICE_STATUS -eq "SERVICE_STOPPED"){
       # If the service is already "SERVICE_STOPPED".
       Write-Host "$ServiceName is already stopped."
   } elseif ( $SERVICE_STATUS -eq "SERVICE_RUNNING" -or $SERVICE_STATUS -eq "SERVICE_PAUSED" ){
      # If the service is "SERVICE_RUNNING" or "SERVICE_PAUSED".
      # '# nssm stop $ServiceName' -> Commented-out alternative command to stop using nssm.
      # Use the standard Windows 'net stop' command to stop the service.
      net stop $ServiceName
      # After attempting to stop, re-query the service status using nssm for confirmation.
      $SERVICE_STATUS =  nssm status $ServiceName
      # Display the updated status. The `n is a newline character for formatting.
      Write-Host "$ServiceName is stopped`n Service status: $SERVICE_STATUS"
   } else {
      # If the $SERVICE_STATUS is "NOT_FOUND" or any other unexpected value.
      # '-ForegroundColor yellow' changes the text color in the console for this message.
      Write-Host -ForegroundColor yellow "Service $ServiceName does not exist."
   } # End of if-elseif-else block for stopping the service.
} # End of Function StopService

# --- Main Script Execution Starts Here ---

# Change PowerShell's current working directory to the path specified in the $RootPath parameter.
# This is crucial if the service or related scripts/configurations expect to be run from this specific directory.
Set-Location $RootPath

# Main conditional block: Decides whether to perform "stop" or "start" operations
# based on the boolean value of the $stopService parameter.
if ($stopService){ # This condition is true if $stopService was passed as $true.
   # --- LOGIC TO STOP THE SERVICE AND DISABLE THE SCHEDULED TASK ---

   Write-Host "Disabling the task scheduler" # Informative message.

   # Attempt to retrieve the scheduled task object.
   # -TaskName $taskSchedulerName: Specifies the name of the task to get.
   # -ErrorAction SilentlyContinue: If the task doesn't exist, PowerShell won't throw a terminating error;
   #                               it will continue, and the output variable will be empty.
   # -OutVariable task: The result (the task object if found, or $null/$empty if not) is stored in a variable named 'task'.
   #                    Note: The variable is just 'task', not '$task', when specified in -OutVariable.
   Get-ScheduledTask -TaskName $taskSchedulerName -ErrorAction SilentlyContinue -OutVariable task

   # Check if the task was found. '$task' will be $null or empty if Get-ScheduledTask didn't find it.
   if (!$task) {
      Write-Host "Task Scheduler does not exist"
   } elseif((Get-ScheduledTask -TaskName $taskSchedulerName -ErrorAction SilentlyContinue).State -eq "Ready"){
      # If the task exists (re-querying here to get its current state) AND its State is "Ready" (meaning it's enabled).
      # Start a 'try' block for error handling during task disabling and service stopping.
      try {
         # Disable the scheduled task, preventing it from running automatically.
         Disable-ScheduledTask -TaskName $taskSchedulerName
         # Call the StopService function (defined above) to stop the actual Windows service.
         StopService -ServiceName $ServiceName
         
      } catch{
         # If an error occurs in the 'try' block (e.g., permission issues).
         Write-Host "Error while disabling task scheduler."
      } # End of try-catch for disabling task and stopping service.
   } elseif((Get-ScheduledTask -TaskName $taskSchedulerName -ErrorAction SilentlyContinue).State -eq "Disabled"){
      # If the task exists AND its State is already "Disabled".
      Write-Host "Task is already disabled."
      # Even if the task is disabled, the service might have been started manually, so attempt to stop it.
      StopService -ServiceName $ServiceName
   } else{
      # If the task exists but is in some other state (e.g., "Running", "Queued", "Unknown").
      Write-Host "Something went wrong with the task state." # More specific message could be useful.
   } # End of if-elseif-else for task handling when stopping.
} else{ # This block executes if $stopService is $false (default behavior).
   # --- LOGIC TO START THE SERVICE AND ENABLE THE SCHEDULED TASK ---
   
   Write-Host "Enabling the task scheduler" # Informative message.

   # Attempt to retrieve the scheduled task object (same logic as in the 'stop' part).
   Get-ScheduledTask -TaskName $taskSchedulerName -ErrorAction SilentlyContinue -OutVariable task

   # Check if the task was found.
   if (!$task) {
      Write-Host "task scheduler does not exist"
   } elseif((Get-ScheduledTask -TaskName $taskSchedulerName -ErrorAction SilentlyContinue).State -eq "Disabled"){
      # If the task exists AND its State is "Disabled".
      # Start a 'try' block for error handling during task enabling and service starting.
      try {
         # Enable the scheduled task, allowing it to run automatically as per its schedule/triggers.
         Enable-ScheduledTask -TaskName $taskSchedulerName
         # Call the StartService function (defined above) to start/restart the Windows service.
         StartService -ServiceName $ServiceName
         
      } catch{
         # If an error occurs in the 'try' block.
         Write-Host "Error while enabling task scheduler."
      } # End of try-catch for enabling task and starting service.

   } elseif((Get-ScheduledTask -TaskName $taskSchedulerName -ErrorAction SilentlyContinue).State -eq "Ready"){
      # If the task exists AND its State is already "Ready" (meaning it's already enabled).
      # The task is already enabled, so just ensure the service itself is started/running.
      StartService -ServiceName $ServiceName
   } else{
      # If the task exists but is in some other state.
      Write-Host "Something went wrong with the task state." # More specific message could be useful.
   } # End of if-elseif-else for task handling when starting.
} # End of main if-else block ($stopService).

# --- Commented-Out Code Sections ---
# The following sections are not executed because they are entirely commented out.
# They provide context or alternative implementations.

# --- (Commented Out) Function to Create a Service using NSSM ---
# Function createService {
#    # Placeholder for the username under which the service will run.
#    $VMUserName = "<replace-it>"
#    # Placeholder for the password of the VMUserName.
#    $VMPassword = "<replace-it>"

#    # Use nssm to install the service.
#    # $ServiceName: The name for the new service.
#    # "C:\Program Files\nodejs\node.exe": The executable to run as a service (Node.js).
#    nssm install $ServiceName "C:\Program Files\nodejs\node.exe"
#    # Set the working directory for the service.
#    nssm set $ServiceName AppDirectory $RootPath
#    # Set the command-line arguments for node.exe (e.g., the main script of the Node.js app).
#    nssm set $ServiceName AppParameters .\bin\www
#    # Configure where the service's standard output (stdout) should be logged.
#    nssm set $ServiceName AppStdout "D:\logs\Demo-Ats-Revamp-API\stdout.log"
#    # Configure where the service's standard error (stderr) should be logged.
#    # Typo in original: Should likely be AppStderr, not another AppStdout.
#    nssm set $ServiceName AppStdout "D:logs\Demo-Ats-Revamp-API\stderr.log" # Corrected: nssm set $ServiceName AppStderr "D:\logs\Demo-Ats-Revamp-API\stderr.log"
#    # Configure log rotation: how often to rotate logs (in seconds, 86400 = 24 hours).
#    nssm set $ServiceName AppRotateSeconds 84600 # (Note: 86400 is 24 hours, 84600 is slightly less)
#    # Configure log rotation: how many old log files to keep.
#    nssm set $ServiceName AppRotateFiles 1
#    # Configure log rotation: whether to rotate logs while the service is running.
#    nssm set $ServiceName AppRotateOnline 1
#    # Set the user account and password for the service to run as.
#    # '.\$VMUserName' means a local user account.
#    nssm set $ServiceName ObjectName ".\$VMUserName" "$VMPassword"
#    # Start the newly created and configured service.
#    nssm start $ServiceName
#    Write-Host "Service $ServiceName created."
# } # End of commented-out createService function.


# --- (Commented Out) Alternative Service Management using PM2 ---
## For PM2 Service
# This section shows how one might manage a similar application using PM2 (a process manager for Node.js)
# instead of NSSM and Windows Services.

# # (Commented out) Example parameters if this section were active.
# Param(
#   [string]$ServiceName = "ats-revamp-preprod", # Name used by PM2
#   [string]$RootPath = 'D:\Demo-Ats-Revamp-API'  # Application root
# )

# # (Commented out) Set current location to the application's root path.
# Set-Location $RootPath

# # (Commented out) Check PM2 process status.
# # 'pm2 id $ServiceName' attempts to get the ID of a PM2-managed process.
# # '.Length' on the output might be used to infer if the process exists (PM2 output varies).
# $SERVICE_STATUS = $(pm2 id $ServiceName).Length

# # (Commented out) Logic based on PM2 process status.
#  if( $SERVICE_STATUS -eq 2 ){ # The condition ' -eq 2 ' is specific to expected PM2 output for a non-existent/stopped process.
#     # If process seems stopped/non-existent, start it using a PM2 configuration file 'app.json'.
#     pm2 start app.json
#     Write-Host "Started $ServiceName."
#  } else {
#     # Otherwise, assume it's running and restart it.
#     pm2 restart app.json
#     Write-Host "Restart $ServiceName."
#  } # End of commented-out PM2 logic.
