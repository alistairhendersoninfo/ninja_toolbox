# NinjaMenu Characters

The site uses four illustrated characters to add personality and guide users through the documentation. This file defines each character, their role, and which pages they appear on.

## Characters

### Little Tracey Ninja (`little_tracey_ninja_`)

**Role:** Site worker — handles day-to-day tasks, guides, and general documentation.

**Personality:** Enthusiastic, hands-on ninja technician. Best friends with Big Tracey for 30+ years. Trained by masters in the dark art of IT — the ancient discipline of turning it off and on again. Specialises in the GUI world from Windows 95 through to Windows 11. Knows every Control Panel shortcut, every right-click context menu, and every "Have you tried restarting?" incantation.

**Appears on:**
- `docs/index.md` — Homepage hero
- `docs/contribute.md` — Encouraging contributions
- `docs/reference/getting-started.md` — Guiding new users
- `docs/reference/tools/index.md` — Tool reference overview
- `.wiki/Home.md` — Wiki welcome
- `.wiki/Tips-and-Tricks.md` — Power-user tips

### Big Tracey Ninja (`big_tracey_ninja_`)

**Role:** Site worker — handles day-to-day tasks, guides, and general documentation. Married to IT Super Nerd.

**Personality:** The other half of the legendary Tracey duo. 30+ years of friendship forged in the fires of blue screens and "General Protection Fault" dialogs. A ninja technician who cut her teeth on Windows 95's Start menu and never looked back. Specialist in desktop support, user training, and explaining to people why they can't use "password123" as their password.

**Appears on:**
- `docs/about.md` — Project story
- `docs/contact.md` — Contact page
- `docs/reference/index.md` — Docs hub
- `.wiki/FAQ.md` — Community FAQ
- `.wiki/Troubleshooting.md` — Troubleshooting guide

### IT Nerd (`it_nerd_`)

**Role:** The father of the group — old-school infrastructure guru.

**Personality:** The grizzled veteran. Beard. Slippers. A mug that says "There's no place like 127.0.0.1." He was configuring UNIX systems before most people had email. Speaks fluent DEC VAX, IBM DB2, AS/400, MS-DOS, and Windows 3.11. Can navigate a green screen telnet session and 5250 emulation blindfolded. Thinks the command line is the only real interface and that GUIs are "just a phase." Still has a working floppy drive. Just in case.

**Appears on:**
- `docs/reference/architecture.md` — System internals
- `docs/reference/education/index.md` — Education overview
- `README.md` — Root readme (optional, keep lightweight)

### IT Super Nerd (`it_super_nerd_`)

**Role:** The brains — writes complex, in-depth educational and technical content. Married to Big Tracey.

**Personality:** Knows both sides of the fence. Old school: UNIX, mainframes, green screens, COBOL. New school: AWS, Kubernetes, LLMs, AI. Networks, servers, storage, security, ERP software, business intelligence, open-source evangelism — he's done it all. The living proof that nerds can get married (to Big Tracey, no less). If it has a CLI, an API, or a config file, he's already written a script for it.

**Appears on:**
- `docs/reference/architecture.md` — Deep technical content (alongside IT Nerd)
- Education scripts and pages (nmap, network analysis, etc.)
- `.wiki/` technical pages
- Any page with in-depth technical walkthroughs

## Image Variants

Each character has images prepared for every site background colour:

| Suffix | Background | Use on |
|--------|-----------|--------|
| `_transparent` | Transparent | Flexible use, overlays |
| `_000000` | Black | Dark accent areas |
| `_14213d` | Prussian Blue | **Main docs site pages** (default) |
| `_fca311` | Orange | Header areas, callouts |
| `_e5e5e5` | Alabaster Grey | Footer areas |
| `_ffffff` | White | **Wiki pages**, GitHub README |

Both `.png` and `.webp` formats are available. Use `.png` in markdown (broader compatibility).

**Image path pattern:** `docs/assets/images/{character}_{colour}.png`

## Page Assignment Summary

| Page | Character(s) | Why |
|------|-------------|-----|
| Homepage (`index.md`) | Little Tracey | Welcoming, approachable |
| About (`about.md`) | Big Tracey | Tells the project story |
| Contact (`contact.md`) | Big Tracey | Friendly contact point |
| Contribute (`contribute.md`) | Little Tracey | Encouraging new contributors |
| Meet the Team (`meet-the-team.md`) | All four | Bio page |
| Docs Hub (`reference/index.md`) | Big Tracey | Guides through documentation |
| Getting Started (`getting-started.md`) | Little Tracey | Guides new users |
| Architecture (`architecture.md`) | IT Nerd + IT Super Nerd | Deep technical content |
| Tools Index (`tools/index.md`) | Little Tracey | Tool overview |
| Education Index (`education/index.md`) | IT Super Nerd | Educational content expert |
| 404 Page (`404.md`) | Little Tracey | Lighthearted lost page |
| Wiki Home | Little Tracey | Welcome to wiki |
| Wiki FAQ | Big Tracey | Community FAQ |
| Wiki Troubleshooting | Big Tracey | Helping with issues |
| Wiki Tips & Tricks | Little Tracey | Power-user tips |
