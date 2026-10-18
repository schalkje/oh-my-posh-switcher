# schalkje-lean

Minimal variant: where am I and what is the repo state on the left, how long and when on the right. No CPU/mem on the prompt.

File: `schalkje-lean.omp.json` · `version: 4`, `final_space: true`. Palette, building blocks and resources: see [`..\README.md`](..\README.md).

## Layout
```
 os  ⚡ path  ‹branch›                                   duration  ♥ time
❯
```

### Block 1 – prompt, left
Separator style (Wholespace): every segment is `style: diamond`, `leading_diamond` `\ue0b2`, `trailing_diamond` `<transparent,BG>\ue0b2</>`; last segment of a block ends with `\ue0b0`.

| # | Segment | fg / bg | Notes |
|---|---|---|---|
| 1 | `os` | orange / `#292929` | |
| 2 | `root` | bg / `#ffff66` | elevated only |
| 3 | `path` | bg / orange | `agnoster_short`, `max_depth: 2` |
| 4 | `git` | lime / `#292929` | text colour via `foreground_templates`: clean lime, dirty `#ff79c6`, ahead/behind cyan, ahead+behind `#f26d50` |

### Block 2 – prompt, right (same separator style)
| # | Segment | fg / bg | Notes |
|---|---|---|---|
| 1 | `executiontime` | orange / `#3d3d3d` | `always_enabled`, threshold 0, `austin` |
| 2 | `time` | bg / orange | `15:04:05` with heart |

### Block 3 – input line (`newline: true`)
`status` segment `❯`, **orange**, red on non-zero exit code.

## Transient prompt
Single line: `♥ <time> <duration> [ <branch>] ❯`, orange, transparent background.
