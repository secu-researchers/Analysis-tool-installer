@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title Analysis VM Tool Installer (Windows 11)

REM ============================================================
REM  Windows 11 Pro analysis VM tool installer (v3)
REM  - winget packages + GitHub release zips + pip + go install
REM  - Run as Administrator. Take a VM snapshot BEFORE running.
REM  - Log: C:\Tools\install_log.txt
REM ============================================================

REM ---- Admin check ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Please right-click this file and choose "Run as administrator".
    pause
    exit /b 1
)

REM ---- winget check ----
where winget >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] winget not found. Install "App Installer" from Microsoft Store, then retry.
    pause
    exit /b 1
)

set "TOOLS=C:\Tools"
set "LOG=%TOOLS%\install_log.txt"
set "FAILED="
if not exist "%TOOLS%" mkdir "%TOOLS%"
echo ==== Install started %date% %time% ==== > "%LOG%"

echo.
echo ############ [1/5] winget packages ############
call :pyinst 3.13.14
call :winget Bandisoft.Bandizip                    "Bandizip"
call :winget Microsoft.VisualStudioCode            "Visual Studio Code"
call :winget Git.Git                               "Git"
call :winget EclipseAdoptium.Temurin.21.JDK        "Temurin JDK 21 (for Ghidra)"
call :winget GoLang.Go                             "Go"
call :winget x64dbg.x64dbg                         "x64dbg"
call :winget hasherezade.PE-bear                   "PE-bear"
call :winget icsharpcode.ILSpy                     "ILSpy"
call :winget MHNexus.HxD                           "HxD"
call :winget WinsiderSS.SystemInformer             "System Informer"
call :winget WiresharkFoundation.Wireshark         "Wireshark"
call :winget Mozilla.Thunderbird                   "Thunderbird"
call :winget OliverBetz.ExifTool                   "ExifTool"
call :winget Insecure.Nmap                         "Nmap"
call :winget PortSwigger.BurpSuite.Community       "Burp Suite Community"

echo.
echo ############ [2/5] GitHub release downloads ############
REM  usage: call :ghdl  owner/repo  "regex for asset name"  folder_name
call :ghdl NationalSecurityAgency/ghidra "ghidra_.*_PUBLIC_.*\.zip$"     Ghidra
call :ghdl rizinorg/cutter          "Windows-x86_64\.zip$"               Cutter
call :ghdl horsicq/DIE-engine       "win64_portable.*\.zip$"             DIE
call :ghdl dnSpyEx/dnSpy            "dnSpy-net-win64\.zip$"              dnSpyEx
call :ghdl gchq/CyberChef           "CyberChef_v[0-9.]+\.zip$"           CyberChef
call :ghdl mandiant/capa            "windows\.zip$"                      capa
call :ghdl mandiant/flare-floss     "windows\.zip$"                      floss
call :ghdl skylot/jadx              "jadx-gui-.*-with-jre-win\.zip$"     jadx
call :ghdl VirusTotal/yara          "win64\.zip$"                        yara
call :ghdl aquasecurity/trivy       "windows-64bit\.zip$"                trivy

echo.
echo ############ [3/5] Direct zip downloads (Sysinternals, Didier Stevens, PeStudio) ############
call :zipdl "https://download.sysinternals.com/files/SysinternalsSuite.zip"       Sysinternals
call :zipdl "https://didierstevens.com/files/software/DidierStevensSuite.zip"     DidierStevensSuite
call :zipdl "https://www.winitor.com/tools/pestudio/current/pestudio.zip"         pestudio

echo.
echo ############ [4/5] Python packages ############
set "PY="
if exist "%ProgramFiles%\Python313\python.exe" set "PY=%ProgramFiles%\Python313\python.exe"
if not defined PY if exist "%LocalAppData%\Programs\Python\Python313\python.exe" set "PY=%LocalAppData%\Programs\Python\Python313\python.exe"
if defined PY (
    "!PY!" -m pip install --upgrade pip >> "%LOG%" 2>&1
    call :pip oletools
    call :pip frida-tools
    call :pip yara-python
    call :pip pefile
    call :pip requests
) else (
    echo [FAIL] Python 3.13 not found - skipping pip packages
    echo FAIL python not found >> "%LOG%"
    set "FAILED=!FAILED! pip-packages"
)

