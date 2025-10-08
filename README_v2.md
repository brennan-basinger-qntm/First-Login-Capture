# First-Login-Capture (v2)

Capture kit to diagnose **first-login issues** on freshly Autopilot-provisioned Windows devices (e.g., **WebView2** prompts affecting **Teams** / **new Outlook**).  
**v2** improves path detection, adds OS/policy/proxy context, and clarifies the workflow.

---

## What’s new in v2
- **Robust WebView2 path**: reads the `location` from the EdgeUpdate client key; falls back to `%ProgramFiles%` and `%ProgramFiles(x86)%`.
- **Edge path discovery**: checks 64-bit and 32-bit locations and the **App Paths** registry.
- **Task listing**: adds `schtasks /Query` for reliable EdgeUpdate task output.
- **Extra context**: OS product/build, `HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate`, and `netsh winhttp show proxy`.
- **Clearer README** with copy‑paste steps and fenced code blocks.

---

## What This Captures
- **WebView2** presence & version (HKLM 64/32-bit + HKCU) and on‑disk binaries.
- **Microsoft Edge** version + **Edge Update** service & scheduled task health.
- **Intune IME** logs and a quick “failing Win32 app” summary.
- **EdgeUpdate** raw logs (why installs/updates succeeded or failed).
- **Event logs** (MDM/Autopilot provisioning, Application, System).
- **Teams / new Outlook** local logs & AppX package versions.
- **Autopilot provisioning artifacts** and an **MDM diagnostics CAB**.
- **OS/Policy/Proxy** context helpful for SYSTEM-context update issues.
- Each phase is zipped for easy sharing.

---

## Before You Start
- Use a **freshly provisioned** device that just completed Windows Autopilot.
- **Sign in once** with the target user account.
- **Do not open Microsoft Edge** yet (we want the pre‑update state).

---

## Quick Start

Open **PowerShell as Administrator**, then run:

```powershell
# 1) Create the working folder
New-Item -ItemType Directory -Force -Path C:\QTM-FirstLoginCapture | Out-Null

# 2) Allow script execution for this window only
Set-ExecutionPolicy -Scope Process Bypass -Force

# 3) Download or copy FirstLoginCapture_v2.ps1 to C:\QTM-FirstLoginCapture
#    (If you can’t download files, paste the script from your repo into this path.)

# 4) Run the three phases
cd C:\QTM-FirstLoginCapture
.\FirstLoginCapture_v2.ps1 -Phase Baseline
# Reproduce issue: open Teams, then new Outlook (DO NOT open Edge yet).
.\FirstLoginCapture_v2.ps1 -Phase PostRepro
# Trigger update: Edge -> edge://settings/help (or use the Start-Process line below), wait ~60s.
Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" "edge://settings/help"; Start-Sleep -Seconds 60
.\FirstLoginCapture_v2.ps1 -Phase AfterEdgeUpdate
```

> **“Repro”** = reproduce the problem intentionally (e.g., launch **Teams** and **new Outlook** to observe any WebView2 prompt/error).

---

## Output & What to Send

All ZIPs are saved to:
```
C:\QTM-FirstLoginCapture\
```
You’ll see:
- `QTM_FirstLogin_YYYYMMDD_HHMMSS_Baseline.zip`
- `QTM_FirstLogin_YYYYMMDD_HHMMSS_PostRepro.zip`
- `QTM_FirstLogin_YYYYMMDD_HHMMSS_AfterEdgeUpdate.zip`

**Send these three ZIPs** (plus any screenshots) to endpoint engineering with this note:

> “Three-phase capture attached: **Baseline**, **PostRepro** (right after the Teams/Outlook popup), and **AfterEdgeUpdate** (after opening Edge → *About* to trigger updates). Bundles include WebView2/Edge versions, Edge Update services/tasks, IME & EdgeUpdate logs, MDM/Autopilot event logs, Teams/Outlook logs, Autopilot artifacts, and OS/policy/proxy context. Please compare WebView2 `pv` under `HKLM\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}` / `WOW6432Node` across phases.”

---

## Troubleshooting & Notes
- **EdgeUpdate services show STOPPED** when idle; they start on demand. That’s normal.
- If Edge isn’t at `C:\Program Files (x86)\…`, v2 also checks `C:\Program Files\…` and App Paths.
- If WebView2 files aren’t found under `%ProgramFiles(x86)%`, v2 reads the **registry `location`** and checks there.
- **Execution policy errors?** Re-run: `Set-ExecutionPolicy -Scope Process Bypass -Force`.
- **No logs?** Ensure **PowerShell is running as Administrator**.
- To **force a failure scenario** for testing: temporarily block Edge/WebView2 update egress during ESP (or require user auth on the proxy for SYSTEM) and ensure Teams auto-starts. Then run the three phases.

---

## Appendix: Manual Edge Update Trigger
```powershell
Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" "edge://settings/help"
Start-Sleep -Seconds 60
```
