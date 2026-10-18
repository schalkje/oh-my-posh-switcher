# Custom themes

Each theme lives in its own subfolder: `themes\<name>\<name>.omp.json` plus a `README.md` that is the **design spec** of that theme (see "Regenerating a theme").

`OmpThemes.ps1` scans this folder recursively, so every theme here shows up in `omp-theme`, `omp-list` and `omp-set <name>` next to the ones in `OMP_THEMES_DIR`. If a name exists in both places, the one here wins. No copying needed.

| Theme | Lines | Description |
|---|---|---|
| [schalkje](schalkje) | 2 | The default: time, CPU/mem, duration, path left; git + node right |
| [schalkje-lean](schalkje-lean) | 2 | Minimal: os, path, git left; duration + time right |
| [schalkje-full](schalkje-full) | 3 | Everything: metrics, languages, battery, session, path + git on their own line |

All three share the look: the Lambda Generation colour palette on the block/separator layout of Wholespace, a `❯` input line close to the left edge, an elevated-shell marker (like Powerlevel10k rainbow) and a **transient prompt** that keeps time, duration, CPU/mem and branch in the scrollback.

## Use
```powershell
omp-list schalkje -Preview      # preview one
omp-list schalkje* -Preview     # compare all three
omp-set schalkje-full           # apply and persist
```

## Add a theme
1. `mkdir themes\<name>`, create `<name>.omp.json` and `README.md` in it.
2. Preview with `omp-list <name> -Preview`; apply with `omp-set <name>`.

## Regenerating a theme
Every theme README lists the palette, the blocks/segments (in order) and the transient template. To change a theme, edit that README first and then have the JSON regenerated from it (ask Copilot: *"regenerate themes\schalkje-lean from its README"*), or edit the JSON by hand and update the README to match.

## Shared building blocks
- **Colours** (Lambda Generation): bg `#292929`, orange `#fb7e14`, cyan `#26C6DA`, lime `#D4E157`, blue `#40c4ff`, extra grey `#3d3d3d`, error `#ff5555`, elevated `#ffff66`.
- **Block separators (Wholespace style)**: every segment is `style: diamond` with `leading_diamond` `\ue0b2` and `trailing_diamond` `<transparent,BG>\ue0b2</>` (BG = that segment's background); the last segment in a block ends with `\ue0b0`.
- **Input line**: a separate block with `newline: true` containing a `status` segment, template `❯`, orange normally and red via `foreground_templates` when `.Code > 0`.
- **Git (identical in all themes)**: dark `#292929` background; the text colour carries the state via `foreground_templates`: clean → lime `#D4E157`, dirty → pink `#ff79c6`, ahead or behind → cyan `#26C6DA`, ahead+behind → `#f26d50`.
- **Elevated**: `root` segment, shown only when running as admin/root, template `\uf0e7` (bolt) on yellow.
- **CPU / memory**: `sysinfo` segment, `.PhysicalPercentUsed`, and used/total GB computed from `.PhysicalTotalMemory` and `.PhysicalAvailableMemory` (bytes / 1073741824).
- **Duration**: `executiontime` with `always_enabled: true`, `threshold: 0`.
- **Transient prompt**: `transient_prompt.template` can reuse the previous prompt's segments via `.Segments.<Type>.<Property>` (e.g. `.Segments.Git.HEAD`, `.Segments.Executiontime.FormattedMs`); time uses `{{ now | date "15:04:05" }}` so it freezes at the moment you hit Enter. This only works inside a live shell session (not with a one-off `oh-my-posh print transient`, where those values show empty).
- A Nerd Font is required for the glyphs.

## Resources
- Configuration overview: https://ohmyposh.dev/docs/configuration/general
- Blocks (`alignment`, `newline`, `type`): https://ohmyposh.dev/docs/configuration/block
- Segments (`style`, `powerline_symbol`, `invert_powerline`, diamonds, `*_templates`): https://ohmyposh.dev/docs/configuration/segment
- Colours (hex, palettes, `transparent`, colour templates, `<fg,bg>` inline): https://ohmyposh.dev/docs/configuration/colors
- Templates (Go templates, sprig, global props like `.Code`, `.Shell`): https://ohmyposh.dev/docs/configuration/templates
- Transient prompt: https://ohmyposh.dev/docs/configuration/transient
- Segment reference: https://ohmyposh.dev/docs/segments/system/os , `/system/root`, `/system/sysinfo`, `/system/executiontime`, `/system/time`, `/system/path`, `/system/status`, `/system/battery`, `/system/session`, `/scm/git`, `/languages/node`, `/languages/python`, `/languages/golang`
- Schema: https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json
- Stock themes for inspiration: https://ohmyposh.dev/docs/themes
- Nerd Font glyph search: https://www.nerdfonts.com/cheat-sheet
- Source inspirations (installed locally): `wholespace`, `lambdageneration`, `powerlevel10k_rainbow`

## Preview tips
```powershell
$env:POSH_SESSION_ID = [guid]::NewGuid()
oh-my-posh print primary   --config .\schalkje\schalkje.omp.json --shell pwsh --escape=false --execution-time 1234
oh-my-posh print transient --config .\schalkje\schalkje.omp.json --shell pwsh --escape=false
```
