# Findings from First-Login Capture

## High-level summary
- **No WebView2 errors occurred during your test**. The runtime was already present at first logon.

## Key observations by phase

- **20251008_094309-Baseline**: WebView2 (registry) = `141.0.3537.57`; WebView2 (file) = `—`; Edge = `—`; edgeupdate = `STOPPED`, edgeupdatem = `STOPPED`; IME failures = `No`; EdgeUpdate log = `MicrosoftEdgeUpdate.log`.
- **20251008_095156-PostRepro**: WebView2 (registry) = `141.0.3537.57`; WebView2 (file) = `—`; Edge = `—`; edgeupdate = `STOPPED`, edgeupdatem = `STOPPED`; IME failures = `No`; EdgeUpdate log = `MicrosoftEdgeUpdate.log`.
- **20251008_095542-AfterEdgeUpdate**: WebView2 (registry) = `141.0.3537.57`; WebView2 (file) = `—`; Edge = `—`; edgeupdate = `STOPPED`, edgeupdatem = `STOPPED`; IME failures = `No`; EdgeUpdate log = `MicrosoftEdgeUpdate.log`.

## Notable details

### 20251008_094309-Baseline

**Registry (excerpt):**
```
﻿--- WebView2 Registry ---
MISSING: HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}
[HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}]


name            : Microsoft Edge WebView2 Runtime
pv              : 141.0.3537.57
location        : C:\Program Files (x86)\Microsoft\EdgeWebView\Application
SilentUninstall : "C:\Program Files (x86)\Microsoft\EdgeWebView\Application\141.0.3537.57\Installer\setup.exe" --force-uninstall 
                  --uninstall --msedgewebview --system-level --verbose-logging
PSPath          : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2
                  A-4295-8BDF-00C3A9A7E4C5}
PSParentPath    : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients
PSChildName     : {F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}
PSDrive         : HKLM
PSProvider      : Microsoft.PowerShell.Core\Registry




MISSING: HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}
```

**WebView2 files check (excerpt):**
```
﻿No EdgeWebView base folder found.
```

**Edge Update services (excerpt):**
```
﻿
SERVICE_NAME: edgeupdate 
        TYPE               : 10  WIN32_OWN_PROCESS  
        STATE              : 1  STOPPED 
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0

SERVICE_NAME: edgeupdatem 
        TYPE               : 10  WIN32_OWN_PROCESS  
        STATE              : 1  STOPPED 
        WIN32_EXIT_CODE    : 1077  (0x435)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0
```

### 20251008_095156-PostRepro

**Registry (excerpt):**
```
﻿--- WebView2 Registry ---
MISSING: HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}
[HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}]


name            : Microsoft Edge WebView2 Runtime
pv              : 141.0.3537.57
location        : C:\Program Files (x86)\Microsoft\EdgeWebView\Application
SilentUninstall : "C:\Program Files (x86)\Microsoft\EdgeWebView\Application\141.0.3537.57\Installer\setup.exe" --force-uninstall 
                  --uninstall --msedgewebview --system-level --verbose-logging
PSPath          : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2
                  A-4295-8BDF-00C3A9A7E4C5}
PSParentPath    : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients
PSChildName     : {F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}
PSDrive         : HKLM
PSProvider      : Microsoft.PowerShell.Core\Registry




MISSING: HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}
```

**WebView2 files check (excerpt):**
```
﻿No EdgeWebView base folder found.
```

**Edge Update services (excerpt):**
```
﻿
SERVICE_NAME: edgeupdate 
        TYPE               : 10  WIN32_OWN_PROCESS  
        STATE              : 1  STOPPED 
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0

SERVICE_NAME: edgeupdatem 
        TYPE               : 10  WIN32_OWN_PROCESS  
        STATE              : 1  STOPPED 
        WIN32_EXIT_CODE    : 1077  (0x435)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0
```

### 20251008_095542-AfterEdgeUpdate

**Registry (excerpt):**
```
﻿--- WebView2 Registry ---
MISSING: HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}
[HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}]


name            : Microsoft Edge WebView2 Runtime
pv              : 141.0.3537.57
location        : C:\Program Files (x86)\Microsoft\EdgeWebView\Application
SilentUninstall : "C:\Program Files (x86)\Microsoft\EdgeWebView\Application\141.0.3537.57\Installer\setup.exe" --force-uninstall 
                  --uninstall --msedgewebview --system-level --verbose-logging
PSPath          : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2
                  A-4295-8BDF-00C3A9A7E4C5}
PSParentPath    : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients
PSChildName     : {F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}
PSDrive         : HKLM
PSProvider      : Microsoft.PowerShell.Core\Registry




MISSING: HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}
```

**WebView2 files check (excerpt):**
```
﻿No EdgeWebView base folder found.
```

**Edge Update services (excerpt):**
```
﻿
SERVICE_NAME: edgeupdate 
        TYPE               : 10  WIN32_OWN_PROCESS  
        STATE              : 1  STOPPED 
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0

SERVICE_NAME: edgeupdatem 
        TYPE               : 10  WIN32_OWN_PROCESS  
        STATE              : 1  STOPPED 
        WIN32_EXIT_CODE    : 1077  (0x435)
        SERVICE_EXIT_CODE  : 0  (0x0)
        CHECKPOINT         : 0x0
        WAIT_HINT          : 0x0
```


## Interpretation

- The WebView2 **registry** shows `pv = 141.0.3537.57` in **all three phases**, which means the **Evergreen Runtime was installed before first logon** (baseline).
- The WebView2 **file check** reported *'No EdgeWebView base folder found'*. This is likely a **script path assumption** rather than a runtime problem. We should read the **`location`** value from the registry and check that path instead of hardcoding `%ProgramFiles(x86)%`.
- The **Edge binary** was not found at `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`. Many machines place Edge at `C:\Program Files\Microsoft\Edge\Application\msedge.exe`. We should probe **both locations (and the App Paths registry)**.
- **Edge Update services** show `STOPPED`. That’s normal when idle; they start on-demand. An EdgeUpdate log is present in the AfterEdgeUpdate bundle, which is expected after an update check.
- **IME summary** shows no install/detection failures, so ESP was not blocked by a Win32 app during your test.

## Recommended script improvements (v2)

1. **WebView2 base path**: read `location` from the EdgeUpdate client key and check that folder; fall back to `%ProgramFiles%` and `%ProgramFiles(x86)%`.
2. **Edge path detection**: look in both `C:\Program Files\Microsoft\Edge\Application\msedge.exe` and `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`, then the **App Paths** registry.
3. **EdgeUpdate tasks**: also dump with `schtasks /Query /TN \Microsoft\EdgeUpdate\* /FO LIST /V` to avoid formatting oddities.
4. **Policy & proxy context** (optional): export `HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate` and `netsh winhttp show proxy`.
5. **OS/build context** (optional): include OS version/build (`Get-ComputerInfo` or `Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'`).