echo.
echo ############ [5/5] Go tools (ProjectDiscovery, ffuf, amass) ############
set "GOEXE=%ProgramFiles%\Go\bin\go.exe"
if exist "!GOEXE!" (
    set "GOBIN=%TOOLS%\go-bin"
    if not exist "!GOBIN!" mkdir "!GOBIN!"
    call :goinst github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    call :goinst github.com/projectdiscovery/httpx/cmd/httpx@latest
    call :goinst github.com/projectdiscovery/katana/cmd/katana@latest
    call :goinst github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    call :goinst github.com/ffuf/ffuf/v2@latest
    call :goinst github.com/owasp-amass/amass/v4/...@master
    REM add go-bin to system PATH
    powershell -NoProfile -Command "$p=[Environment]::GetEnvironmentVariable('Path','Machine'); if($p -notlike '*C:\Tools\go-bin*'){[Environment]::SetEnvironmentVariable('Path',$p+';C:\Tools\go-bin','Machine')}"
    REM verify installed binaries
    for %%b in (subfinder httpx katana nuclei ffuf amass) do (
        if exist "!GOBIN!\%%b.exe" (
            echo     [OK] %%b.exe
        ) else (
            echo     [MISSING] %%b.exe
            set "FAILED=!FAILED! go-bin:%%b"
        )
    )
) else (
    echo [FAIL] Go not found - skipping Go tools ^(open a new admin prompt after Go install and re-run^)
    echo FAIL go not found >> "%LOG%"
    set "FAILED=!FAILED! go-tools"
)

echo.
echo ============================================================
echo  DONE. Log: %LOG%
if defined FAILED (
    echo  Failed items:!FAILED!
) else (
    echo  All items finished without reported errors.
)
echo.
echo  Tools extracted to: %TOOLS%
echo  Reboot or re-login so PATH changes (Go, Python, Git) take effect.
echo ============================================================
pause
exit /b 0


REM ------------------------------------------------------------
:pyinst
REM %1 = exact Python 3.13.x version. Handles: not installed / same version / older version.
set "PYX="
set "PYALL=1"
set "CURV="
if exist "%ProgramFiles%\Python313\python.exe" (
    set "PYX=%ProgramFiles%\Python313\python.exe"
    set "PYALL=1"
)
if not defined PYX if exist "%LocalAppData%\Programs\Python\Python313\python.exe" (
    set "PYX=%LocalAppData%\Programs\Python\Python313\python.exe"
    set "PYALL=0"
)
if defined PYX (
    for /f "tokens=2" %%v in ('"!PYX!" --version') do set "CURV=%%v"
    if "!CURV!"=="%~1" (
        echo     [OK] Python %~1 already installed
        echo OK python %~1 already installed >> "%LOG%"
        exit /b 0
    )
    echo [*] Found Python !CURV! - upgrading in place to %~1 ...
    call :pydirect %~1 !PYALL!
) else (
    echo [*] Installing Python %~1 via winget ...
    winget install --id Python.Python.3.13 -e --source winget --version %~1 --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
    set "RC=!errorlevel!"
    if "!RC!"=="0" (
        echo     [OK] Python %~1
    ) else (
        echo     [FAIL] winget Python code !RC! - trying python.org installer
        call :pydirect %~1 1
    )
)
exit /b 0

REM ------------------------------------------------------------
:pydirect
REM %1 = version, %2 = InstallAllUsers (1 or 0). Official python.org installer.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { $f=Join-Path $env:TEMP 'python-%~1-amd64.exe'; Invoke-WebRequest 'https://www.python.org/ftp/python/%~1/python-%~1-amd64.exe' -OutFile $f -UseBasicParsing; $p=Start-Process $f -ArgumentList '/quiet','InstallAllUsers=%~2','PrependPath=1','Include_launcher=1' -Wait -PassThru; Remove-Item $f -Force; if($p.ExitCode -ne 0){ throw ('installer exit code '+$p.ExitCode) }; Write-Host '    [OK] Python %~1' } catch { Write-Host ('    [FAIL] '+$_.Exception.Message); exit 1 }" >> "%LOG%.tmp" 2>&1
set "RC=!errorlevel!"
type "%LOG%.tmp"
type "%LOG%.tmp" >> "%LOG%"
del "%LOG%.tmp" >nul 2>&1
if not "!RC!"=="0" set "FAILED=!FAILED! Python-%~1"
exit /b 0

