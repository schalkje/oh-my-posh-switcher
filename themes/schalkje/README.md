# schalkje

Default variant. Two lines, everything useful on the first line, the cursor on `❯` on its own line.

File: `schalkje.omp.json` · oh-my-posh config `version: 4`, `final_space: true`, `console_title_template: {{ .Folder }}`.
General building blocks, palette and resources: see [`..\README.md`](..\README.md).

## Palette
bg `#292929` · orange `#fb7e14` · cyan `#26C6DA` · lime `#D4E157` · blue `#40c4ff` · grey `#3d3d3d` · error `#ff5555` · elevated `#ffff66`
Dark text (`#292929`) on coloured blocks, orange text on dark blocks.

## Layout
```
 os  ⚡ path  ♥ time  cpu% · mem GB  duration            ‹node› ‹branch›
❯ style (Wholespace): every segment is `style: diamond` with `leading_diamond` `\ue0b2` and `trailing_diamond` `<transparent,BG>\ue0b2</>` (BG = the segment's own background), so blocks are visibly separated. The last segment of a block ends with `\ue0b0`.

### Block 1 – prompt, left
| # | Segment | fg / bg | Notes |
|---|---|---|---|
| 1 | `os` | orange / bg | `WSL at` prefix inside WSL |
| 2 | `root` | bg / `#ffff66` | only visible when elevated, bolt `\uf0e7` |
| 3 | `path` | bg / lime | `agnoster_short`, `max_depth: 2`, home `~`, folder icon `…` |
| 4 | `time` | bg / orange | `15:04:05`, heart `\u2665` |
| 5 | `sysinfo` | bg / cyan | `CPU %` · `used/total GB` |
| 6 | `executiontime` | orange / grey | `always_enabled`, threshold 0, style `austin`; last, trailing `\ue0b0` |

### Block 2 – prompt, right
| # | Segment | fg / bg | Notes |
|---|---|---|---|
| 1 | `node` | bg / blue | only inside node projects |
| 2 | `git` | lime / `#292929` | text colour via `foreground_templates`: clean lime, dirty `#ff79c6`, ahead/behind cyan, ahead+behind `#f26d50`; shows upstream icon, branch, status, stash; last, trailing `\ue0b0` |

### Block 3 – input line (`newline: true`)
`status` segment, template `❯`, **orange**, red when `.Code > 0`, `always_enabled`.

## Transient prompt
Colour orange, transparent background. After pressing Enter the whole prompt collapses to:
```
♥ <time> <duration> [<cpu% mem/totalGB>] [ <branch>]
❯
```
Path is dropped; time (`now | date`), duration (`.Segments.Executiontime.FormattedMs`), CPU/mem (`.Segments.Sysinfo.*`) and branch (`.Segments.Git.HEAD`) stay. Parts are guarded with `{{ if }}` so they vanish if unavailable.
