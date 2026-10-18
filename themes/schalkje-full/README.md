# schalkje-full

Everything on: system metrics, toolchain versions, battery and session info, with path and git on their own line. Three lines.

File: `schalkje-full.omp.json` · `version: 4`, `final_space: true`. Palette, building blocks and resources: see [`..\README.md`](..\README.md).

## Layout
```
 os  ⚡ ♥ time  cpu% · mem GB  duration            user@host ‹battery› ‹python› ‹go› ‹node›
 path  ‹branch›
❯
```

### Block 1 – line 1 left
Separator style (Wholespace): every segment is `style: diamond`, `leading_diamond` `\ue0b2`, `trailing_diamond` `<transparent,BG>\ue0b2</>`; last segment of a block ends with `\ue0b0`.

| # | Segment | fg / bg | Notes |
|---|---|---|---|
| 1 | `os` | orange / `#292929` | |
| 2 | `root` | bg / `#ffff66` | elevated only |
| 3 | `time` | bg / orange | `15:04:05` |
| 4 | `sysinfo` | bg / cyan | CPU % · used/total GB |
| 5 | `executiontime` | orange / `#3d3d3d` | `always_enabled`, threshold 0 |

### Block 2 – line 1 right (same separator style)
| # | Segment | fg / bg | Notes |
|---|---|---|---|
| 1 | `session` | orange / `#292929` | `user@host`, ssh icon when remote |
| 2 | `battery` | bg / blue | hidden on machines without battery |
| 3 | `python` | bg / `#FFDE57` | `display_mode: files` |
| 4 | `go` | bg / `#00acd7` | |
| 5 | `node` | bg / lime | |

### Block 3 – line 2 (`newline: true`), Lambda Generation text style
| # | Segment | fg / bg | Notes |
|---|---|---|---|
| 1 | `path` | orange / `#292929` | `agnoster_short`, `max_depth: 4` |
| 2 | `git` | lime / `#292929` | text colour via `foreground_templates`: clean lime, dirty `#ff79c6`, ahead/behind cyan, ahead+behind `#f26d50` |

### Block 4 – input line (`newline: true`)
`status` segment `❯`, **orange**, red on non-zero exit code.

## Transient prompt
Two lines, orange, transparent background:
```
♥ <time> <duration> [<cpu% mem/totalGB>] [ <branch>]
❯
```
