# Keystone setup script for Windows (OSS tier)
# Detects host and configures accordingly

param(
    [string]$SkillsRoot = "$env:USERPROFILE\.claude\skills",
    [string]$CavemanMode = "off"
)

Write-Host "Setting up Keystone (OSS tier) on Windows..."

# Determine the host CLI
$HostCLI = $null
if (Get-Command claude -ErrorAction SilentlyContinue) {
    $HostCLI = "claude"
} elseif (Get-Command kilo -ErrorAction SilentlyContinue) {
    $HostCLI = "kilo"
} elseif (Get-Command gemini -ErrorAction SilentlyContinue) {
    $HostCLI = "gemini"
} else {
    Write-Error "Error: No supported host CLI found (Claude Code, Kilo Code, or Gemini CLI)"
    exit 1
}

Write-Host "Detected host: $HostCLI"

# Create skills root directory if it doesn't exist
New-Item -ItemType Directory -Force -Path $SkillsRoot | Out-Null

# Install each skill as its own directory with SKILL.md
# Claude Code expects: ~/.claude/skills/<skill-name>/SKILL.md
$SkillsPath = Join-Path $PSScriptRoot "skills"
if (Test-Path $SkillsPath) {
    $skillFiles = Get-ChildItem -Path $SkillsPath -Filter "keystone-*.md"
    foreach ($skillFile in $skillFiles) {
        $skillName = [System.IO.Path]::GetFileNameWithoutExtension($skillFile.Name)
        $skillDir = Join-Path $SkillsRoot $skillName

        New-Item -ItemType Directory -Force -Path $skillDir | Out-Null

        $content = Get-Content -Raw -Path $skillFile.FullName
        # Replace {{CAVEMAN_MODE}} placeholder with configured value
        $content = $content -replace '\{\{CAVEMAN_MODE\}\}', $CavemanMode

        Set-Content -Path (Join-Path $skillDir "SKILL.md") -Value $content -NoNewline
        Write-Host "  Installed skill: $skillName"
    }
}

# Copy tools and adapters into a shared keystone support directory
$KeystoneDir = Join-Path $SkillsRoot "keystone"
New-Item -ItemType Directory -Force -Path $KeystoneDir | Out-Null

$ToolsPath = Join-Path $PSScriptRoot "tools"
if (Test-Path $ToolsPath) {
    $ToolsDest = Join-Path $KeystoneDir "tools"
    New-Item -ItemType Directory -Force -Path $ToolsDest | Out-Null
    Copy-Item -Path "$ToolsPath\*" -Destination $ToolsDest -Recurse -Force
}

$AdaptersPath = Join-Path $PSScriptRoot "adapters"
if (Test-Path $AdaptersPath) {
    $AdaptersDest = Join-Path $KeystoneDir "adapters"
    New-Item -ItemType Directory -Force -Path $AdaptersDest | Out-Null
    Copy-Item -Path "$AdaptersPath\*" -Destination $AdaptersDest -Recurse -Force
}

# Create decisions directory for ADR exports
$DecisionsDest = Join-Path $KeystoneDir "decisions"
New-Item -ItemType Directory -Force -Path $DecisionsDest | Out-Null

# Copy reference files into keystone support dir
$filesToCopy = @("CLAUDE.md", "ARCHITECTURE.md", "ETHOS.md", "CONTRIBUTING.md", "CHANGELOG.md")
foreach ($file in $filesToCopy) {
    $filePath = Join-Path $PSScriptRoot $file
    if (Test-Path $filePath) {
        Copy-Item -Path $filePath -Destination $KeystoneDir -Force
    }
}

Write-Host ""
Write-Host "Keystone OSS tier setup complete!"
Write-Host "Skills installed:"
Write-Host "  /keystone-req  — Requirements clarification"
Write-Host "  /keystone-est  — Back-of-envelope estimation"
Write-Host "  /keystone-hld  — High-level design + Mermaid diagram"
Write-Host "  /keystone-adr  — Architecture Decision Record"
Write-Host ""
Write-Host "Run '/keystone-req --help' in Claude Code to get started."
