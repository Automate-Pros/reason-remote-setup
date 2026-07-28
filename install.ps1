<#
.SYNOPSIS
  One-line installer for the Automate Pros Reason Remote surfaces.

.DESCRIPTION
  Downloads the latest setup bundle and installs the Reason Remote codec and maps into
  Reason, so the user never has to find, download and unzip anything by hand.

  Published to the root of https://github.com/Automate-Pros/reason-remote-setup as
  install.ps1, and run with:

    irm https://raw.githubusercontent.com/Automate-Pros/reason-remote-setup/main/install.ps1 | iex

  Deliberately has no param() block and no #Requires: neither behaves predictably when a
  script is piped into Invoke-Expression, so the version check below is explicit. Anyone
  who wants to pass arguments can use the scriptblock form instead:

    & ([scriptblock]::Create((irm <url>)))

  Canonical source lives in the private repo at scripts/bootstrap-install.ps1 — edit there
  and republish, per docs/PUBLISHING.md.
#>

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
  Write-Host ''
  Write-Host 'PowerShell 7 or newer is required.' -ForegroundColor Red
  Write-Host "  You are running $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition) edition)."
  Write-Host '  Install it from https://aka.ms/powershell, open a new "pwsh" window, and run this again.'
  Write-Host ''
  return
}

$AssetUrl = 'https://github.com/Automate-Pros/reason-remote-setup/releases/latest/download/reason-remote-setup.zip'
$workDir = Join-Path ([System.IO.Path]::GetTempPath()) ("reason-remote-setup-{0}" -f [guid]::NewGuid().ToString('N'))

# The progress bar makes Invoke-WebRequest dramatically slower and leaves artefacts behind
# when a script is piped into iex.
$previousProgress = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

try {
  New-Item -ItemType Directory -Force -Path $workDir | Out-Null
  $zipPath = Join-Path $workDir 'reason-remote-setup.zip'

  Write-Host 'Reason Remote — Automate Pros' -ForegroundColor Cyan
  Write-Host "Downloading the latest setup bundle..."
  Invoke-WebRequest -Uri $AssetUrl -OutFile $zipPath

  # A GitHub error page or a truncated transfer would otherwise reach Expand-Archive and
  # fail with something far less obvious than this.
  $size = (Get-Item -LiteralPath $zipPath).Length
  if ($size -lt 10KB) {
    throw "The download is only $size bytes, which is not the setup bundle. Check $AssetUrl in a browser."
  }
  Write-Host ("  {0:N0} KB downloaded" -f ($size / 1KB))

  Expand-Archive -LiteralPath $zipPath -DestinationPath $workDir -Force

  $installer = Join-Path $workDir 'install-remote.ps1'
  if (-not (Test-Path -LiteralPath $installer)) {
    throw 'The bundle did not contain install-remote.ps1.'
  }

  Write-Host ''
  & $installer
}
catch {
  Write-Host ''
  Write-Host "Install failed: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host 'You can install manually instead — see' -ForegroundColor Yellow
  Write-Host '  https://github.com/Automate-Pros/reason-remote-setup#readme' -ForegroundColor Yellow
  exit 1
}
finally {
  $ProgressPreference = $previousProgress
  Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
}
