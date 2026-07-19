$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $script:failures.Add($Message)
}

function Require-File {
    param([string]$RelativePath)

    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Missing file: $RelativePath"
        return $null
    }

    return $path
}

function Require-Literal {
    param(
        [string]$Content,
        [string]$Expected,
        [string]$Context
    )

    if (-not $Content.Contains($Expected)) {
        Add-Failure "$Context does not contain: $Expected"
    }
}

function Forbid-Literal {
    param(
        [string]$Content,
        [string]$Forbidden,
        [string]$Context
    )

    if ($Content.Contains($Forbidden)) {
        Add-Failure "$Context still contains forbidden content: $Forbidden"
    }
}

function Require-Xml {
    param([string]$RelativePath)

    $path = Require-File $RelativePath
    if (-not $path) {
        return
    }

    try {
        [void][xml](Get-Content -Raw -LiteralPath $path)
    }
    catch {
        Add-Failure "Invalid XML in ${RelativePath}: $($_.Exception.Message)"
    }
}

$readmePath = Require-File 'README.md'
if ($readmePath) {
    $readme = Get-Content -Raw -LiteralPath $readmePath

    @(
        'assets/header-dark.svg',
        'assets/header-light.svg',
        'profile-3d-contrib/profile-cosmic.svg',
        'github-snake.svg',
        'github-snake-dark.svg',
        'Nia',
        'darkcupid412',
        'I am an evil intergalactic cat.',
        'BetterHurricane',
        'Geyser',
        'i=java%2Cgradle%2Cgit%2Cgithub%2Cidea%2Cvscode'
    ) | ForEach-Object {
        Require-Literal $readme $_ 'README.md'
    }

    @(
        'github-readme-activity-graph',
        'herokuapp',
        'github-profile-trophy',
        'visitor-badge',
        'profile-views',
        'i=java,gradle,git,github,idea,vscode'
    ) | ForEach-Object {
        Forbid-Literal $readme $_ 'README.md'
    }
}

$workflowPath = Require-File '.github/workflows/profile-3d.yml'
if ($workflowPath) {
    $workflow = Get-Content -Raw -LiteralPath $workflowPath

    @(
        'workflow_dispatch:',
        'cron:',
        'contents: write',
        'actions/checkout@v4',
        'yoshi389111/github-profile-3d-contrib@v0.9.3',
        'USERNAME: ${{ github.repository_owner }}',
        'SETTING_JSON: .github/profile-3d-settings.json'
    ) | ForEach-Object {
        Require-Literal $workflow $_ '.github/workflows/profile-3d.yml'
    }
}

$settingsPath = Require-File '.github/profile-3d-settings.json'
if ($settingsPath) {
    try {
        $settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json
        if ($settings.fileName -ne 'profile-cosmic.svg') {
            Add-Failure '.github/profile-3d-settings.json must generate profile-cosmic.svg'
        }
        if (-not $settings.darkMode) {
            Add-Failure '.github/profile-3d-settings.json must contain a darkMode palette'
        }
    }
    catch {
        Add-Failure "Invalid JSON in .github/profile-3d-settings.json: $($_.Exception.Message)"
    }
}

Require-Xml 'assets/header-dark.svg'
Require-Xml 'assets/header-light.svg'
Require-Xml 'profile-3d-contrib/profile-cosmic.svg'

if ($failures.Count -gt 0) {
    Write-Host 'Profile validation failed:'
    $failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host 'Profile validation passed.'
