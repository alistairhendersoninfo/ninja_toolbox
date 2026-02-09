# TODO - NinjaMenu

## Completed

### Core Infrastructure
- [x] Create folder structure
- [x] Create CLAUDE.md documentation
- [x] Create script templates
- [x] Create install_menu.sh
- [x] Create main menu.py application
- [x] Add cross-platform shared library (`.lib/platform.sh`)
- [x] Add tool script support with binary dependency checking

### Scripts (79 total)
- [x] Monitoring suite (13 scripts + install-all)
- [x] Network suite (18 scripts + install-all + nmap-tools-bundle)
- [x] LLM & AI tools (Claude, Gemini, Codex, Cursor, Antigravity)
- [x] Git & GitHub tools (setup, test, reset, push-to-repo)
- [x] Post-setup Kali (Node.js, ZSH fix, themes, XRDP, Proxmox tools)
- [x] Proxmox tools (ProxMenux, Toolbox, PVE Helper Scripts)
- [x] Education: nmap scanning, discovery, evasion, footprinting, output, vulnerability (28 scripts)
- [x] Education: nmap-unleashed reporting and scanning (5 scripts)

### GitHub Pages Site (docs/)
- [x] Jekyll site with just-the-docs theme
- [x] Custom `ninjamenu` colour scheme (Prussian Blue, Orange, Grey, White, Black)
- [x] Custom SCSS: `_sass/color_schemes/ninjamenu.scss`, `_sass/custom/custom.scss`, `_sass/custom/setup.scss`
- [x] Homepage with logo in orange block + Big Tracey
- [x] About, Contact, Contribute pages
- [x] Reference section: Getting Started, Architecture, Tool Reference (6 categories), Education
- [x] Meet the Team bio page (all 4 characters)
- [x] 404 page with Little Tracey
- [x] Favicon and Apple touch icon
- [x] OG meta tags and theme-color

### Wiki (.wiki/)
- [x] Home, FAQ, Troubleshooting, Tips & Tricks
- [x] Sidebar, Footer, Script Ideas, Distro Compatibility
- [x] Character images (using `_000000` variants for dark background)

### GitHub Actions
- [x] Pages deployment workflow (`.github/workflows/pages.yml`)
- [x] Wiki Guardian spam detection (`.github/workflows/wiki-guardian.yml` + `.github/scripts/wiki-guardian.sh`)
- [x] Fix wiki-guardian.sh pipefail crash (grep || true pattern)

### Site Characters
- [x] 4 characters defined with bios and page assignments
- [x] 60+ image variants generated (5 subjects x 6 backgrounds x PNG + WebP)
- [x] Image conversion utility (`docs/assets/convert_image.sh`)
- [x] Character guide (`.claude/characters.md`)

### Skills
- [x] `/create-pr` — scaffold new feature branch with draft PR
- [x] `/merge-pr` — check status and merge PR
- [x] `/approve-pr` — admin self-review gate
- [x] `/review-tasks` — read PR review comments, create tasks
- [x] `/ship-it` — full end-to-end: branch → commit → push → PR → merge
- [x] `/trigger-guardian` — test Wiki Guardian with clean or spam edit

### README
- [x] shields.io-style badges (Pages, Wiki, Scripts)
- [x] Centred logo
- [x] Documentation links table (Pages, Wiki, Meet the Team)

## In Progress

- [ ] Verify Wiki Guardian works end-to-end (needs a fresh gollum event to trigger)
- [ ] Push latest character image changes to main (network → it_nerd, LLM → it_nerd+super_nerd, meet-the-team reorder, plus README badges and homepage changes from previous session)

## Backlog

### Enhancements
- [ ] Add search functionality to menu system
- [ ] Add favourites system
- [ ] Add installation history
- [ ] Add batch installation mode
- [ ] Add configuration backup/restore
- [ ] Add update checker for scripts

### Content
- [ ] Complete technical manuals for all categories
- [ ] Add inline help to menu system
- [ ] Add more education scripts (tcpdump, wireshark, etc.)
- [ ] Add penetration testing tool installers
- [ ] Add development environment setups

### Ideas
- [ ] Web-based interface option
- [ ] Remote installation support
- [ ] Script marketplace/repository
- [ ] Auto-update mechanism
