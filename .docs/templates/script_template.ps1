# TODO: Windows PowerShell implementation
# script_template.ps1 — Tier 2 Windows script template
#
# This is the template for OS-agnostic Tier 2 install scripts on Windows.
# Uses platform.ps1 for cross-platform package management (winget/choco/scoop).
#
# Template:
#
# param(
#     [ValidateSet("install", "uninstall")]
#     [string]$Action = "install"
# )
#
# $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# $MenuRoot = (Get-Item $ScriptDir).Parent.FullName
# . "$MenuRoot\.lib\platform.ps1"
#
# switch ($Action) {
#     "install" {
#         Write-Info "Installing <tool>..."
#         Install-Pkg "<package>"
#         Mark-Installed $true
#         Write-Success "<tool> installed successfully"
#     }
#     "uninstall" {
#         Write-Info "Uninstalling <tool>..."
#         Remove-Pkg "<package>"
#         Mark-Installed $false
#         Write-Success "<tool> uninstalled successfully"
#     }
# }

Write-Host "Tier 2 Windows template — not yet implemented." -ForegroundColor Yellow
