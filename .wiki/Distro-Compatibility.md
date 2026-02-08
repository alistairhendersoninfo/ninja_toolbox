# Distro Compatibility

Community-reported test results across different platforms. Help us by testing NinjaMenu on your system and adding a row.

## Compatibility Matrix

| Distro | Version | Architecture | Status | Notes | Reported By |
|--------|---------|-------------|--------|-------|-------------|
| Kali Linux | 2024.1+ | x86_64 | Fully supported | Primary target platform | @alistairhendersoninfo |
| Debian | 12 (Bookworm) | x86_64 | Fully supported | | @alistairhendersoninfo |
| Ubuntu | 22.04+ | x86_64 | Fully supported | | @alistairhendersoninfo |
| macOS | 14+ (Sonoma) | Apple Silicon (arm64) | Fully supported | Requires Homebrew | @alistairhendersoninfo |
| macOS | 14+ (Sonoma) | Intel (x86_64) | Fully supported | Requires Homebrew | @alistairhendersoninfo |

## How to Report

1. Edit this page
2. Add a row to the table above with your test results
3. Use one of these status values:
   - **Fully supported** -- Everything works
   - **Mostly works** -- Minor issues (describe in Notes)
   - **Partial** -- Some scripts work, some don't (describe in Notes)
   - **Broken** -- Fundamental issues (describe in Notes and open an [issue](https://github.com/alistairhendersoninfo/ninja_toolbox/issues/new))
4. Include your GitHub username so we can follow up if needed

## Menu Backend Compatibility

| Backend | Linux | macOS | Notes |
|---------|-------|-------|-------|
| gum | Yes | Yes | Default backend |
| whiptail | Yes | No | Linux only |
| dialog | Yes | Yes | Fallback |
| textual | Yes | Yes | Requires Python venv |
