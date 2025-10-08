<# 
 Keeping the updated version 2 script as a separate file for now
 FirstLoginCapture_v2.ps1
 Purpose: Improved capture with resilient Edge/WebView2 path detection and extra context.
#>

param([string]$Phase = "Baseline")

$ErrorActionPreference = 'SilentlyContinue'
$Root  = 'C:\QTM-FirstLoginCapture'
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Out   = Join-Path $Root "$Stamp-$Phase"
New-Item -ItemType Directory -Force -Path $Out,$Out\Logs,$Out\Events,$Out\Autopilot | Out-Null

# --- Summary header ---
$Summary = Join-Path $Out '00_SUMMARY.txt'
"Phase: $Phase"            | Out-File $Summary
"Time : $(Get-Date)"       | Out-File $Summary -Append
"Host : $(hostname)"       | Out-File $Summary -Append
"User : $(whoami)"         | Out-File $Summary -Append

# --- OS/Build context ---
try {
  $osK = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
  $osP = Get-ItemProperty $osK -ErrorAction Stop
  "OS ProductName : $($osP.ProductName)"    | Out-File $Summary -Append
  "OS ReleaseId   : $($osP.ReleaseId)"      | Out-File $Summary -Append
  "OS DisplayVersion: $($osP.DisplayVersion)" | Out-File $Summary -Append
  "OS Build       : $($osP.CurrentBuildNumber)" | Out-File $Summary -Append
} catch {}

# 1) Environment context files
(Get-Date) | Out-File "$Out\01_timestamp.txt"
whoami /all | Out-File "$Out\02_whoami.txt"
hostname    | Out-File "$Out\03_hostname.txt"

# Helper: robust Edge path
function Get-EdgeExePath {
  $candidates = @(
    "$Env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "$Env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe"
  )
  foreach($p in $candidates){ if(Test-Path $p){ return $p } }
  try {
    $k = Get-Item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction Stop
    $appPath = $k.GetValue('')
    if($appPath -and (Test-Path $appPath)){ return $appPath }
  } catch {}
  return $null
}

# Helper: WebView2 base from registry
$ClientId = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
function Get-WV2BaseFromReg {
  $paths = @(
    "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$ClientId",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$ClientId"
  )
  foreach($p in $paths){
    if(Test-Path $p){ $loc = (Get-ItemProperty $p -ea 0).location; if($loc){ return $loc } }
  }
  # Fallbacks
  $fallbacks = @(
    "$Env:ProgramFiles\Microsoft\EdgeWebView\Application",
    "$Env:ProgramFiles(x86)\Microsoft\EdgeWebView\Application"
  )
  foreach($f in $fallbacks){ if(Test-Path $f){ return $f } }
  return $fallbacks[1]
}

# 2) WebView2 registry dump
"--- WebView2 Registry ---" | Out-File "$Out\10_webview2_registry.txt"
foreach($rk in @("HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$ClientId","HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$ClientId","HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$ClientId")){
  if(Test-Path $rk){ "[$rk]" | Out-File "$Out\10_webview2_registry.txt" -Append; Get-ItemProperty $rk | fl * | Out-String | Out-File "$Out\10_webview2_registry.txt" -Append }
  else { "MISSING: $rk" | Out-File "$Out\10_webview2_registry.txt" -Append }
}

# 3) WebView2 files (based on registry location)
$WvBase = Get-WV2BaseFromReg
if(Test-Path $WvBase){
  $Latest = Get-ChildItem $WvBase -Directory | ?{ $_.Name -match '^\d+\.' } | Sort-Object Name -Descending | Select -First 1
  if($Latest){
    "WebView2 folder: $($Latest.FullName)" | Out-File "$Out\11_webview2_files.txt"
    $Exe = Join-Path $Latest.FullName 'msedgewebview2.exe'
    if(Test-Path $Exe){
      $FileVer = (Get-Item $Exe).VersionInfo.FileVersion
      "File version: $FileVer" | Out-File "$Out\11_webview2_files.txt" -Append
      "WebView2 (from file): $FileVer" | Out-File $Summary -Append
    } else {
      "msedgewebview2.exe not found under $($Latest.FullName)" | Out-File "$Out\11_webview2_files.txt" -Append
    }
  } else {
    "No versioned folders found under $WvBase" | Out-File "$Out\11_webview2_files.txt"
  }
} else {
  "WebView2 base path not found: $WvBase" | Out-File "$Out\11_webview2_files.txt"
}

