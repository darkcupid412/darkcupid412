$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$panelPaths = @(
    'assets/profile-hero.svg',
    'assets/profile-overview.svg',
    'assets/project-betterhurricane.svg',
    'assets/project-geyser.svg'
)

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
        Add-Failure "$Context contains forbidden content: $Forbidden"
    }
}

$readmePath = Require-File 'README.md'
if ($readmePath) {
    $readme = Get-Content -Raw -LiteralPath $readmePath

    $panelPaths | ForEach-Object {
        Require-Literal $readme $_ 'README.md'
    }

    @(
        'https://github.com/darkcupid412/BetterHurricane',
        'https://github.com/darkcupid412/Geyser',
        'github-snake.svg',
        'github-snake-dark.svg'
    ) | ForEach-Object {
        Require-Literal $readme $_ 'README.md'
    }

    @(
        'readme-typing-svg',
        'skillicons.dev',
        'github-readme-activity-graph',
        'github-readme-streak-stats',
        'herokuapp',
        'github-profile-summary-cards',
        'github-profile-trophy',
        '<table'
    ) | ForEach-Object {
        Forbid-Literal $readme $_ 'README.md'
    }

    if ([regex]::Matches($readme, 'align="top"').Count -lt 5) {
        Add-Failure 'README.md must top-align all four panels and the snake'
    }

    if ([regex]::Matches($readme, 'width="50%"').Count -ne 2) {
        Add-Failure 'README.md must render both project cards at exactly half width'
    }

    @(
        'assets/contribution-skyline.svg',
        'Contribution skyline',
        'bridging editions, bending protocols, fixing collisions',
        'width="49.5%"'
    ) | ForEach-Object {
        Forbid-Literal $readme $_ 'README.md'
    }
}

$snakeWorkflowPath = Require-File '.github/workflows/snake.yml'
if ($snakeWorkflowPath) {
    $snakeWorkflow = Get-Content -Raw -LiteralPath $snakeWorkflowPath

    @(
        'color_snake=%23ffffff',
        'color_dots=%232d3032,%232d3032,%233b6485,%234f87b3,%2379bdf0'
    ) | ForEach-Object {
        Require-Literal $snakeWorkflow $_ 'snake.yml'
    }
}

$panelContent = ''
foreach ($relativePath in $panelPaths) {
    $path = Require-File $relativePath
    if (-not $path) {
        continue
    }

    try {
        [void][xml](Get-Content -Raw -LiteralPath $path)
        $panelContent += Get-Content -Raw -LiteralPath $path
    }
    catch {
        Add-Failure "Invalid XML in ${relativePath}: $($_.Exception.Message)"
    }
}

@(
    '@darkcupid412',
    'Nia',
    'I am an evil intergalactic cat.',
    '1,135',
    'Current orbit',
    'Java',
    'Gradle',
    'Minecraft protocol',
    'Cross-play',
    'Recent work',
    'BetterHurricane',
    'Geyser',
    'fork'
) | ForEach-Object {
    Require-Literal $panelContent $_ 'SVG panels'
}

@(
    'Commit',
    'PullReq',
    'Review',
    'Repo',
    'language',
    'radar',
    'pie-chart',
    'Contribution skyline',
    'bridging editions, bending protocols, fixing collisions'
) | ForEach-Object {
    Forbid-Literal $panelContent $_ 'SVG panels'
}

if ($failures.Count -gt 0) {
    Write-Host 'Reference profile validation failed:'
    $failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host 'Reference profile validation passed.'
