param (
    [switch]$Chrome,
    [switch]$Brave,
    [switch]$Firefox
)

.\AtlasModules\initPowerShell.ps1

# ----------------------------------------------------------------------------------------------------------- #
# Software is no longer installed with a package manager anymore to be as fast and as reliable as possible.   #
# ----------------------------------------------------------------------------------------------------------- #

$timeouts = @("--connect-timeout", "10", "--retry", "5", "--retry-delay", "0", "--retry-all-errors")
$msiArgs = "/qn /quiet /norestart ALLUSERS=1 REBOOT=ReallySuppress"
$arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')

# Create a temporary directory
function Remove-TempDirectory { Pop-Location; Remove-Item -Path $tempDir -Force -Recurse -EA 0 }
$tempDir = Join-Path -Path $env:TEMP -ChildPath ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Push-Location $tempDir

# Brave
if ($Brave) {
    Write-Output "Downloading Brave..."
    & curl.exe -LSs "https://laptop-updates.brave.com/latest/winx64" -o "$tempDir\BraveSetup.exe" $timeouts
    if (!$?) {
        Write-Error "Downloading Brave failed."
        exit 1
    }

    Write-Output "Installing Brave..."
    Start-Process -FilePath "$tempDir\BraveSetup.exe" -WindowStyle Hidden -ArgumentList '/silent /install'

    do {
        $processesFound = Get-Process | Where-Object { "BraveSetup" -contains $_.Name } | Select-Object -ExpandProperty Name
        if ($processesFound) {
            Write-Output "Still running BraveSetup."
            Start-Sleep -Seconds 2
        }
        else {
            Remove-TempDirectory
        }
    } until (!$processesFound)

    Stop-Process -Name "brave" -Force -EA 0

    exit
}

# Firefox
if ($Firefox) {
    $firefoxArch = ('win64', 'win64-aarch64')[$arm]

    Write-Output "Downloading Firefox..."
    & curl.exe -LSs "https://download.mozilla.org/?product=firefox-latest-ssl&os=$firefoxArch&lang=en-US" -o "$tempDir\firefox.exe" $timeouts
    Write-Output "Installing Firefox..."
    Start-Process -FilePath "$tempDir\firefox.exe" -WindowStyle Hidden -ArgumentList '/S /ALLUSERS=1' -Wait

    Remove-TempDirectory
    exit
}

# Chrome
if ($Chrome) {
    Write-Output "Downloading Google Chrome..."
    $chromeArch = ('64', '_Arm64')[$arm]
    & curl.exe -LSs "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise$chromeArch.msi" -o "$tempDir\chrome.msi" $timeouts
    Write-Output "Installing Google Chrome..."
    Start-Process -FilePath "$tempDir\chrome.msi" -WindowStyle Hidden -ArgumentList '/qn' -Wait

    Remove-TempDirectory
    exit
}

# Remove temporary directory
Remove-TempDirectory
