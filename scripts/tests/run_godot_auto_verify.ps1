param(
    [string]$GodotExe = "",
    [switch]$FixCache = $true,
    [switch]$SkipSceneSmoke = $false,
    [switch]$SkipValidation = $false
)

$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$ValidationScript = Join-Path $ProjectRoot "scripts\tests\run_godot_validation.ps1"
$MainMenuScene = "res://scenes/ui/main_menu.tscn"
$MainScene = "res://scenes/main/main.tscn"
$CriticalRegexStrict = "Parse Error:|Compile Error:|Failed to load script|Unrecognized UID|Failed to create an autoload|hides an autoload singleton|Identifier not found"
$CriticalRegexBroad = "ERROR:|SCRIPT ERROR:|Parse Error:|Compile Error:|Failed to load script|Failed loading resource:|Unrecognized UID"

function Resolve-GodotExe {
    param([string]$CurrentValue)

    if (-not [string]::IsNullOrWhiteSpace($CurrentValue) -and (Test-Path -LiteralPath $CurrentValue -PathType Leaf)) {
        return $CurrentValue
    }

    $candidates = @(
        (Join-Path $env:USERPROFILE "Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"),
        (Join-Path $env:USERPROFILE "Downloads\Godot_v4.6.2-stable_win64_console.exe"),
        (Join-Path $env:USERPROFILE "Downloads\Godot_v4.6.2-stable_win64.exe")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    throw "Godot console executable not found. Passe -GodotExe com o caminho completo."
}

function Invoke-GodotStep {
    param(
        [string]$StepName,
        [string[]]$Arguments,
        [string]$GodotPath,
        [string]$CriticalPattern
    )

    Write-Host "==> $StepName"
    $rawOutput = & $GodotPath @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $lines = @($rawOutput | ForEach-Object { "$_" })
    $critical = @($lines | Where-Object { $_ -match $CriticalPattern })

    foreach ($line in $critical) {
        Write-Host $line
    }

    if ($exitCode -ne 0) {
        throw "$StepName falhou (exit code: $exitCode)."
    }

    return $critical
}

Set-Location $ProjectRoot
$GodotExe = Resolve-GodotExe -CurrentValue $GodotExe

$allCritical = @()

if ($FixCache) {
    $godotCache = Join-Path $ProjectRoot ".godot"
    if (Test-Path -LiteralPath $godotCache) {
        Write-Host "==> Limpando cache .godot"
        $previousProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"
        try {
            Remove-Item -LiteralPath $godotCache -Recurse -Force
        } finally {
            $ProgressPreference = $previousProgressPreference
        }
    }
}

# Import primeiro para evitar falsos positivos de loading em editor metadata recem limpo.
$allCritical += Invoke-GodotStep -StepName "Import assets" -Arguments @("--headless", "--path", $ProjectRoot, "--import") -GodotPath $GodotExe -CriticalPattern $CriticalRegexStrict
$allCritical += Invoke-GodotStep -StepName "Rebuild editor metadata" -Arguments @("--headless", "--path", $ProjectRoot, "--editor", "--quit") -GodotPath $GodotExe -CriticalPattern $CriticalRegexStrict

if (-not $SkipSceneSmoke) {
    $allCritical += Invoke-GodotStep -StepName "Smoke scene main_menu" -Arguments @("--headless", "--path", $ProjectRoot, "--scene", $MainMenuScene, "--quit-after", "2") -GodotPath $GodotExe -CriticalPattern $CriticalRegexBroad
    $allCritical += Invoke-GodotStep -StepName "Smoke scene main" -Arguments @("--headless", "--path", $ProjectRoot, "--scene", $MainScene, "--quit-after", "2") -GodotPath $GodotExe -CriticalPattern $CriticalRegexBroad
}

if (-not $SkipValidation) {
    if (-not (Test-Path -LiteralPath $ValidationScript -PathType Leaf)) {
        throw "Validation script nao encontrado: $ValidationScript"
    }

    Write-Host "==> Executando suite de validacao"
    $validationOutput = & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $ValidationScript -GodotExe $GodotExe 2>&1
    $validationExitCode = $LASTEXITCODE
    $validationLines = @($validationOutput | ForEach-Object { "$_" })
    $validationCritical = @($validationLines | Where-Object { $_ -match $CriticalRegexBroad })

    foreach ($line in $validationCritical) {
        Write-Host $line
    }

    $allCritical += $validationCritical

    if ($validationExitCode -ne 0) {
        throw "Suite de validacao falhou (exit code: $validationExitCode)."
    }
}

$uniqueCritical = @($allCritical | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)

if ($uniqueCritical.Count -gt 0) {
    Write-Host ""
    Write-Host "RESULT: FAIL"
    Write-Host "Erros criticos detectados:"
    foreach ($line in $uniqueCritical) {
        Write-Host "- $line"
    }
    exit 2
}

Write-Host ""
Write-Host "RESULT: PASS"
Write-Host "Godot verificado sem erros criticos (UID/autoload/compile/runtime)."
exit 0
