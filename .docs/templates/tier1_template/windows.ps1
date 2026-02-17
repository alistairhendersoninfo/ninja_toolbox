# TODO: Windows PowerShell implementation
# windows.ps1 — Tier 1 Windows script template
#
# This is the template for OS-specific Tier 1 scripts on Windows.
# Each Tier 1 modular folder can include a windows.ps1 alongside
# macos.sh and linux.sh for Windows-native installation.
#
# Template:
#
# param(
#     [ValidateSet("install", "uninstall")]
#     [string]$Action = "install"
# )
#
# . "$PSScriptRoot\_common.ps1"
#
# switch ($Action) {
#     "install" {
#         Write-Info "Installing <tool> on Windows..."
#         winget install <package-id>
#         Mark-Installed $true
#         Write-Success "<tool> installed successfully"
#     }
#     "uninstall" {
#         Write-Info "Uninstalling <tool> on Windows..."
#         winget uninstall <package-id>
#         Mark-Installed $false
#         Write-Success "<tool> uninstalled successfully"
#     }
# }

Write-Host "Tier 1 Windows template — not yet implemented." -ForegroundColor Yellow
