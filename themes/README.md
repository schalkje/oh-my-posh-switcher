# Custom themes

Each theme lives in its own subfolder: `themes\<name>\<name>.omp.json` (plus an optional README).

`OmpThemes.ps1` scans this folder recursively, so every theme here shows up in `omp-theme`, `omp-list` and `omp-set <name>` automatically, next to the ones in `OMP_THEMES_DIR`. If a name exists in both places, the one here wins. No copying needed.

## Add a theme
1. `mkdir themes\<name>` and create `<name>.omp.json` in it.
2. Preview: `omp-list <name> -Preview`
3. Apply: `omp-set <name>`

## Themes
| Theme | Description |
|---|---|
| [schalkje](schalkje) | Tokyo-night style powerline prompt |
