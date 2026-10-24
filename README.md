# Oh-My-Posh Theme Switcher

A single PowerShell script (`OmpThemes.ps1`) to list, preview, switch and download [oh-my-posh](https://ohmyposh.dev) themes.

## Requirements
- PowerShell 7+
- The standalone `oh-my-posh` binary (v18 or newer), installed with `winget install JanDeDobbeleer.OhMyPosh -s winget` or any method from https://ohmyposh.dev/docs/installation/windows. It is looked up on `PATH` first, then in the usual install folders (winget, installer, scoop, chocolatey).
- A Nerd Font in your terminal (otherwise preview glyphs look garbled)

> **Old installations:** the deprecated oh-my-posh *PowerShell module* (`Install-Module oh-my-posh`, v3.x, `Import-Module oh-my-posh` + `Set-PoshPrompt` in the profile) is **not** supported: its bundled v3 binary has a different command line and cannot render current (schema version 3/4) themes. The switcher detects it and warns; run `omp-upgrade` (`Install-OhMyPosh`) or menu option 6 to install the current binary via winget. `omp-set` then comments out the old `Import-Module oh-my-posh` / `Set-PoshPrompt` lines in your profile. Remove the module afterwards with `Uninstall-Module oh-my-posh -AllVersions` (or `omp-upgrade -RemoveLegacyModule`).

## Setup
Add to your `$PROFILE` (before the `oh-my-posh init` line):

```powershell
$env:OMP_THEMES_DIR = "$HOME\.config\ohmyposh"   # optional; this is the default
. C:\repo\jeroen\oh-my-posh-switcher\OmpThemes.ps1
```

`OMP_THEMES_DIR` is the folder holding your `*.omp.json|yaml|toml` themes. It is created if missing. Themes from `$env:POSH_THEMES_PATH` (the stock themes some installers ship) and from this repo's `themes\` folder are listed as well; precedence is `themes\` > `OMP_THEMES_DIR` > `POSH_THEMES_PATH`.

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
| 6 | Install or upgrade the oh-my-posh binary via winget |

### Commands (after dot-sourcing in your profile)

| Command | Alias | Description |
|---|---|---|
| `Select-OmpTheme` | `omp-theme` | Interactive picker: Up/Down/PageUp/PageDown, Enter applies, Esc/Q cancels |
| `Get-OmpTheme [name] [-Preview]` | `omp-list` | List themes (current marked `*`); `-Preview` renders each prompt |
| `Set-OmpTheme <name> [-NoPersist]` | `omp-set` | Switch the current shell (Tab completes) and save to profile |
| `Install-OmpTheme [names] [-List] [-All] [-Force] [-Apply]` | `omp-install` | List or download themes from [JanDeDobbeleer/oh-my-posh/themes](https://github.com/JanDeDobbeleer/oh-my-posh/tree/main/themes); names accept wildcards |
| `Install-OhMyPosh [-RemoveLegacyModule]` | `omp-upgrade` | Install or upgrade the oh-my-posh binary with winget and make it available in the current session; optionally uninstall the deprecated PowerShell module |
| `Show-OmpMenu` / `Show-OmpHelp` | `omp-menu` / `omp-help` | Menu and help text |

Examples:
```powershell
omp-install agnoster, tokyo*     # download
omp-set agnoster                 # switch now and persist
omp-list -Preview                # see them all
```

## How it works
- **Persistence:** `Set-OmpTheme` rewrites the first active `oh-my-posh init pwsh` line in `$PROFILE` (extra active ones and legacy `Import-Module oh-my-posh` / `Set-PoshPrompt` lines are commented out; a `.bak` copy is made first).
- **Binary lookup:** `Get-OmpExe` resolves the executable once per session (PATH, then known install folders, and adds that folder to `PATH` so the profile's init line works too). Without a usable binary every command fails with a message pointing at `omp-upgrade`.
- **Previews:** rendered with `oh-my-posh print primary`, using a fresh session id (otherwise oh-my-posh reuses the active theme) and UTF-8 output.
- **Downloads:** GitHub contents API; existing files are skipped unless `-Force`. Set `$env:GITHUB_TOKEN` to avoid the unauthenticated rate limit (60 requests/hour).

## Custom themes
Your own themes live in `themes\<name>\` (see `themes\README.md`). The switcher scans that folder automatically, so they appear alongside the downloaded ones.

## Notes
- Running the script directly (not dot-sourced) saves the theme for new shells but won't change the current prompt; use `omp-theme` / `omp-set` for that.
