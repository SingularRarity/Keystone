# Keystone setup script for Windows (OSS tier)
# Detects host and configures accordingly

param(
    [string]$InstallPath = "$env:USERPROFILE\.claude\skills\keystone"
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

# Create skills directory if it doesn't exist
$SkillsDir = $InstallPath
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

# Copy skill files
$SkillsPath = Join-Path $PSScriptRoot "skills"
if (Test-Path $SkillsPath) {
    Copy-Item -Path "$SkillsPath\*" -Destination $SkillsDir -Force
}

# Copy tools
$ToolsPath = Join-Path $PSScriptRoot "tools"
$ToolsDest = Join-Path $SkillsDir "tools"
if (Test-Path $ToolsPath) {
    New-Item -ItemType Directory -Force -Path $ToolsDest | Out-Null
    Copy-Item -Path "$ToolsPath\*" -Destination $ToolsDest -Force
}

# Copy adapters
$AdaptersPath = Join-Path $PSScriptRoot "adapters"
$AdaptersDest = Join-Path $SkillsDir "adapters"
if (Test-Path $AdaptersPath) {
    New-Item -ItemType Directory -Force -Path $AdaptersDest | Out-Null
    Copy-Item -Path "$AdaptersPath\*" -Destination $AdaptersDest -Force
}

# Create decisions directory
$DecisionsDest = Join-Path $SkillsDir "decisions"
New-Item -ItemType Directory -Force -Path $DecisionsDest | Out-Null

# Copy CLAUDE.md
$ClaudeMdPath = Join-Path $PSScriptRoot "CLAUDE.md"
if (Test-Path $ClaudeMdPath) {
    Copy-Item -Path $ClaudeMdPath -Destination $SkillsDir -Force
}

# Copy other files
$filesToCopy = @("ARCHITECTURE.md", "ETHOS.md", "CONTRIBUTING.md", "CHANGELOG.md", "LICENSE")
foreach ($file in $filesToCopy) {
    $filePath = Join-Path $PSScriptRoot $file
    if (Test-Path $filePath) {
        Copy-Item -Path $filePath -Destination $SkillsDir -Force
    }
}

# Run TypeScript setup if available (placeholder)
$SetupTsPath = Join-Path $PSScriptRoot "setup.ts"
if (Test-Path $SetupTsPath) {
    Write-Host "Running TypeScript setup..."
    # In a real implementation, this would run tsx or similar
    Write-Host "TypeScript setup placeholder - would detect host and create symlinks"
}

Write-Host "Keystone OSS tier setup complete!"
Write-Host "Run '/keystone-req --help' to get started."