# 4) Edge version + Edge Update health
$EdgeExe = Get-EdgeExePath
if($EdgeExe){
  "Edge path   : $EdgeExe" | Out-File "$Out\12_edge_version.txt"
  "Edge version: $((Get-Item $EdgeExe).VersionInfo.FileVersion)" | Out-File "$Out\12_edge_version.txt" -Append
} else {
  "Edge not found via standard paths or App Paths registry." | Out-File "$Out\12_edge_version.txt"
}
sc.exe query edgeupdate   | Out-File "$Out\13_edgeupdate_services.txt"
sc.exe query edgeupdatem  | Out-File "$Out\13_edgeupdate_services.txt" -Append

# Also dump scheduled tasks via schtasks (more reliable text)
schtasks /Query /TN \Microsoft\EdgeUpdate\* /FO LIST /V > "$Out\14_edgeupdate_tasks.txt" 2>&1

# 5) IME logs + quick summary
$ImeLogRoot = 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs'
if(Test-Path $ImeLogRoot){
  New-Item -ItemType Directory -Force -Path "$Out\Logs\IME" | Out-Null
  Copy-Item "$ImeLogRoot\*" "$Out\Logs\IME" -Recurse -Force
  Get-Content "$ImeLogRoot\IntuneManagementExtension.log" |
    Select-String -Pattern 'Win32App','Install Failed','Exit code','Detection failed','App installation failed' |
    Set-Content "$Out\15_ime_app_summary.txt"
}

# 6) EdgeUpdate raw logs
$EdgeLogs = 'C:\ProgramData\Microsoft\EdgeUpdate\Log'
$EdgeLogsOut = Join-Path $Out 'Logs\EdgeUpdate'
New-Item -ItemType Directory -Force -Path $EdgeLogsOut | Out-Null
if(Test-Path $EdgeLogs){ Copy-Item "$EdgeLogs\*" $EdgeLogsOut -Recurse -Force }

# 7) Event logs
wevtutil epl Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin       "$Out\Events\DMEDP-Admin.evtx"
wevtutil epl Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Operational "$Out\Events\DMEDP-Operational.evtx"
wevtutil epl Application "$Out\Events\Application.evtx"
wevtutil epl System      "$Out\Events/System.evtx"

# 8) Teams / Outlook
$RA = $env:APPDATA; $LA = $env:LOCALAPPDATA
New-Item -ItemType Directory -Force -Path "$Out\Logs\App" | Out-Null
foreach($p in @("$RA\Microsoft\Teams\*.log","$RA\Microsoft\Teams\logs.txt","$LA\Packages\MSTeams_8wekyb3d8bbwe\LocalState\*","$LA\Packages\Microsoft.OutlookForWindows_8wekyb3d8bbwe\LocalState\*")){
  Copy-Item $p "$Out\Logs\App" -Recurse -Force -ErrorAction SilentlyContinue
}

# 9) Autopilot + MDM diagnostics
Copy-Item "C:\Windows\Provisioning\Autopilot\*" "$Out\Autopilot" -Recurse -Force -ErrorAction SilentlyContinue
try{ mdmdiagnosticstool.exe -area Autopilot;DeviceEnrollment;DeviceProvisioning -cab "$Out\MDMDiag-$Phase.cab" } catch {}

# 10) Policy & proxy context (optional but helpful)
reg query "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /s > "$Out\17_edgeupdate_policies.txt" 2>&1
netsh winhttp show proxy > "$Out\18_winhttp_proxy.txt" 2>&1

# 11) Zip
$Zip = Join-Path $Root ("QTM_FirstLogin_"+$Stamp+"_"+$Phase+".zip")
Compress-Archive -Path $Out\* -DestinationPath $Zip -Force
"Capture complete: $Zip" | Tee-Object -FilePath $Summary -Append
Write-Host "Capture complete: $Zip"
