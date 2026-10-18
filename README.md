# Oh-My-Posh Theme Switcher

A single PowerShell script (`OmpThemes.ps1`) to list, preview, switch and download [oh-my-posh](https://ohmyposh.dev) themes.

## Requirements
- PowerShell 7+
- `oh-my-posh` on your `PATH`
- A Nerd Font in your terminal (otherwise preview glyphs look garbled)

## Setup
Add to your `$PROFILE` (before the `oh-my-posh init` line):

```powershell
$env:OMP_THEMES_DIR = "$HOME\.config\ohmyposh"   # optional; this is the default
. C:\repo\jeroen\oh-my-posh-switcher\OmpThemes.ps1
```

`OMP_THEMES_DIR` is the folder holding your `*.omp.json|yaml|toml` themes. It is created if missing.

## Usage

### Menu
Run `.\OmpThemes.ps1` directly (or `omp-menu` once loaded):

| Option | Action |
|---|---|
| 1 | Browse and switch theme with live preview |
| 2 | List installed themes |
| 3 | Preview all installed themes |
| 4 | Download themes from GitHub (filter, pick numbers or `all`) |
| 5 | Help |

### Commands (after dot-sourcing in your profile)

| Command | Alias | Description |
|---|---|---|
| `Select-OmpTheme` | `omp-theme` | Interactive picker: Up/Down/PageUp/PageDown, Enter applies, Esc/Q cancels |
| `Get-OmpTheme [name] [-Preview]` | `omp-list` | List themes (current marked `*`); `-Preview` renders each prompt |
| `Set-OmpTheme <name> [-NoPersist]` | `omp-set` | Switch the current shell (Tab completes) and save to profile |
| `Install-OmpTheme [names] [-List] [-All] [-Force] [-Apply]` | `omp-install` | List or download themes from [JanDeDobbeleer/oh-my-posh/themes](https://github.com/JanDeDobbeleer/oh-my-posh/tree/main/themes); names accept wildcards |
| `Show-OmpMenu` / `Show-OmpHelp` | `omp-menu` / `omp-help` | Menu and help text |

Examples:
```powershell
omp-install agnoster, tokyo*     # download
omp-set agnoster                 # switch now and persist
omp-list -Preview                # see them all
```

## How it works
- **Persistence:** `Set-OmpTheme` rewrites the first active `oh-my-posh init pwsh` line in `$PROFILE` (extra active ones are commented out; a `.bak` copy is made first).
- **Previews:** rendered with `oh-my-posh print primary`, using a fresh session id (otherwise oh-my-posh reuses the active theme) and UTF-8 output.
- **Downloads:** GitHub contents API; existing files are skipped unless `-Force`. Set `$env:GITHUB_TOKEN` to avoid the unauthenticated rate limit (60 requests/hour).

## Notes
- Running the script directly (not dot-sourced) saves the theme for new shells but won't change the current prompt; use `omp-theme` / `omp-set` for that.
