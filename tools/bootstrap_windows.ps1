param(
    [string]$FlutterVersion = "3.44.2"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

Write-Step "Bootstrap SpendWise su Windows"
Write-Host "Repository: $repoRoot"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git non e' disponibile nel PATH. Installa Git e rilancia questo script."
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw "Node.js non e' disponibile nel PATH. Installa Node.js 20+ e rilancia questo script."
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    throw "npm non e' disponibile nel PATH. Installa Node.js 20+ e rilancia questo script."
}

$toolingDir = Join-Path $repoRoot ".tooling"
$flutterDir = Join-Path $toolingDir "flutter"
$flutterBat = Join-Path $flutterDir "bin\flutter.bat"

New-Item -ItemType Directory -Force -Path $toolingDir | Out-Null

if (-not (Test-Path $flutterBat)) {
    Write-Step "Scarico Flutter $FlutterVersion in .tooling"
    $zipPath = Join-Path $toolingDir "flutter_windows_$FlutterVersion-stable.zip"
    $downloadUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$FlutterVersion-stable.zip"

    if (-not (Test-Path $zipPath)) {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
    }

    $extractDir = Join-Path $toolingDir "_flutter_extract"
    if (Test-Path $extractDir) {
        Remove-Item -LiteralPath $extractDir -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

    $extractedFlutter = Join-Path $extractDir "flutter"
    if (-not (Test-Path $extractedFlutter)) {
        throw "Archivio Flutter non valido: cartella flutter non trovata."
    }

    if (Test-Path $flutterDir) {
        Remove-Item -LiteralPath $flutterDir -Recurse -Force
    }

    Move-Item -LiteralPath $extractedFlutter -Destination $flutterDir
    Remove-Item -LiteralPath $extractDir -Recurse -Force
} else {
    Write-Step "Flutter locale gia' presente in .tooling"
}

Write-Step "Verifico Flutter"
& $flutterBat --version
& $flutterBat config --no-analytics | Out-Null

Write-Step "Scarico dipendenze Flutter"
& $flutterBat pub get

Write-Step "Installo dipendenze Worker"
Push-Location (Join-Path $repoRoot "workers")
npm install
Pop-Location

Write-Step "Bootstrap completato"
Write-Host ""
Write-Host "Per avviare SpendWise in locale:" -ForegroundColor Green
Write-Host ".\.tooling\flutter\bin\flutter.bat run -d web-server --web-port 52100 --dart-define=API_URL=https://spendwise.lopreteangelo97.workers.dev/api"

