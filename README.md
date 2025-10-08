First-Login-Capture

A small, repeatable capture kit to help diagnose first-login issues on freshly Autopilot-provisioned Windows devices (e.g., WebView2 popups impacting Teams / new Outlook). It collects versions, services/tasks status, IME logs, EdgeUpdate logs, event logs, app logs, and Autopilot artifacts across three phases so endpoint engineering can see exactly what changed.

Table of Contents

What this captures

Before you start

Quick Start (copy/paste)

Step-by-Step Instructions

Script Content

Run the Three Phases

Output & What to Send

Tips & Notes

Troubleshooting

What this captures

WebView2 presence & version (HKLM 64/32-bit + HKCU) and on-disk binaries.

Microsoft Edge version + Edge Update service & scheduled task health.

Intune IME logs and a quick “failing Win32 app” summary.

EdgeUpdate raw logs (why installs/updates succeeded or failed).

Event logs (MDM/Autopilot provisioning, Application, System).

Teams / new Outlook local logs & AppX package versions.

Autopilot provisioning artifacts and an MDM diagnostics CAB.

Each phase is zipped for easy sharing.

Before you start

Use a freshly provisioned device that just completed Windows Autopilot.

Sign in once with the user account.

Do not open Microsoft Edge yet (we want to capture failure state first).

Quick Start (copy/paste)

Open PowerShell as Administrator, then run:

# 1) Create the working folder
New-Item -ItemType Directory -Force -Path C:\QTM-FirstLoginCapture | Out-Null

# 2) Allow script execution for this window only
Set-ExecutionPolicy -Scope Process Bypass -Force

# 3) Create the script (paste everything between @' and '@ inclusive)
$script = @'
<-- paste the script from the "Script Content" section here (including this @' line and the closing '@ on its own line) -->
'@

# 4) Save the script to disk
$script | Set-Content -Path C:\QTM-FirstLoginCapture\FirstLoginCapture.ps1 -Encoding UTF8


Now skip to Run the Three Phases
.

Step-by-Step Instructions
1) Open PowerShell as Administrator

Start → type powershell → right-click Windows PowerShell (or PowerShell 7) → Run as administrator.

2) Create the working folder
New-Item -ItemType Directory -Force -Path C:\QTM-FirstLoginCapture | Out-Null

3) Allow execution in this window only
Set-ExecutionPolicy -Scope Process Bypass -Force

4) Put the script content into a variable

Paste everything between @' and '@ inclusive. The closing '@ must be alone on its own line—nothing else on that line.

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

5) Save the script to a .ps1 file
$script | Set-Content -Path C:\QTM-FirstLoginCapture\FirstLoginCapture.ps1 -Encoding UTF8

6) Verify the file exists
Get-Item C:\QTM-FirstLoginCapture\FirstLoginCapture.ps1

Script Content

For convenience, the full script is included in the block above (Step 4).
If you prefer, save it directly as FirstLoginCapture.ps1 using your editor of choice.

Run the Three Phases

“Repro” = reproduce the issue on purpose. Here, that means: first logon → open Teams and new Outlook (don’t open Edge yet) → if you see a WebView2 prompt/error, that’s the failure we want to capture.

Phase A — Baseline (before opening anything)
cd C:\QTM-FirstLoginCapture
.\FirstLoginCapture.ps1 -Phase Baseline

Phase B — Reproduce the issue, then capture

Manually open Teams, then new Outlook (do not open Edge yet).

If you see a WebView2 prompt or app failure → take a screenshot.

Capture:

.\FirstLoginCapture.ps1 -Phase PostRepro

Phase C — Trigger Edge updater, then capture
Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" "edge://settings/help"  # Forces Edge/WebView2 update check
Start-Sleep -Seconds 60
.\FirstLoginCapture.ps1 -Phase AfterEdgeUpdate

Output & What to Send

All ZIPs are saved to:

C:\QTM-FirstLoginCapture\


Files you’ll see:

QTM_FirstLogin_YYYYMMDD_HHMMSS_Baseline.zip

QTM_FirstLogin_YYYYMMDD_HHMMSS_PostRepro.zip

QTM_FirstLogin_YYYYMMDD_HHMMSS_AfterEdgeUpdate.zip

Send these three ZIPs (plus your screenshot) to the endpoint engineer with this note:

“Three-phase capture attached: Baseline, PostRepro (right after the Teams/Outlook popup), and AfterEdgeUpdate (after opening Edge → About to trigger updates). Bundles include WebView2/Edge versions, Edge Update services/tasks, IME & EdgeUpdate logs, MDM/Autopilot event logs, Teams/Outlook logs, and Autopilot artifacts. Please compare WebView2 pv under HKLM\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5} / WOW6432Node across phases.”

Tips & Notes

Don’t open Edge until after Phase B — we want to observe the broken state first.

If Teams auto-starts, you can still run Phase A quickly right after the desktop appears.

If your tenant uses a proxy, SYSTEM may not reach update endpoints during ESP—these captures help prove it.

Troubleshooting

Execution policy errors: Re-run Set-ExecutionPolicy -Scope Process Bypass -Force in the same window.

Edge path differs: Confirm Edge at
C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe.
If not present, install/repair Edge and re-run Phase C.

IME/EdgeUpdate logs missing: That’s fine; the script leaves a _missing.txt marker so engineering knows.

Access denied copying logs: Make sure you’re running PowerShell as Administrator.

No WebView2 folder found in Baseline but present in AfterEdgeUpdate: that’s often the key insight—Edge Update delivered the runtime only after user logon.
