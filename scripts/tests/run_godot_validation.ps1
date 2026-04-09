param(
    [string]$GodotExe = ""
)

$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$ValidationScene = "res://scenes/tests/core_loop_validation.tscn"

if ([string]::IsNullOrWhiteSpace($GodotExe)) {
    $Candidates = @(
        (Join-Path $env:USERPROFILE "Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe"),
        (Join-Path $env:USERPROFILE "Downloads\Godot_v4.6.2-stable_win64_console.exe"),
        (Join-Path $env:USERPROFILE "Downloads\Godot_v4.6.2-stable_win64.exe")
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
            $GodotExe = $Candidate
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($GodotExe) -or -not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    throw "Godot console executable not found. Pass -GodotExe with the full path."
}

& $GodotExe --headless --path $ProjectRoot --scene $ValidationScene
exit $LASTEXITCODE
