# Oh-My-Posh theme switcher. Dot-source from $PROFILE:  . <path>\OmpThemes.ps1
# Themes folder: $env:OMP_THEMES_DIR (fallback: ~\.config\ohmyposh)

function Get-OmpThemesDir {
    $dir = if ($env:OMP_THEMES_DIR) { $env:OMP_THEMES_DIR } else { Join-Path $HOME '.config\ohmyposh' }
    $dir = [Environment]::ExpandEnvironmentVariables($dir)
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $dir
}

function Get-OmpThemeFile {
    param([string]$Name)
    # Custom themes shipped with this repo (.\themes\**) take precedence over same-named downloaded ones
    $custom = Join-Path $PSScriptRoot 'themes'
    $files = @()
    if (Test-Path -LiteralPath $custom) { $files += Get-ChildItem -LiteralPath $custom -File -Recurse }
    $files += Get-ChildItem -LiteralPath (Get-OmpThemesDir) -File
    $files = $files | Where-Object { $_.Name -match '\.omp\.(json|ya?ml|toml)$' } |
        Group-Object Name | ForEach-Object { $_.Group[0] }
    if ($Name) {
        $n = $Name -replace '\.omp\.(json|ya?ml|toml)$', ''
        $files = $files | Where-Object { ($_.Name -replace '\.omp\.(json|ya?ml|toml)$', '') -like $n }
    }
    $files | Sort-Object Name
}

function Get-OmpTheme {
    [CmdletBinding()]
    param([Parameter(Position = 0)][string]$Name, [switch]$Preview)
    $current = $env:POSH_CONFIG
    $files = @(Get-OmpThemeFile -Name $Name)
    if (-not $files) { Write-Warning "No themes found in $(Get-OmpThemesDir)"; return }
    foreach ($f in $files) {
        $short = $f.Name -replace '\.omp\.(json|ya?ml|toml)$', ''
        $isCur = $current -and ($f.FullName -ieq $current)
        if ($Preview) {
            Write-Host ("`n== {0}{1}" -f $short, $(if ($isCur) { '  (current)' } else { '' })) -ForegroundColor Cyan
            Show-OmpPreview $f.FullName
        } else {
            [pscustomobject]@{ Current = $(if ($isCur) { '*' } else { '' }); Name = $short; Path = $f.FullName }
        }
    }
}

function Show-OmpPreview {
    param([string]$Path)
    # The session id makes oh-my-posh reuse the cached active config, so clear it; decode output as UTF-8
    $oldSession = $env:POSH_SESSION_ID
    $oldEnc = [Console]::OutputEncoding
    try {
        $env:POSH_SESSION_ID = [guid]::NewGuid().ToString()
        [Console]::OutputEncoding = [Text.Encoding]::UTF8
        oh-my-posh print primary --config $Path --shell pwsh --escape=false 2>&1 | Write-Host
        Write-Host ''
    }
    catch { Write-Warning "Preview failed: $_" }
    finally {
        [Console]::OutputEncoding = $oldEnc
        $env:POSH_SESSION_ID = $oldSession
    }
}