REM ------------------------------------------------------------
:winget
REM %1 = package id, %2 = display name, %3.. = extra args
set "PID=%~1"
set "PNAME=%~2"
shift
shift
echo [*] Installing !PNAME! ...
winget install --id !PID! -e --source winget --silent --accept-package-agreements --accept-source-agreements %1 %2 %3 %4 >> "%LOG%" 2>&1
set "RC=!errorlevel!"
REM 0 = ok, -1978335189 = already installed / no upgrade available
if "!RC!"=="0" (
    echo     [OK] !PNAME!
) else if "!RC!"=="-1978335189" (
    echo     [OK] !PNAME! ^(already installed^)
) else (
    echo     [FAIL] !PNAME! ^(code !RC!^)
    echo FAIL winget !PID! code !RC! >> "%LOG%"
    set "FAILED=!FAILED! !PNAME!"
)
exit /b 0

REM ------------------------------------------------------------
:ghdl
REM %1 = owner/repo, %2 = asset regex, %3 = folder name
REM Searches the 15 most recent non-prerelease releases for the first matching asset.
echo [*] Downloading %~3 from GitHub %~1 ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { $rels=Invoke-RestMethod 'https://api.github.com/repos/%~1/releases?per_page=15' -Headers @{'User-Agent'='installer'}; $a=$null; foreach($r in $rels){ if($r.draft -or $r.prerelease){continue}; $a=$r.assets | Where-Object { $_.name -match '%~2' } | Select-Object -First 1; if($a){break} }; if(-not $a){ throw 'asset not found in recent releases' }; $z=Join-Path $env:TEMP $a.name; Invoke-WebRequest $a.browser_download_url -OutFile $z -UseBasicParsing; $d='%TOOLS%\%~3'; if(Test-Path $d){Remove-Item $d -Recurse -Force}; Expand-Archive $z -DestinationPath $d -Force; Remove-Item $z -Force; Write-Host ('    [OK] '+$a.name+' -> '+$d) } catch { Write-Host ('    [FAIL] %~3 : '+$_.Exception.Message); exit 1 }" >> "%LOG%.tmp" 2>&1
set "RC=!errorlevel!"
type "%LOG%.tmp"
type "%LOG%.tmp" >> "%LOG%"
del "%LOG%.tmp" >nul 2>&1
if not "!RC!"=="0" set "FAILED=!FAILED! %~3"
exit /b 0

REM ------------------------------------------------------------
:zipdl
REM %1 = url, %2 = folder name
echo [*] Downloading %~2 ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { $z=Join-Path $env:TEMP '%~2.zip'; Invoke-WebRequest '%~1' -OutFile $z -UseBasicParsing; $d='%TOOLS%\%~2'; Expand-Archive $z -DestinationPath $d -Force; Remove-Item $z -Force; Write-Host ('    [OK] %~2 -> '+$d) } catch { Write-Host ('    [FAIL] %~2 : '+$_.Exception.Message); exit 1 }" >> "%LOG%.tmp" 2>&1
set "RC=!errorlevel!"
type "%LOG%.tmp"
type "%LOG%.tmp" >> "%LOG%"
del "%LOG%.tmp" >nul 2>&1
if not "!RC!"=="0" set "FAILED=!FAILED! %~2"
exit /b 0

REM ------------------------------------------------------------
:pip
echo [*] pip install %~1 ...
"!PY!" -m pip install --upgrade %~1 >> "%LOG%" 2>&1
if !errorlevel! neq 0 (
    echo     [FAIL] %~1
    set "FAILED=!FAILED! pip:%~1"
) else (
    echo     [OK] %~1
)
exit /b 0

REM ------------------------------------------------------------
:goinst
echo [*] go install %~1 ...
"!GOEXE!" install %~1 >> "%LOG%" 2>&1
if !errorlevel! neq 0 (
    echo     [FAIL] %~1
    set "FAILED=!FAILED! go:%~1"
) else (
    echo     [OK] %~1
)
exit /b 0
