# First-Login-Capture
Captures data pertaining to why Windows Autopilot is failing to preprovision

1) Open PowerShell as Administrator
Start → type powershell → right-click Windows PowerShell (or PowerShell 7) → Run as administrator.

2) Create the working folder
New-Item -ItemType Directory -Force -Path C:\QTM-FirstLoginCapture | Out-Null

3) Allow Execution in this window only
Set-ExecutionPolicy -Scope Process Bypass -Force

4) Put the script content into a variable:
Paste everything between @' and '@ inclusive (those two lines mark the start and end).
The closing '@ must be alone on its own line - nothing else on that line:



# -------------- SCRIPT START -------------------

$script = @'
<# 
 FirstLoginCapture.ps1
 Purpose: Capture everything we need around first-logon WebView2/Teams/Outlook behavior.
 Run it three times with -Phase: Baseline, PostRepro, AfterEdgeUpdate
#>

param([string]$Phase = "Baseline")

# ------------------------
# 0) PREP & OUTPUT FOLDERS
# ------------------------
$ErrorActionPreference = 'SilentlyContinue'
$Root  = 'C:\QTM-FirstLoginCapture'
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Out   = Join-Path $Root "$Stamp-$Phase"
New-Item -ItemType Directory -Force -Path $Out,$Out\Logs,$Out\Events,$Out\Autopilot | Out-Null

# Human summary
$Summary = Join-Path $Out '00_SUMMARY.txt'
"Phase: $Phase"      | Out-File $Summary
"Time : $(Get-Date)" | Out-File $Summary -Append
"Host : $(hostname)" | Out-File $Summary -Append
"User : $(whoami)"   | Out-File $Summary -Append
""                   | Out-File $Summary -Append

# 1) Environment context
(Get-Date) | Out-File "$Out\01_timestamp.txt"
whoami /all | Out-File "$Out\02_whoami.txt"
hostname    | Out-File "$Out\03_hostname.txt"

# 2) WebView2 registry (HKLM 64/32 + HKCU)
$ClientId = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
$RegKeys  = @(
  "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$ClientId",
  "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$ClientId",
  "HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$ClientId"
)
"--- WebView2 Registry ---" | Out-File "$Out\10_webview2_registry.txt"
foreach($k in $RegKeys){
  if(Test-Path $k){
    "[$k]" | Out-File "$Out\10_webview2_registry.txt" -Append
    Get-ItemProperty $k | Format-List * | Out-String | Out-File "$Out\10_webview2_registry.txt" -Append
  } else {
    "MISSING: $k" | Out-File "$Out\10_webview2_registry.txt" -Append
  }
}

# 3) WebView2 files on disk (+ version)
$WvBase = "$env:ProgramFiles(x86)\Microsoft\EdgeWebView\Application"
if(Test-Path $WvBase){
  $Latest = Get-ChildItem $WvBase -Directory | Where-Object { $_.Name -match '^\d+\.' } |
            Sort-Object Name -Descending | Select-Object -First 1
  if($Latest){
    "WebView2 folder: $($Latest.FullName)" | Out-File "$Out\11_webview2_files.txt"
    $Exe = Join-Path $Latest.FullName 'msedgewebview2.exe'
    if(Test-Path $Exe){
      $FileVer = (Get-Item $Exe).VersionInfo.FileVersion
      "File version: $FileVer" | Out-File "$Out\11_webview2_files.txt" -Append
      "WebView2 (from file): $FileVer" | Out-File $Summary -Append
    }
  }
} else {
  "No EdgeWebView base folder found." | Out-File "$Out\11_webview2_files.txt"
  "WebView2 files NOT found."         | Out-File $Summary -Append
}

# 4) Edge version + Edge Update health
$EdgeExe = "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe"
if(Test-Path $EdgeExe){
  $EdgeVer = (Get-Item $EdgeExe).VersionInfo.FileVersion
  "Edge version: $EdgeVer" | Out-File "$Out\12_edge_version.txt"
  "Edge version          : $EdgeVer" | Out-File $Summary -Append
} else {
  "Edge not found at expected path." | Out-File "$Out\12_edge_version.txt"
}
sc.exe query edgeupdate   | Out-File "$Out\13_edgeupdate_services.txt"
sc.exe query edgeupdatem  | Out-File "$Out\13_edgeupdate_services.txt" -Append
Get-ScheduledTask -TaskPath '\Microsoft\EdgeUpdate\' |
  Select-Object TaskName,State,LastRunTime,LastTaskResult |
  Format-Table -Auto | Out-String | Out-File "$Out\14_edgeupdate_tasks.txt"

