param(
  [string]$MsiPath,
  [string]$OutputDir = (Join-Path $PSScriptRoot "..\..\dist")
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$buildPackage = Join-Path $repoRoot "build-package"
$bundleWork = Join-Path $buildPackage "bootstrapper"
$templatePath = Join-Path $PSScriptRoot "bundle.wxs.in"
$vcRedistPath = Join-Path $bundleWork "vc_redist.x64.exe"
$vcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"

if (-not $MsiPath) {
  $candidate = Get-ChildItem $buildPackage -Filter "keyboard-mouse-share-master-*-win-x64.msi" -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if (-not $candidate) {
    throw "No 键鼠共享大师 MSI found in $buildPackage. Build the MSI first."
  }
  $MsiPath = $candidate.FullName
}

$MsiPath = (Resolve-Path $MsiPath).Path
$msiName = [IO.Path]::GetFileName($MsiPath)
if ($msiName -notmatch '^keyboard-mouse-share-master-(\d+\.\d+\.\d+\.\d+)-win-x64\.msi$') {
  throw "Unexpected MSI filename: $msiName"
}
$version = $Matches[1]

New-Item -ItemType Directory -Force -Path $bundleWork, $OutputDir | Out-Null

$wix = Get-Command wix -ErrorAction SilentlyContinue
if (-not $wix) {
  $wixPath = Join-Path $env:USERPROFILE ".dotnet\tools\wix.exe"
  if (-not (Test-Path $wixPath)) {
    throw "WiX 4 was not found. Install the wix .NET global tool first."
  }
  $wix = Get-Item $wixPath
}
$wixExe = $wix.Source
if (-not $wixExe) { $wixExe = $wix.FullName }

& $wixExe extension add -g WixToolset.Bal.wixext/4.0.6 | Out-Null
& $wixExe extension add -g WixToolset.Util.wixext/4.0.6 | Out-Null

Write-Host "Downloading current Microsoft VC++ x64 Runtime..."
Invoke-WebRequest -Uri $vcRedistUrl -OutFile $vcRedistPath -UseBasicParsing

$vcInfo = (Get-Item $vcRedistPath).VersionInfo
Write-Host ("VC++ Runtime: {0}" -f $vcInfo.FileVersion)

$bundleSource = Get-Content $templatePath -Raw -Encoding UTF8
$bundleSource = $bundleSource.Replace("@BUNDLE_VERSION@", $version)
$bundleSource = $bundleSource.Replace("@VCREDIST_PATH@", [Security.SecurityElement]::Escape($vcRedistPath))
$bundleSource = $bundleSource.Replace("@MSI_PATH@", [Security.SecurityElement]::Escape($MsiPath))
$bundleSource = $bundleSource.Replace(
  "@ICON_PATH@",
  [Security.SecurityElement]::Escape((Join-Path $repoRoot "src\apps\res\deskflow.ico"))
)
$generatedWxs = Join-Path $bundleWork "bundle.wxs"
Set-Content -Path $generatedWxs -Value $bundleSource -Encoding UTF8 -NoNewline

$outFile = Join-Path $OutputDir ("KeyboardMouseShareMaster-Setup-{0}-x64.exe" -f $version)
if (Test-Path $outFile) { Remove-Item $outFile -Force }

$wixArgs = @(
  "build",
  "-arch", "x64",
  "-ext", "WixToolset.Bal.wixext",
  "-ext", "WixToolset.Util.wixext",
  "-out", $outFile,
  $generatedWxs
)
& $wixExe @wixArgs

if ($LASTEXITCODE -ne 0) {
  throw "WiX bundle build failed with exit code $LASTEXITCODE"
}

$wixPdb = [IO.Path]::ChangeExtension($outFile, ".wixpdb")
if (Test-Path $wixPdb) {
  Remove-Item $wixPdb -Force
}

$hash = Get-FileHash $outFile -Algorithm SHA256
Write-Host ("Created: {0}" -f $outFile)
Write-Host ("SHA256: {0}" -f $hash.Hash)