function Set-OmpProfileTheme {
    param([string]$Path)
    $line = "oh-my-posh init pwsh --config `"$Path`" | Invoke-Expression"
    $prof = $PROFILE.CurrentUserCurrentHost
    if (-not (Test-Path $prof)) { New-Item -ItemType File -Path $prof -Force | Out-Null }
    Copy-Item $prof "$prof.bak" -Force
    $lines = @(Get-Content $prof)
    $idx = for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*oh-my-posh\s+init\s+pwsh') { $i } }
    if ($idx) {
        $lines[$idx[0]] = $line
        $lines = for ($i = 0; $i -lt $lines.Count; $i++) { if ($idx.Count -gt 1 -and $idx[1..($idx.Count - 1)] -contains $i) { "# $($lines[$i])" } else { $lines[$i] } }
    } else { $lines += $line }
    Set-Content $prof $lines
}

function Set-OmpTheme {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)][string]$Name, [switch]$NoPersist)
    $f = @(Get-OmpThemeFile -Name $Name)
    if ($f.Count -ne 1) {
        Write-Error $(if ($f.Count) { "Ambiguous name '$Name': $($f.Name -join ', ')" } else { "Theme '$Name' not found in $(Get-OmpThemesDir)" })
        return
    }
    oh-my-posh init pwsh --config $f[0].FullName | Invoke-Expression
    $env:POSH_CONFIG = $f[0].FullName
    if (-not $NoPersist) { Set-OmpProfileTheme $f[0].FullName; Write-Host "Theme '$Name' applied and saved to profile." -ForegroundColor Green }
}

Register-ArgumentCompleter -CommandName Set-OmpTheme, Get-OmpTheme -ParameterName Name -ScriptBlock {
    param($cmd, $param, $word)
    Get-OmpThemeFile | ForEach-Object { $_.Name -replace '\.omp\.(json|ya?ml|toml)$', '' } |
        Where-Object { $_ -like "$word*" } | ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}

function Select-OmpTheme {
    [CmdletBinding()]
    param()
    $files = @(Get-OmpThemeFile)
    if (-not $files) { Write-Warning 'No themes found.'; return }
    $i = [Math]::Max(0, [array]::IndexOf(@($files.FullName), $env:POSH_CONFIG))
    $top = [Console]::CursorTop
    while ($true) {
        Clear-Host
        Write-Host 'Up/Down: browse   Enter: apply   Esc/Q: cancel' -ForegroundColor Yellow
        $win = 10; $start = [Math]::Max(0, [Math]::Min($i - 5, $files.Count - $win))
        for ($k = $start; $k -lt [Math]::Min($files.Count, $start + $win); $k++) {
            $n = $files[$k].Name -replace '\.omp\.(json|ya?ml|toml)$', ''
            if ($k -eq $i) { Write-Host "> $n" -ForegroundColor Cyan } else { Write-Host "  $n" }
        }
        Write-Host ''
        Show-OmpPreview $files[$i].FullName
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow' { $i = ($i - 1 + $files.Count) % $files.Count }
            'DownArrow' { $i = ($i + 1) % $files.Count }
            'PageUp' { $i = [Math]::Max(0, $i - 10) }
            'PageDown' { $i = [Math]::Min($files.Count - 1, $i + 10) }
            'Enter' { Clear-Host; Set-OmpTheme ($files[$i].Name -replace '\.omp\.(json|ya?ml|toml)$', ''); return }
            { $_ -in 'Escape', 'Q' } { Clear-Host; return }
        }
    }
}

function Install-OmpTheme {
    [CmdletBinding()]
    param([Parameter(Position = 0)][string[]]$Name, [switch]$All, [switch]$List, [switch]$Force, [switch]$Apply)
    $headers = @{ 'User-Agent' = 'OmpThemes-ps1' }
    if ($env:GITHUB_TOKEN) { $headers.Authorization = "Bearer $env:GITHUB_TOKEN" }
    try {
        $items = Invoke-RestMethod -Headers $headers 'https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/contents/themes'
    } catch { Write-Error "Could not list GitHub themes: $_"; return }
    $remote = $items | Where-Object { $_.name -match '\.omp\.(json|ya?ml|toml)$' }
    if ($List -or (-not $Name -and -not $All)) {
        $local = Get-OmpThemeFile | ForEach-Object Name
        $remote | ForEach-Object { [pscustomobject]@{ Installed = $(if ($local -contains $_.name) { '*' } else { '' }); Name = $_.name -replace '\.omp\.(json|ya?ml|toml)$', '' } }
        return
    }
    $dir = Get-OmpThemesDir
    $sel = if ($All) { $remote } else {
        foreach ($n in $Name) {
            $m = @($remote | Where-Object { ($_.name -replace '\.omp\.(json|ya?ml|toml)$', '') -like $n })
            if (-not $m) { Write-Warning "No GitHub theme matches '$n'" }
            $m
        }
    }
    foreach ($t in $sel) {
        $dest = Join-Path $dir $t.name
        if ((Test-Path $dest) -and -not $Force) { Write-Host "Skip (exists): $($t.name)"; continue }
        try { Invoke-WebRequest -Headers $headers $t.download_url -OutFile $dest; Write-Host "Installed: $($t.name)" -ForegroundColor Green }
        catch { Write-Warning "Failed $($t.name): $_" }
    }
    if ($Apply -and $sel.Count -eq 1) { Set-OmpTheme ($sel[0].name -replace '\.omp\.(json|ya?ml|toml)$', '') }
}

Set-Alias omp-theme Select-OmpTheme
Set-Alias omp-list Get-OmpTheme
Set-Alias omp-set Set-OmpTheme
Set-Alias omp-install Install-OmpTheme

function Show-OmpHelp {
    Write-Host @"

  OH-MY-POSH THEME SWITCHER - HOW IT WORKS
  ----------------------------------------
  Themes folder : $(Get-OmpThemesDir)
                  (change with `$env:OMP_THEMES_DIR; default ~\.config\ohmyposh)
  Current theme : $(if ($env:POSH_CONFIG) { Split-Path $env:POSH_CONFIG -Leaf } else { '(unknown)' })

  Menu:   run  .\OmpThemes.ps1   (or  omp-menu  once loaded from your profile)
  Direct commands (after dot-sourcing in `$PROFILE):
    omp-theme             interactive picker with live preview
    omp-list [-Preview]   list themes (with rendered previews)
    omp-set <name>        switch theme (Tab completes); saved to profile
    omp-install [names]   list/download themes from GitHub
                          (-All, -Force, -Apply)

  Notes: previews need a Nerd Font. Switching in the menu only affects the
  profile for new shells; use  omp-set  / dot-source to change the live shell.

"@ -ForegroundColor Gray
}

function Show-OmpMenu {
    [CmdletBinding()] param()
    while ($true) {
        Clear-Host
        $cur = if ($env:POSH_CONFIG) { (Split-Path $env:POSH_CONFIG -Leaf) -replace '\.omp\.(json|ya?ml|toml)$', '' } else { '-' }
        $count = @(Get-OmpThemeFile).Count
        Write-Host ''
        Write-Host '  +----------------------------------------+' -ForegroundColor Cyan
        Write-Host '  |      OH-MY-POSH  THEME  SWITCHER       |' -ForegroundColor Cyan
        Write-Host '  +----------------------------------------+' -ForegroundColor Cyan
        Write-Host "  Folder  : $(Get-OmpThemesDir)"
        Write-Host "  Current : $cur     Installed: $count themes`n"
        Write-Host '  [1] Browse & switch theme (live preview)'
        Write-Host '  [2] List installed themes'
        Write-Host '  [3] Preview all installed themes'
        Write-Host '  [4] Download themes from GitHub'
        Write-Host '  [5] Help / how it works'
        Write-Host '  [Q] Quit' -ForegroundColor DarkGray
        $c = (Read-Host "`n  Choose").Trim().ToUpper()
        switch ($c) {
            '1' { Select-OmpTheme }
            '2' { Get-OmpTheme | Format-Table -AutoSize | Out-Host; Read-Host '  Enter to continue' | Out-Null }
            '3' { Get-OmpTheme -Preview; Read-Host '  Enter to continue' | Out-Null }
            '4' {
                $list = @(Install-OmpTheme -List)
                if (-not $list) { Read-Host '  Enter to continue' | Out-Null; continue }
                $filter = Read-Host "  Filter (blank = all $($list.Count) themes)"
                $shown = @($list | Where-Object { $_.Name -like "*$filter*" })
                for ($k = 0; $k -lt $shown.Count; $k++) {
                    Write-Host ("  {0,3}) {1}{2}" -f ($k + 1), $shown[$k].Name, $(if ($shown[$k].Installed) { '  [installed]' } else { '' }))
                }
                $pick = Read-Host '  Numbers to download (e.g. 1,4,7 or "all"; blank = cancel)'
                if ($pick) {
                    $names = if ($pick -eq 'all') { $shown.Name } else { $pick -split '[,\s]+' | Where-Object { $_ -match '^\d+$' -and [int]$_ -ge 1 -and [int]$_ -le $shown.Count } | ForEach-Object { $shown[[int]$_ - 1].Name } }
                    if ($names) { Install-OmpTheme $names }
                }
                Read-Host '  Enter to continue' | Out-Null
            }
            '5' { Show-OmpHelp; Read-Host '  Enter to continue' | Out-Null }
            { $_ -in 'Q', '' } { return }
        }
    }
}

Set-Alias omp-menu Show-OmpMenu
Set-Alias omp-help Show-OmpHelp

# Run the menu when executed directly (.\OmpThemes.ps1) but not when dot-sourced
if ($MyInvocation.InvocationName -ne '.') { Show-OmpMenu }