# 5) Intune IME logs + quick app summary
$ImeLogRoot = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs'
if(Test-Path $ImeLogRoot){
  New-Item -ItemType Directory -Force -Path "$Out\Logs\IME" | Out-Null
  Copy-Item "$ImeLogRoot\*" "$Out\Logs\IME" -Recurse -Force
  Get-Content "$ImeLogRoot\IntuneManagementExtension.log" |
    Select-String -Pattern 'Win32App','Install Failed','Exit code','Detection failed','App installation failed' |
    Set-Content "$Out\15_ime_app_summary.txt"
} else {
  "IME logs folder not found." | Out-File "$Out\15_ime_app_summary.txt"
}

# 6) EdgeUpdate raw logs
$EdgeLogs = 'C:\ProgramData\Microsoft\EdgeUpdate\Log'
if(Test-Path $EdgeLogs){
  New-Item -ItemType Directory -Force -Path "$Out\Logs\EdgeUpdate" | Out-Null
  Copy-Item "$EdgeLogs\*" "$Out\Logs\EdgeUpdate" -Recurse -Force
} else {
  "EdgeUpdate logs folder not found." | Out-File "$Out\Logs\EdgeUpdate\_missing.txt"
}

# 7) Event logs (MDM/Autopilot + App + System)
wevtutil epl Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin       "$Out\Events\DMEDP-Admin.evtx"
wevtutil epl Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Operational "$Out\Events\DMEDP-Operational.evtx"
wevtutil epl Application "$Out\Events\Application.evtx"
wevtutil epl System      "$Out\Events/System.evtx"

# 8) Teams + new Outlook local logs (best effort)
$RA = $env:APPDATA
$LA = $env:LOCALAPPDATA
New-Item -ItemType Directory -Force -Path "$Out\Logs\App" | Out-Null
$Paths = @(
  "$RA\Microsoft\Teams\*.log",
  "$RA\Microsoft\Teams\logs.txt",
  "$LA\Packages\MSTeams_8wekyb3d8bbwe\LocalState\*",
  "$LA\Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe\LocalState\*"
)
foreach($p in $Paths){ Copy-Item $p "$Out\Logs\App" -Recurse -Force -ErrorAction SilentlyContinue }

# 9) Autopilot artifacts + MDM diagnostics CAB
Copy-Item "C:\Windows\Provisioning\Autopilot\*" "$Out\Autopilot" -Recurse -Force -ErrorAction SilentlyContinue
try{ mdmdiagnosticstool.exe -area Autopilot;DeviceEnrollment;DeviceProvisioning -cab "$Out\MDMDiag-$Phase.cab" } catch {}

# 10) AppX info (Teams & new Outlook)
Get-AppxPackage MSTeams* , *Outlook* |
  Select-Object Name, PackageFamilyName, Version |
  Format-Table -Auto | Out-String | Out-File "$Out\16_appx_teams_outlook.txt"

# 11) Zip the capture
$Zip = Join-Path $Root ("QTM_FirstLogin_"+$Stamp+"_"+$Phase+".zip")
Compress-Archive -Path $Out\* -DestinationPath $Zip -Force
"Capture complete: $Zip" | Tee-Object -FilePath $Summary -Append
Write-Host "Capture complete: $Zip"
'@


# ----------------- END SCRIPT ---------------------


# 5) In the same powershell window, run the following command to save the script variable we created to a .ps1 file
$script | Set-Content -Path C:\QTM-FirstLoginCapture\FirstLoginCapture.ps1 -Encoding UTF8

# 6) Verify the file exists:
Get-Item C:\QTM-FirstLoginCapture\FirstLoginCapture.ps1

# 7) Run the three phases
# Phase A - Baseline (before opeining anything)
cd C:\QTM-FirstLoginCapture
.\FirstLoginCapture.ps1 -Phase Baseline

# Phase B — Reproduce the issue, then capture
# Manually open Teams, then new Outlook (do not open Edge yet).
# If you see a WebView2 prompt or app failure → take a screenshot.
# Capture:
.\FirstLoginCapture.ps1 -Phase PostRepro

# Phase C — Trigger Edge updater, then capture:
Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" "edge://settings/help"
Start-Sleep -Seconds 60
.\FirstLoginCapture.ps1 -Phase AfterEdgeUpdate

# 8) Grab the output
# All three ZIPs will be in:
C:\QTM-FirstLoginCapture\

#They’ll look like:
QTM_FirstLogin_YYYYMMDD_HHMMSS_Baseline.zip
QTM_FirstLogin_YYYYMMDD_HHMMSS_PostRepro.zip
QTM_FirstLogin_YYYYMMDD_HHMMSS_AfterEdgeUpdate.zip











