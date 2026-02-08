# Wiki Templates

This directory contains the template pages for the GitHub Wiki. The actual wiki is a separate git repo (`ninja_toolbox.wiki.git`), but we keep the templates here so they're version-controlled alongside the main codebase.

## Initial Setup

The wiki must be initialised via the GitHub UI before these templates can be pushed:

1. Go to https://github.com/alistairhendersoninfo/ninja_toolbox/wiki
2. Click "Create the first page"
3. Save (content doesn't matter -- we'll overwrite it)
4. Then push the templates:

```bash
git clone https://github.com/alistairhendersoninfo/ninja_toolbox.wiki.git /tmp/wiki
cp .wiki/*.md /tmp/wiki/
cd /tmp/wiki
git add -A
git commit -m "Add wiki template pages"
git push
```

## Updating Wiki Templates

If you update templates here, push them to the wiki repo:

```bash
git clone https://github.com/alistairhendersoninfo/ninja_toolbox.wiki.git /tmp/wiki
cp .wiki/*.md /tmp/wiki/
cd /tmp/wiki
git add -A
git commit -m "Update wiki templates from main repo"
git push
```

## Files

| File | Purpose |
|------|---------|
| `Home.md` | Wiki landing page with navigation and guidelines |
| `_Sidebar.md` | Sidebar navigation (appears on every page) |
| `_Footer.md` | Footer with links (appears on every page) |
| `FAQ.md` | Frequently asked questions |
| `Troubleshooting.md` | Common problems and community-sourced fixes |
| `Distro-Compatibility.md` | Platform compatibility matrix |
| `Script-Ideas.md` | Community wishlist of tools to add |
| `Tips-and-Tricks.md` | Power-user tips and workflow ideas |
